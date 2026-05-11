enum AiChatRole { user, assistant }

class AiChatMessage {
  AiChatMessage({
    required this.role,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AiChatMessage.user(String content) {
    return AiChatMessage(role: AiChatRole.user, content: content);
  }

  factory AiChatMessage.assistant(String content) {
    return AiChatMessage(role: AiChatRole.assistant, content: content);
  }

  final AiChatRole role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role == AiChatRole.user;

  String get groqRole => switch (role) {
    AiChatRole.user => 'user',
    AiChatRole.assistant => 'assistant',
  };
}
