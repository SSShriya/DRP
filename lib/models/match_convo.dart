class ChatConversation {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;

  ChatConversation({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
  });
}