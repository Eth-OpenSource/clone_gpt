import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clone_gpt/data/local/chat_database.dart';
import 'package:clone_gpt/data/models/chat_models.dart';
import 'package:clone_gpt/data/remote/gemini_service.dart';
import 'package:clone_gpt/features/chat/chat_controller.dart';

class MockCompletionService implements ChatCompletionService {
  final Stream<String> Function({
    required List<ChatMessage> conversationHistory,
    String? model,
    String? systemInstruction,
    StreamCancellationToken? cancellationToken,
  }) onStream;

  MockCompletionService(this.onStream);

  @override
  Stream<String> streamChatCompletion({
    required List<ChatMessage> conversationHistory,
    String? model,
    String? systemInstruction,
    StreamCancellationToken? cancellationToken,
  }) {
    return onStream(
      conversationHistory: conversationHistory,
      model: model,
      systemInstruction: systemInstruction,
      cancellationToken: cancellationToken,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late ChatDatabase database;

  setUp(() async {
    database = await ChatDatabase.inMemory();
  });

  tearDown(() async {
    await database.close();
  });

  group('ChatController Lifecycle & Streaming', () {
    test('initializes with empty thread list', () async {
      final controller = ChatController(
        database: database,
        completionService: MockCompletionService((
            {required conversationHistory, model, systemInstruction, cancellationToken}) {
          return const Stream.empty();
        }),
      );

      await controller.initialize();
      expect(controller.threads, isEmpty);
      expect(controller.currentThread, isNull);
      expect(controller.messages, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('streams tokens and completes successfully', () async {
      final mockService = MockCompletionService((
          {required conversationHistory, model, systemInstruction, cancellationToken}) async* {
        yield 'Hello ';
        yield 'world!';
      });

      final controller = ChatController(
        database: database,
        completionService: mockService,
      );
      await controller.initialize();

      await controller.sendMessage('Test prompt');

      expect(controller.isStreaming, isFalse);
      expect(controller.messages.length, equals(2));
      expect(controller.messages[0].isUser, isTrue);
      expect(controller.messages[0].content, equals('Test prompt'));
      expect(controller.messages[1].isAssistant, isTrue);
      expect(controller.messages[1].content, equals('Hello world!'));
      expect(controller.messages[1].status, equals(MessageStatus.complete));
      expect(controller.threads.length, equals(1));
    });

    test('stopping stream cleanly preserves partial response', () async {
      final completer = Completer<void>();

      final mockService = MockCompletionService((
          {required conversationHistory, model, systemInstruction, cancellationToken}) async* {
        yield 'First ';
        yield 'chunk ';
        cancellationToken?.attach(() {
          completer.complete();
        });
        // Wait for cancellation
        await completer.future;
      });

      final controller = ChatController(
        database: database,
        completionService: mockService,
      );
      await controller.initialize();

      // Start sending without awaiting completion so we can stop it mid-flight
      final sendFuture = controller.sendMessage('Long stream prompt');

      // Wait briefly for first chunks to be processed
      await Future.delayed(const Duration(milliseconds: 30));
      expect(controller.isStreaming, isTrue);

      controller.stopStreaming();
      await sendFuture;

      expect(controller.isStreaming, isFalse);
      expect(controller.messages.length, equals(2));
      final assistantMsg = controller.messages[1];
      expect(assistantMsg.content, contains('First chunk'));
      expect(assistantMsg.status, equals(MessageStatus.aborted));
    });

    test('captures error message and allows clean retry', () async {
      int attempts = 0;

      final mockService = MockCompletionService((
          {required conversationHistory, model, systemInstruction, cancellationToken}) async* {
        attempts++;
        if (attempts == 1) {
          throw const GeminiException(
            type: GeminiErrorType.rateLimited,
            message: 'Rate limit exceeded (HTTP 429)',
            statusCode: 429,
          );
        } else {
          yield 'Recovered successfully!';
        }
      });

      final controller = ChatController(
        database: database,
        completionService: mockService,
      );
      await controller.initialize();

      await controller.sendMessage('Will fail initially');

      expect(controller.errorMessage, contains('Rate limit'));
      expect(controller.lastFailedPrompt, equals('Will fail initially'));

      // Retry turn
      await controller.retryLastTurn();

      expect(controller.errorMessage, isNull);
      expect(controller.messages.length, equals(2));
      expect(controller.messages.last.content, equals('Recovered successfully!'));
    });
  });
}
