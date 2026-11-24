import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../models/chat_models.dart';

enum GeminiErrorType {
  rateLimited,
  serviceUnavailable,
  networkUnavailable,
  timeout,
  authError,
  invalidRequest,
  cancelled,
  unknown;

  String toUserMessage() {
    switch (this) {
      case GeminiErrorType.rateLimited:
        return 'Rate limit exceeded (HTTP 429). Please wait a moment.';
      case GeminiErrorType.serviceUnavailable:
        return 'Gemini service is temporarily unavailable (HTTP 503).';
      case GeminiErrorType.networkUnavailable:
        return 'No network connection. Please check your internet.';
      case GeminiErrorType.timeout:
        return 'Request timed out waiting for server response.';
      case GeminiErrorType.authError:
        return 'API key or authentication error. Please verify your credentials.';
      case GeminiErrorType.invalidRequest:
        return 'Invalid request payload or model configuration.';
      case GeminiErrorType.cancelled:
        return 'Stream stopped.';
      case GeminiErrorType.unknown:
        return 'An unexpected error occurred while communicating with Gemini.';
    }
  }
}

class GeminiException implements Exception {
  final GeminiErrorType type;
  final String message;
  final int? statusCode;

  const GeminiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Token used to abort an active streaming request cleanly.
class StreamCancellationToken {
  bool _isCancelled = false;
  void Function()? _onCancel;

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _onCancel?.call();
  }

  void attach(void Function() onCancel) {
    if (_isCancelled) {
      onCancel();
    } else {
      _onCancel = onCancel;
    }
  }
}

abstract class ChatCompletionService {
  Stream<String> streamChatCompletion({
    required List<ChatMessage> conversationHistory,
    String? model,
    String? systemInstruction,
    StreamCancellationToken? cancellationToken,
  });
}

class GeminiService implements ChatCompletionService {
  final http.Client? _customClient;

  const GeminiService([this._customClient]);

  /// Extracts text tokens from raw SSE line.
  /// Format: 'data: {"candidates":[{"content":{"parts":[{"text":"chunk"}]}}]}'
  static String? parseSseLine(String rawLine) {
    final trimmed = rawLine.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('data:')) {
      return null;
    }

