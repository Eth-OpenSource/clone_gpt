import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/chat_database.dart';
import '../../data/models/chat_models.dart';
import '../../data/remote/gemini_service.dart';

class ChatController extends ChangeNotifier {
  final ChatDatabase _database;
  final ChatCompletionService _completionService;
  final Uuid _uuid = const Uuid();

  ChatController({
    ChatDatabase? database,
    ChatCompletionService? completionService,
  })  : _database = database ?? ChatDatabase.instance,
        _completionService = completionService ?? const GeminiService();

  List<ChatThread> _threads = [];
  List<ChatThread> get threads => List.unmodifiable(_threads);

  ChatThread? _currentThread;
  ChatThread? get currentThread => _currentThread;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _lastFailedPrompt;
  String? get lastFailedPrompt => _lastFailedPrompt;

  /// Dedicated notifier for active stream chunks to isolate high-frequency rebuilds.
  final ValueNotifier<String> activeStreamNotifier = ValueNotifier<String>('');

  StreamCancellationToken? _cancellationToken;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _threads = await _database.getThreads();
      if (_threads.isNotEmpty) {
        await selectThread(_threads.first.id);
      } else {
        _currentThread = null;
        _messages = [];
      }
    } catch (e) {
      _errorMessage = 'Failed to load chat history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNewChat() async {
    if (_isStreaming) {
      stopStreaming();
    }
    _currentThread = null;
    _messages = [];
    _errorMessage = null;
    _lastFailedPrompt = null;
    activeStreamNotifier.value = '';
    notifyListeners();
  }

  Future<void> selectThread(String threadId) async {
    if (_isStreaming) {
      stopStreaming();
    }

    _errorMessage = null;
    _lastFailedPrompt = null;
    activeStreamNotifier.value = '';

    final thread = _threads.firstWhere(
      (t) => t.id == threadId,
      orElse: () => ChatThread(
        id: threadId,
        title: 'Chat',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    _currentThread = thread;

    try {
      _messages = await _database.getMessagesForThread(threadId);
    } catch (e) {
      _errorMessage = 'Failed to load messages for this thread.';
    }

    notifyListeners();
  }

  Future<void> deleteThread(String threadId) async {
    final isDeletingCurrent = _currentThread?.id == threadId;
    if (isDeletingCurrent && _isStreaming) {
      stopStreaming();
    }

    await _database.deleteThread(threadId);
    _threads = await _database.getThreads();

    if (isDeletingCurrent) {
      if (_threads.isNotEmpty) {
        await selectThread(_threads.first.id);
      } else {
        await createNewChat();
      }
    } else {
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isStreaming) return;

    _errorMessage = null;
    _lastFailedPrompt = trimmedText;

    // Auto-create thread if starting from blank screen
    if (_currentThread == null) {
      final now = DateTime.now();
      final title = ChatDatabase.generateThreadTitle(trimmedText);
      final newThread = ChatThread(
        id: _uuid.v4(),
        title: title,
        createdAt: now,
        updatedAt: now,
      );
      await _database.saveThread(newThread);
      _currentThread = newThread;
      _threads = [newThread, ..._threads];
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      threadId: _currentThread!.id,
      role: MessageRole.user,
      content: trimmedText,
      status: MessageStatus.complete,
      createdAt: DateTime.now(),
    );

    // Save user message to database
    await _database.saveMessage(userMessage);

    final assistantMessageId = _uuid.v4();
    final assistantPlaceholder = ChatMessage(
      id: assistantMessageId,
      threadId: _currentThread!.id,
      role: MessageRole.assistant,
      content: '',
      status: MessageStatus.streaming,
      createdAt: DateTime.now(),
    );

    activeStreamNotifier.value = '';

    _messages = [..._messages, userMessage, assistantPlaceholder];
    _isStreaming = true;
    notifyListeners();

    _cancellationToken = StreamCancellationToken();
    final buffer = StringBuffer();

    try {
      final tokenStream = _completionService.streamChatCompletion(
        conversationHistory: _messages.sublist(0, _messages.length - 1),
        cancellationToken: _cancellationToken,
      );

      await for (final token in tokenStream) {
        buffer.write(token);
        activeStreamNotifier.value = buffer.toString();
      }

      final finalContent = buffer.toString();

      if (_cancellationToken?.isCancelled == true) {
        final abortedMessage = assistantPlaceholder.copyWith(
          content: finalContent,
          status: MessageStatus.aborted,
        );
        if (finalContent.isNotEmpty) {
          await _database.saveMessage(abortedMessage);
          _messages = [
            ..._messages.sublist(0, _messages.length - 1),
            abortedMessage,
          ];
        } else {
          _messages = _messages.sublist(0, _messages.length - 1);
        }
      } else {
        final completedMessage = assistantPlaceholder.copyWith(
          content: finalContent,
          status: MessageStatus.complete,
        );

        await _database.saveMessage(completedMessage);

        _messages = [
          ..._messages.sublist(0, _messages.length - 1),
          completedMessage,
        ];
        _errorMessage = null;
        _lastFailedPrompt = null;
      }
    } catch (e) {
      final partialContent = buffer.toString();
      if (_cancellationToken?.isCancelled == true) {
        // User voluntarily tapped Stop
        final abortedMessage = assistantPlaceholder.copyWith(
          content: partialContent,
          status: MessageStatus.aborted,
        );
        if (partialContent.isNotEmpty) {
          await _database.saveMessage(abortedMessage);
          _messages = [
            ..._messages.sublist(0, _messages.length - 1),
            abortedMessage,
          ];
        } else {
          // Empty aborted message - remove placeholder
          _messages = _messages.sublist(0, _messages.length - 1);
        }
      } else {
        // An unexpected or network/quota error occurred
        if (e is GeminiException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'An error occurred while connecting to Gemini.';
        }

        if (partialContent.isNotEmpty) {
          final partialMessage = assistantPlaceholder.copyWith(
            content: partialContent,
            status: MessageStatus.error,
          );
          await _database.saveMessage(partialMessage);
          _messages = [
            ..._messages.sublist(0, _messages.length - 1),
            partialMessage,
          ];
        } else {
          // Remove empty assistant placeholder so retry can cleanly generate
          _messages = _messages.sublist(0, _messages.length - 1);
        }
      }
    } finally {
      _isStreaming = false;
      _cancellationToken = null;
      _threads = await _database.getThreads();
      notifyListeners();
    }
  }

  void stopStreaming() {
    if (!_isStreaming || _cancellationToken == null) return;
    _cancellationToken?.cancel();
  }

  Future<void> retryLastTurn() async {
    final prompt = _lastFailedPrompt;
    if (prompt == null || prompt.isEmpty || _isStreaming) return;

    // If last message was the failed user turn, remove it from list and re-send
    if (_messages.isNotEmpty && _messages.last.isUser) {
      final lastMsg = _messages.last;
      await _database.deleteMessage(lastMsg.id);
      _messages = _messages.sublist(0, _messages.length - 1);
      notifyListeners();
    }

    _errorMessage = null;
    await sendMessage(prompt);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopStreaming();
    activeStreamNotifier.dispose();
    super.dispose();
  }
}
