import 'package:drp/services/supabase_client.dart';
import 'session_manager.dart';
import 'package:intl/intl.dart';

Future<String> loadUserId() async {
  final user = supabase.auth.currentUser;
  if (user != null) return user.id;

  final id = await SessionManager.getUserId();
  if (id == null) {
    await SessionManager.clearSession();
    return '';
  }
  return id;
}

String formatGroupDate(DateTime dt) {
  final now = DateTime.now();
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(dt, now)) return 'Today';
  if (sameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
}

String formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String formatDate(String raw) {
  try {
    return DateFormat('EEE, MMM d yyyy').format(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

const String invitePrefix = 'INVITATION_DATA:';

/// Builds the raw INVITATION_DATA string from a result map.
/// [result] may optionally contain 'lat' and 'lng' (both double).
/// Old messages without those fields are still parsed correctly.
String buildInvitePayload(Map result) {
  final lat = result['lat'];
  final lng = result['lng'];
  final hasCoords = lat != null && lng != null;

  return '$invitePrefix{'
      '"date":"${result['date']}",'
      '"time":"${result['time']}",'
      '"location":"${result['location'] ?? ''}"'
      '${hasCoords ? ',"lat":$lat,"lng":$lng' : ''}'
      '}';
}

/// Extracts date / time / location / optional coords from a raw invite payload.
/// Returns null for lat/lng when the message pre-dates coordinate support.
({String date, String time, String location, double? lat, double? lng})
parseInvitePayload(String text) {
  final data = text.replaceFirst(invitePrefix, '');

  String pickStr(RegExp re) {
    final m = re.firstMatch(data);
    return m != null ? m.group(1)! : 'Not specified';
  }

  double? pickDouble(RegExp re) {
    final m = re.firstMatch(data);
    if (m == null) return null;
    return double.tryParse(m.group(1)!);
  }

  final loc = pickStr(RegExp(r'"location":"([^"]*)"'));
  return (
    date: pickStr(RegExp(r'"date":"([^"]+)"')),
    time: pickStr(RegExp(r'"time":"([^"]+)"')),
    location: loc.isEmpty ? 'Not specified' : loc,
    // These will be null for any message sent before this update
    lat: pickDouble(RegExp(r'"lat":([-\d.]+)')),
    lng: pickDouble(RegExp(r'"lng":([-\d.]+)')),
  );
}
