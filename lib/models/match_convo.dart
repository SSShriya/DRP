import 'match_card.dart';

class ChatConversation {
  final MatchCard matchCard;
  final int numMessages;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isSociety;

  const ChatConversation({
    required this.matchCard,
    this.numMessages = 0,
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    this.isOnline = false,
    this.isSociety = false,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      matchCard: MatchCard.fromJson(json),
      isSociety: json['event_id'] != null,
      numMessages: json['num_messages'] ?? 0,
    );
  }

  String get name => matchCard.title;
  String get otherUserId => matchCard.id;
  String get event => matchCard.eventName;
  List<String> get interests => matchCard.interests;
  String? get imageUrl => matchCard.imageUrl;
}