    final jsonStr = trimmed.substring(5).trim();
    if (jsonStr.isEmpty || jsonStr == '[DONE]') {
      return null;
    }

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('error')) {
          final err = decoded['error'];
          final errMsg = err is Map ? err['message'] ?? 'Gemini API Error' : err.toString();
          throw GeminiException(
            type: GeminiErrorType.invalidRequest,
            message: errMsg.toString(),
          );
        }

        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final firstCandidate = candidates.first as Map<String, dynamic>?;
          final content = firstCandidate?['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final buffer = StringBuffer();
            for (final part in parts) {
              if (part is Map<String, dynamic> && part.containsKey('text')) {
                buffer.write(part['text']);
              }
            }
            final text = buffer.toString();
            return text.isNotEmpty ? text : null;
          }
        }
      }
    } on GeminiException {
      rethrow;
    } catch (_) {
      // Ignore unparseable partial chunk lines safely
    }
    return null;
  }

  /// Trims outbound context to the most recent [maxMessages] completed turns.
  static List<ChatMessage> trimContextWindow(
    List<ChatMessage> messages, {
    int maxMessages = AppConfig.maxContextMessages,
  }) {
    final valid = messages
        .where((m) => m.content.trim().isNotEmpty && !m.isError)
        .toList();
    if (valid.length <= maxMessages) {
      return valid;
    }
    return valid.sublist(valid.length - maxMessages);
  }

  /// Builds the Gemini API contents payload mapping 'assistant' to 'model'.
  static Map<String, dynamic> buildPayload({
    required List<ChatMessage> conversationHistory,
    String? systemInstruction,
  }) {
    final contents = conversationHistory.map((m) {
      return {
        'role': m.isUser ? 'user' : 'model',
        'parts': [
          {'text': m.content}
        ],
      };
    }).toList();

    final payload = <String, dynamic>{
      'contents': contents,
    };

    final instruction = systemInstruction ?? AppConfig.systemInstruction;
    if (instruction.isNotEmpty) {
      payload['systemInstruction'] = {
        'parts': [
          {'text': instruction}
        ],
      };
    }

    return payload;
  }

  @override
  Stream<String> streamChatCompletion({
    required List<ChatMessage> conversationHistory,
    String? model,
    String? systemInstruction,
    StreamCancellationToken? cancellationToken,
  }) async* {
    if (cancellationToken?.isCancelled == true) {
      return;
    }

    final trimmedHistory = trimContextWindow(conversationHistory);
    if (trimmedHistory.isEmpty) {
      return;
    }

    final endpointUri = AppConfig.getStreamGenerateContentUri(model: model);
    final requestBody = jsonEncode(
      buildPayload(
        conversationHistory: trimmedHistory,
        systemInstruction: systemInstruction,
      ),
    );

    // Bounded exponential backoff retry for transient 429 / 503 before streaming tokens start
    int attempt = 0;
    const maxAttempts = 3;

    while (true) {
      attempt++;
      if (cancellationToken?.isCancelled == true) {
        return;
      }

      final client = _customClient ?? http.Client();
      bool tokensStarted = false;
      http.StreamedResponse? streamedResponse;

      try {
        final request = http.Request('POST', endpointUri)
          ..headers['Content-Type'] = 'application/json; charset=utf-8'
          ..headers['Accept'] = 'text/event-stream';

        // Also supply API key header if configured
        if (AppConfig.geminiApiKey.isNotEmpty) {
          request.headers['x-goog-api-key'] = AppConfig.geminiApiKey;
        }

        request.body = requestBody;

        cancellationToken?.attach(() {
          try {
            client.close();
          } catch (_) {}
        });

        final sendFuture = client.send(request);
        streamedResponse = await sendFuture.timeout(AppConfig.connectTimeout);

        final statusCode = streamedResponse.statusCode;

        if (statusCode == 200) {
          final linesStream = streamedResponse.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter());

          await for (final line in linesStream.timeout(AppConfig.streamTimeout)) {
            if (cancellationToken?.isCancelled == true) {
              return;
            }

            final token = parseSseLine(line);
            if (token != null && token.isNotEmpty) {
              tokensStarted = true;
              yield token;
            }
          }
          return;
        }

        // Handle error responses
        final errorBody = await streamedResponse.stream.bytesToString();
        String parsedMsg = '';
        try {
          final errJson = jsonDecode(errorBody);
          if (errJson is Map && errJson.containsKey('error')) {
            parsedMsg = errJson['error']['message'] ?? '';
          }
        } catch (_) {}

        if ((statusCode == 429 || statusCode == 503) &&
            !tokensStarted &&
            attempt < maxAttempts) {
          final delay = Duration(milliseconds: 1000 * (1 << (attempt - 1)));
          await Future.delayed(delay);
          continue;
        }

        if (statusCode == 429) {
          throw GeminiException(
            type: GeminiErrorType.rateLimited,
            message: parsedMsg.isNotEmpty
                ? parsedMsg
                : GeminiErrorType.rateLimited.toUserMessage(),
            statusCode: statusCode,
          );
        } else if (statusCode == 503) {
          throw GeminiException(
            type: GeminiErrorType.serviceUnavailable,
            message: parsedMsg.isNotEmpty
                ? parsedMsg
                : GeminiErrorType.serviceUnavailable.toUserMessage(),
            statusCode: statusCode,
          );
        } else if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
          throw GeminiException(
            type: GeminiErrorType.authError,
            message: parsedMsg.isNotEmpty
                ? parsedMsg
                : GeminiErrorType.authError.toUserMessage(),
            statusCode: statusCode,
          );
        } else {
          throw GeminiException(
            type: GeminiErrorType.unknown,
            message: parsedMsg.isNotEmpty
                ? parsedMsg
                : 'Server returned HTTP $statusCode: $errorBody',
            statusCode: statusCode,
          );
        }
      } on SocketException {
        if (cancellationToken?.isCancelled == true) return;
        throw GeminiException(
          type: GeminiErrorType.networkUnavailable,
          message: GeminiErrorType.networkUnavailable.toUserMessage(),
        );
      } on TimeoutException {
        if (cancellationToken?.isCancelled == true) return;
        throw GeminiException(
          type: GeminiErrorType.timeout,
          message: GeminiErrorType.timeout.toUserMessage(),
        );
      } on http.ClientException {
        if (cancellationToken?.isCancelled == true) return;
        throw GeminiException(
          type: GeminiErrorType.networkUnavailable,
          message: GeminiErrorType.networkUnavailable.toUserMessage(),
        );
      } catch (e) {
        if (cancellationToken?.isCancelled == true) return;
        if (e is GeminiException) rethrow;
        throw GeminiException(
          type: GeminiErrorType.unknown,
          message: e.toString(),
        );
      } finally {
        if (_customClient == null) {
          client.close();
        }
      }
    }
  }
}
