import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/dm_message.dart';
import '../services/utils.dart';

const _primaryColor = Color(0xFF8789C0);
const _accentColor = Color(0xFF84DCC6);
const _accentDark = Color(0xFF409A83);

class DmInvitationCard extends StatelessWidget {
  final DmMessage msg;
  final int index;
  final String myUserId;
  final void Function(int index) onEdit;
  final void Function(int index, bool accepted) onRespond;

  const DmInvitationCard({
    super.key,
    required this.msg,
    required this.index,
    required this.myUserId,
    required this.onEdit,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = parseInvitePayload(msg.text);
    final isPending = msg.invitationStatus == null;
    final lastEditedByMe = msg.lastEditedBy == myUserId;
    final shouldShowButtons =
        !lastEditedByMe &&
        (msg.lastEditedBy != null || (!msg.fromMe && msg.lastEditedBy == null));

    return Align(
      alignment: msg.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildBody(context, parsed, isPending, shouldShowButtons),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            msg.fromMe ? 'Meeting Sent' : 'Meeting Invitation',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ({String date, String time, String location, double? lat, double? lng})
    parsed,
    bool isPending,
    bool shouldShowButtons,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Date: ${formatDate(parsed.date)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '⏰ Time: ${parsed.time}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),

          // ── Location row with optional map chip ──────────────────────────
          _LocationRow(
            location: parsed.location,
            lat: parsed.lat,
            lng: parsed.lng,
          ),

          const Divider(height: 16),
          if (isPending)
            _buildPendingActions(shouldShowButtons)
          else
            _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildPendingActions(bool shouldShowButtons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => onEdit(index),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Edit', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (shouldShowButtons)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => onRespond(index, false),
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => onRespond(index, true),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          )
        else
          const Center(
            child: Text(
              'Waiting for reply...',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final accepted = msg.invitationStatus == true;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: accepted
              ? _accentColor.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          accepted ? 'Accepted ✓' : 'Declined ✕',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: accepted ? _accentDark : Colors.red,
          ),
        ),
      ),
    );
  }
}

// ── Location row ──────────────────────────────────────────────────────────────

class _LocationRow extends StatelessWidget {
  final String location;
  final double? lat;
  final double? lng;

  const _LocationRow({
    required this.location,
    required this.lat,
    required this.lng,
  });

  bool get _hasPin => lat != null && lng != null;

  void _openMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _ReadOnlyLocationMap(centre: LatLng(lat!, lng!), label: location),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '📍 Location: $location',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        // Only show the chip when real coordinates exist
        if (_hasPin) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _openMap(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accentColor, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 13, color: _accentDark),
                  SizedBox(width: 4),
                  Text(
                    'View Map',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _accentDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Read-only map screen ──────────────────────────────────────────────────────

class _ReadOnlyLocationMap extends StatelessWidget {
  final LatLng centre;
  final String label;

  const _ReadOnlyLocationMap({required this.centre, required this.label});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF84DCC6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Location'),
        backgroundColor: teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: centre, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.drp',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: centre,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      size: 48,
                      color: teal,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Bottom pill ───────────────────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 16, color: teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label == 'Not specified'
                          ? '${centre.latitude.toStringAsFixed(5)}, '
                                '${centre.longitude.toStringAsFixed(5)}'
                          : label,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
