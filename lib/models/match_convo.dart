class ChatConversation {
  final String name;
  final List<String> interests;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final List<_Message> messages = [];

  ChatConversation({
    required this.name,
    required this.interests,
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

class _Message {
  final String text;
  final bool fromMe;

  _Message({required this.text, required this.fromMe});
}