import 'package:flutter/material.dart';
import '../models/event_card.dart';
import '../services/registration_service.dart';

class EventProfileScreen extends StatefulWidget {
  final EventCard card;

  const EventProfileScreen({super.key, required this.card});

  @override
  State<EventProfileScreen> createState() => _EventProfileScreenState();
}

class _EventProfileScreenState extends State<EventProfileScreen> {
  RegistrationService registrationService = RegistrationService();
  bool _isRegistered = false; 

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRegistered(); 
  }

  Future<void> _checkIfAlreadyRegistered() async {
    final isRegistered = await registrationService.hasRegistered(
      widget.card.eventId,
    );

    if (mounted) {
      setState(() {
        _isRegistered = isRegistered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _isRegistered ? registrationService.registerForEvent(widget.card.eventId) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0XFF84DCC6),
                  foregroundColor: const Color(0XFF222222),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRegistered ? const Text(
                    "You've already registered!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ) : const Text(
                    "I'm going!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}