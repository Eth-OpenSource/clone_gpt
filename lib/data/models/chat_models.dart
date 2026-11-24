enum MessageRole {
  user,
  assistant,
  system;

  String toValue() => name;

  static MessageRole fromValue(String value) {
    return MessageRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageRole.user,
    );
  }
}

enum MessageStatus {
  streaming,
  complete,
  error,
  aborted;

  String toValue() => name;

  static MessageStatus fromValue(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageStatus.complete,
    );
  }
}

class ChatThread {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatThread copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatThread(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ChatThread.fromMap(Map<String, dynamic> map) {
    return ChatThread(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}

class ChatMessage {
  final String id;
  final String threadId;
  final MessageRole role;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    this.status = MessageStatus.complete,
    required this.createdAt,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isStreaming => status == MessageStatus.streaming;
  bool get isError => status == MessageStatus.error;
  bool get isAborted => status == MessageStatus.aborted;

  ChatMessage copyWith({
    String? id,
    String? threadId,
    MessageRole? role,
    String? content,
    MessageStatus? status,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      role: role ?? this.role,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'thread_id': threadId,
      'role': role.toValue(),
      'content': content,
      'status': status.toValue(),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      threadId: map['thread_id'] as String,
      role: MessageRole.fromValue(map['role'] as String),
      content: map['content'] as String,
      status: MessageStatus.fromValue(map['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
