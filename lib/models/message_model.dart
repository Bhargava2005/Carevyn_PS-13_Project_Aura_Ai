// lib/models/message_model.dart

enum MessageRole { user, assistant, system }

enum MessageStatus { sending, sent, error }

class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isVoice;

  Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isVoice = false,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isVoice,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isVoice: isVoice ?? this.isVoice,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'isVoice': isVoice,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        content: json['content'],
        role: MessageRole.values.firstWhere((e) => e.name == json['role']),
        timestamp: DateTime.parse(json['timestamp']),
        status: MessageStatus.values.firstWhere(
          (e) => e.name == (json['status'] ?? 'sent'),
        ),
        isVoice: json['isVoice'] ?? false,
      );

  /// Converts to Anthropic API format
  Map<String, dynamic> toApiFormat() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };
}