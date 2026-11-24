import 'package:test/test.dart';
import 'package:clone_gpt/data/models/chat_models.dart';
import 'package:clone_gpt/data/remote/gemini_service.dart';

void main() {
  group('GeminiService SSE Chunk Parsing', () {
    test('extracts text chunk from valid SSE line', () {
      const line =
          'data: {"candidates":[{"content":{"parts":[{"text":"Hello world"}],"role":"model"}}]}';
      final token = GeminiService.parseSseLine(line);
      expect(token, equals('Hello world'));
    });

    test('extracts concatenated text from multi-part chunk', () {
      const line =
          'data: {"candidates":[{"content":{"parts":[{"text":"Hello "},{"text":"enterprise"}],"role":"model"}}]}';
      final token = GeminiService.parseSseLine(line);
      expect(token, equals('Hello enterprise'));
    });

    test('returns null for non-data lines and empty lines', () {
      expect(GeminiService.parseSseLine(''), isNull);
      expect(GeminiService.parseSseLine(': ping'), isNull);
      expect(GeminiService.parseSseLine('event: message'), isNull);
    });

    test('returns null for [DONE] token', () {
      expect(GeminiService.parseSseLine('data: [DONE]'), isNull);
      expect(GeminiService.parseSseLine('data:    [DONE]   '), isNull);
    });

    test('throws GeminiException when data contains API error object', () {
      const line =
          'data: {"error":{"code":429,"message":"Resource has been exhausted","status":"RESOURCE_EXHAUSTED"}}';
      expect(
        () => GeminiService.parseSseLine(line),
        throwsA(isA<GeminiException>().having(
          (e) => e.message,
          'message',
          contains('exhausted'),
        )),
      );
    });

    test('gracefully ignores malformed JSON chunk', () {
      expect(GeminiService.parseSseLine('data: {malformed}'), isNull);
    });
  });

  group('GeminiService Context Window Trimming', () {
    test('preserves history when length <= maxMessages', () {
      final messages = List.generate(
        5,
        (i) => ChatMessage(
          id: '$i',
          threadId: 't1',
          role: i.isEven ? MessageRole.user : MessageRole.assistant,
          content: 'Message $i',
          createdAt: DateTime.now(),
        ),
      );

      final trimmed = GeminiService.trimContextWindow(messages, maxMessages: 20);
      expect(trimmed.length, equals(5));
      expect(trimmed.first.id, equals('0'));
      expect(trimmed.last.id, equals('4'));
    });

    test('trims older messages to keep the most recent maxMessages', () {
      final messages = List.generate(
        10,
        (i) => ChatMessage(
          id: '$i',
          threadId: 't1',
          role: i.isEven ? MessageRole.user : MessageRole.assistant,
          content: 'Message $i',
          createdAt: DateTime.now(),
        ),
      );

      final trimmed = GeminiService.trimContextWindow(messages, maxMessages: 4);
      expect(trimmed.length, equals(4));
      expect(trimmed[0].id, equals('6'));
      expect(trimmed[1].id, equals('7'));
      expect(trimmed[2].id, equals('8'));
      expect(trimmed[3].id, equals('9'));
    });

    test('ignores empty or error messages in context window', () {
      final messages = [
        ChatMessage(
          id: '1',
          threadId: 't1',
          role: MessageRole.user,
          content: 'Valid user query',
          createdAt: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          threadId: 't1',
          role: MessageRole.assistant,
          content: '   ',
          createdAt: DateTime.now(),
        ),
        ChatMessage(
          id: '3',
          threadId: 't1',
          role: MessageRole.assistant,
          content: 'Error occurred',
          status: MessageStatus.error,
          createdAt: DateTime.now(),
        ),
        ChatMessage(
          id: '4',
          threadId: 't1',
          role: MessageRole.assistant,
          content: 'Valid assistant reply',
          createdAt: DateTime.now(),
        ),
      ];

      final trimmed = GeminiService.trimContextWindow(messages);
      expect(trimmed.length, equals(2));
      expect(trimmed.map((m) => m.id), equals(['1', '4']));
    });
  });

  group('GeminiService Payload Construction', () {
    test('maps assistant role to model role for Gemini API', () {
      final history = [
        ChatMessage(
          id: '1',
          threadId: 't1',
          role: MessageRole.user,
          content: 'Hello',
          createdAt: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          threadId: 't1',
          role: MessageRole.assistant,
          content: 'Hi there',
          createdAt: DateTime.now(),
        ),
      ];

      final payload = GeminiService.buildPayload(
        conversationHistory: history,
        systemInstruction: 'Test system instruction',
      );

      final contents = payload['contents'] as List;
      expect(contents.length, equals(2));
      expect(contents[0]['role'], equals('user'));
      expect(contents[0]['parts'][0]['text'], equals('Hello'));
      expect(contents[1]['role'], equals('model'));
      expect(contents[1]['parts'][0]['text'], equals('Hi there'));

      final instruction = payload['systemInstruction'] as Map;
      expect(instruction['parts'][0]['text'], equals('Test system instruction'));
    });
  });
}
