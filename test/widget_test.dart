import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clone_gpt/data/local/chat_database.dart';
import 'package:clone_gpt/data/models/chat_models.dart';
import 'package:clone_gpt/data/remote/gemini_service.dart';
import 'package:clone_gpt/features/chat/chat_controller.dart';
import 'package:clone_gpt/features/chat/widgets/chat_composer.dart';
import 'package:clone_gpt/main.dart';

class MockCompletionService implements ChatCompletionService {
  @override
  Stream<String> streamChatCompletion({
    required List<ChatMessage> conversationHistory,
    String? model,
    String? systemInstruction,
    StreamCancellationToken? cancellationToken,
  }) async* {
    yield 'Hello from Gemini!';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Renders empty state and sends message smoke test',
      (WidgetTester tester) async {
    final db = await ChatDatabase.inMemory();
    final controller = ChatController(
      database: db,
      completionService: MockCompletionService(),
    );
    await controller.initialize();

    await tester.pumpWidget(CloneGptApp(controller: controller));
    await tester.pumpAndSettle();

    // Verify empty state quiet prompt is visible
    expect(
      find.text('What would you like to build or solve today?'),
      findsOneWidget,
    );
    expect(find.text('cloneGPT'), findsOneWidget);

    // Enter text in composer
    final inputFinder = find.byType(ChatComposer);
    expect(inputFinder, findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Build a Flutter app');
    await tester.pump();

    // Tap Send button
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify user message and assistant reply are rendered
    expect(find.text('Build a Flutter app'), findsOneWidget);
    expect(find.text('Hello from Gemini!'), findsOneWidget);

    await db.close();
  });
}
