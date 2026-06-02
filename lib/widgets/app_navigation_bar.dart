import 'package:drp/models/event_card.dart';
import 'package:drp/screens/events_screen.dart';
import 'package:flutter/material.dart';
import '../models/match_convo.dart';
import '../screens/dm_home_screen.dart';

class AppNavigationBar extends StatelessWidget {
  final List<ChatConversation> conversations;
  final List<EventCard> recommendedEvents;
  final int currentIndex;

  const AppNavigationBar({
    super.key,
    required this.conversations,
    required this.recommendedEvents,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFFEBA6A9),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Events'),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        if (index == currentIndex) return; // alr here, do nothing
        switch (index) {
          case 0:
            // pop until back to route
            Navigator.popUntil(context, (route) => route.isFirst);
            break;
          case 1:
            // search screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventsScreen(
                  recommendedEvents: recommendedEvents,
                  conversations: conversations,
                ),
              ),
            );
            break;
          case 2:
            // dm screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DMOverviewScreen(
                  conversations: conversations,
                  recommendedEvents: recommendedEvents,
                ),
              ),
            );
            break;
          case 3:
            // Navigate to Profile screen (not implemented)
            break;
        }
      }, 
    );
  }
}
