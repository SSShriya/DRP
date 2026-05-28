import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Recommended Events',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: recCards.length,
              itemBuilder: (context, index) {
                return InteractiveCard(card: recCards[index]);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Matches',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: matchCards.length,
              itemBuilder: (context, index) {
                return InteractiveCard(card: matchCards[index]);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12)),
        ],
      ),
      bottomNavigationBar: const AppNavigationBar(),
    );
  }
}

class  AppCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const  AppCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const recCards = [
   AppCard(title: 'Cookie Making', subtitle: 'Baking Society', icon: Icons.cloud, color: Colors.indigo),
   AppCard(title: 'Fight Club', subtitle: 'Boxing Society', icon: Icons.cloud, color: Colors.indigo),
   AppCard(title: 'Listening Party', subtitle: 'Alternative Music Society', icon: Icons.cloud, color: Colors.indigo),
   AppCard(title: 'Off the Hook', subtitle: 'KnitSock', icon: Icons.cloud, color: Colors.indigo),
];

const matchCards = [
   AppCard(title: 'Jeremy', subtitle: 'KCL History', icon: Icons.person, color: Colors.pinkAccent),
   AppCard(title: 'Emily', subtitle: 'LSE Economics', icon: Icons.person, color: Colors.pinkAccent),
   AppCard(title: 'Carl', subtitle: 'Imperial Physics', icon: Icons.person, color: Colors.pinkAccent),
   AppCard(title: 'Anne', subtitle: 'UCL Psychology', icon: Icons.person, color: Colors.pinkAccent),
   AppCard(title: 'Geoffrey', subtitle: 'Royal Holloway Law', icon: Icons.person, color: Colors.pinkAccent),
   AppCard(title: 'Zenaidah', subtitle: 'Queen Mary Medicine', icon: Icons.person, color: Colors.pinkAccent),
];

class InteractiveCard extends StatelessWidget {
  final  AppCard card;

  const InteractiveCard({super.key, required this.card});
    
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child:
    Material(
      color: card.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {}, // handle tap
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(card.icon, color: Colors.white, size: 32),
              const Spacer(),
              Text(
                card.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: 0,
      onTap: (index) {}, // handle navigation
    );
  }
}