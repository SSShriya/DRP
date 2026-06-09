import 'package:drp/services/match_service.dart';
import 'package:flutter/material.dart';
import '../models/match_card.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class UserProfileCard extends StatelessWidget {
  final MatchCard card;

  const UserProfileCard({
    super.key, 
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Profile card --
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProfilePicture(
                  name: card.title,
                  radius: 40,
                  fontsize: 32,
                  random: false,
                  img: card.imageUrl.isNotEmpty ? card.imageUrl : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: [
                          const Icon(Icons.school, size: 17),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${card.yearGroup} · ${card.university} · ${card.course}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 17),
                          Text(
                            card.location,
                            style: const TextStyle(fontSize: 16, color: Colors.grey,),
                          ),
                        ],
                      ),
                    ],
                  )
                ),          
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Shared event ──
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You both want to attend:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  card.eventName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5DA9E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            ),
          ),

          const SizedBox(height: 12),

          // ── Interests ──
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interests:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                ...card.interests.map(
                  (interest) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('★ ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(interest, style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Bio ──
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bio:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(card.bio, style: const TextStyle(fontSize: 16)),
              ]
            )
          ),

          const SizedBox(height: 16),

          // ── Block button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmBlock(context),
              icon: const Icon(Icons.block, color: Colors.red),
              label: const Text('Block User', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handleBlock(BuildContext context) async {
    try {
      await MatchService().blockUser(card.id);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block: $e')),
        );
      }
    }
  }

  void _confirmBlock(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block user?'),
        content: Text(
          'You won\'t be matched with ${card.title} again. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleBlock(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}


class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: child,
    );
  }
}