import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/chat_models.dart';

class ChatDatabase {
  static const String dbName = 'clonegpt_v1.db';
  static const int dbVersion = 1;

  Database? _db;
  final Database? _injectedDb;

  ChatDatabase([this._injectedDb]) {
    if (_injectedDb != null) {
      _db = _injectedDb;
    }
  }

  static ChatDatabase? _instance;
  static ChatDatabase get instance => _instance ??= ChatDatabase();

  static void initializeFfiIfNeeded() {
    // Mobile platforms use native SQLite. Desktop/FFI configured conditionally if needed.
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<ChatDatabase> inMemory() async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
    return ChatDatabase(db);
  }

  Future<Database> _initDatabase() async {
    final defaultDatabasesPath = await getDatabasesPath();
    final dbPath = p.join(defaultDatabasesPath, dbName);

    return await openDatabase(
      dbPath,
      version: dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
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

    await db.execute(
      'CREATE INDEX idx_messages_thread_id ON messages (thread_id)',
    );
    await db.execute(
      'CREATE INDEX idx_threads_updated_at ON threads (updated_at DESC)',
    );
  }

  // --- Thread Operations ---

  Future<List<ChatThread>> getThreads() async {
    final db = await database;
    final maps = await db.query(
      'threads',
      orderBy: 'updated_at DESC',
    );
    return maps.map(ChatThread.fromMap).toList();
  }

  Future<ChatThread?> getThread(String id) async {
    final db = await database;
    final maps = await db.query(
      'threads',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ChatThread.fromMap(maps.first);
  }

  Future<void> saveThread(ChatThread thread) async {
    final db = await database;
    await db.insert(
      'threads',
      thread.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateThreadTitle(String threadId, String newTitle) async {
    final db = await database;
    await db.update(
      'threads',
      {
        'title': newTitle,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [threadId],
    );
  }

  Future<void> touchThread(String threadId) async {
    final db = await database;
    await db.update(
      'threads',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [threadId],
    );
  }

  Future<void> deleteThread(String threadId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'messages',
        where: 'thread_id = ?',
        whereArgs: [threadId],
      );
      await txn.delete(
        'threads',
        where: 'id = ?',
        whereArgs: [threadId],
      );
    });
  }

  // --- Message Operations ---

  Future<List<ChatMessage>> getMessagesForThread(String threadId) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'thread_id = ?',
      whereArgs: [threadId],
      orderBy: 'created_at ASC',
    );
    return maps.map(ChatMessage.fromMap).toList();
  }

  Future<void> saveMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await touchThread(message.threadId);
  }

  Future<void> updateMessageContent(
    String messageId,
    String content,
    MessageStatus status,
  ) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'content': content,
        'status': status.toValue(),
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  static String generateThreadTitle(String firstMessage) {
    final cleaned = firstMessage
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'New Chat';

    final firstLine = cleaned.split('\n').first.trim();
    if (firstLine.length <= 36) {
      return firstLine;
    }

    final truncated = firstLine.substring(0, 36);
    final lastSpace = truncated.lastIndexOf(' ');
    if (lastSpace > 16) {
      return '${truncated.substring(0, lastSpace)}...';
    }
    return '${truncated.trim()}...';
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
