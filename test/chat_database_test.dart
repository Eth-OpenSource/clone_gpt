import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';
import 'package:clone_gpt/data/local/chat_database.dart';
import 'package:clone_gpt/data/models/chat_models.dart';

void main() {
  late ChatDatabase database;

  setUp(() async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: ChatDatabase.dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE threads (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE messages (
              id TEXT PRIMARY KEY,
              thread_id TEXT NOT NULL,
              role TEXT NOT NULL,
              content TEXT NOT NULL,
              status TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (thread_id) REFERENCES threads (id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );
    database = ChatDatabase(db);
  });

  tearDown(() async {
    await database.close();
  });

  group('ChatDatabase CRUD Operations', () {
    test('creates and retrieves thread by id and list ordered by updated_at', () async {
      final now = DateTime.now();
      final thread1 = ChatThread(
        id: 't-1',
        title: 'First Thread',
        createdAt: now.subtract(const Duration(minutes: 10)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
      );
      final thread2 = ChatThread(
        id: 't-2',
        title: 'Second Thread',
        createdAt: now,
        updatedAt: now,
      );

      await database.saveThread(thread1);
      await database.saveThread(thread2);

      final fetched = await database.getThread('t-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('First Thread'));

      final allThreads = await database.getThreads();
      expect(allThreads.length, equals(2));
      // Ordered by updated_at DESC: thread2 comes first
      expect(allThreads.first.id, equals('t-2'));
      expect(allThreads.last.id, equals('t-1'));
    });

    test('updates thread title and timestamp', () async {
      final thread = ChatThread(
        id: 't-1',
        title: 'Initial Title',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await database.saveThread(thread);

      await database.updateThreadTitle('t-1', 'Updated Title');
      final updated = await database.getThread('t-1');
      expect(updated!.title, equals('Updated Title'));
    });

    test('inserts, updates, and fetches messages for thread in chronological order', () async {
      final thread = ChatThread(
        id: 't-1',
        title: 'Thread 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await database.saveThread(thread);

      final msg1 = ChatMessage(
        id: 'm-1',
        threadId: 't-1',
        role: MessageRole.user,
        content: 'What is Dart?',
        createdAt: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      final msg2 = ChatMessage(
        id: 'm-2',
        threadId: 't-1',
        role: MessageRole.assistant,
        content: 'Dart is a client-optimized language.',
        status: MessageStatus.streaming,
        createdAt: DateTime.now(),
      );

      await database.saveMessage(msg1);
      await database.saveMessage(msg2);

      var messages = await database.getMessagesForThread('t-1');
      expect(messages.length, equals(2));
      expect(messages[0].id, equals('m-1'));
      expect(messages[1].id, equals('m-2'));
      expect(messages[1].isStreaming, isTrue);

      // Update streamed message
      await database.updateMessageContent(
        'm-2',
        'Dart is a client-optimized language developed by Google.',
        MessageStatus.complete,
      );

      messages = await database.getMessagesForThread('t-1');
      expect(messages[1].content, contains('by Google'));
      expect(messages[1].status, equals(MessageStatus.complete));
    });

    test('deleting a thread cascades and removes its messages', () async {
      final thread = ChatThread(
        id: 't-del',
        title: 'To Delete',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await database.saveThread(thread);

      final msg = ChatMessage(
        id: 'm-del',
        threadId: 't-del',
        role: MessageRole.user,
        content: 'Hello',
        createdAt: DateTime.now(),
      );
      await database.saveMessage(msg);

      expect((await database.getMessagesForThread('t-del')).length, equals(1));

      await database.deleteThread('t-del');

      expect(await database.getThread('t-del'), isNull);
      expect((await database.getMessagesForThread('t-del')).length, equals(0));
    });
  });

  group('ChatDatabase Title Generation', () {
    test('handles empty or blank prompt', () {
      expect(ChatDatabase.generateThreadTitle(''), equals('New Chat'));
      expect(ChatDatabase.generateThreadTitle('   '), equals('New Chat'));
    });

    test('cleans whitespace and returns short prompt as title', () {
      expect(
        ChatDatabase.generateThreadTitle('   Explain   quantum computing   '),
        equals('Explain quantum computing'),
      );
    });

    test('truncates cleanly at word boundary for long prompt', () {
      const longPrompt =
          'Can you please provide a comprehensive breakdown of distributed consensus algorithms like Raft and Paxos?';
      final title = ChatDatabase.generateThreadTitle(longPrompt);
      expect(title.endsWith('...'), isTrue);
      expect(title.length, lessThanOrEqualTo(40));
    });
  });
}
