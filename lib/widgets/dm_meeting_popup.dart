import 'package:drp/widgets/pick_location_map.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class DMMeetingPopup extends StatefulWidget {
  final String? initialDate;
  final String? initialTime;
  final String? initialLocation;
  final double? initialLat;
  final double? initialLng;

  const DMMeetingPopup({
    super.key,
    this.initialDate,
    this.initialTime,
    this.initialLocation,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<DMMeetingPopup> createState() => _DMMeetingPopupState();
}

class _DMMeetingPopupState extends State<DMMeetingPopup> {
  static const _purple = Color(0xFF8789C0);

  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LatLng? _pickedLatLng;

  // ── Validation state ──────────────────────────────────────────────────────
  bool _dateError = false;
  bool _timeError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = DateTime.tryParse(widget.initialDate!);
    }
    if (widget.initialTime != null) {
      final parts = widget.initialTime!.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    if (widget.initialLocation != null) {
      _locationController.text = widget.initialLocation!;
    }
    if (widget.initialLat != null && widget.initialLng != null) {
      _pickedLatLng = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _purple,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF222222),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateError = false; // ← clear error once a value is chosen
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _purple,
            onSurface: Color(0xFF222222),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeError = false; // ← clear error once a value is chosen
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationMap(initialLocation: _pickedLatLng),
      ),
    );
    if (result != null) {
      setState(() {
        _pickedLatLng = result;
        if (_locationController.text.trim().isEmpty) {
          _locationController.text =
              '${result.latitude.toStringAsFixed(5)}, '
              '${result.longitude.toStringAsFixed(5)}';
        }
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Renders a picker button with an optional inline error message below it,
  /// mirroring the look of a [TextField] validation error.
  Widget _pickerField({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool hasValue,
    required bool hasError,
    required String errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: hasError ? Colors.red[700] : _purple),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Bitter',
                  color: hasError
                      ? Colors.red[700]
                      : hasValue
                      ? const Color(0xFF222222)
                      : Colors.grey[600],
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                // Red border when invalid, normal colours otherwise
                color: hasError
                    ? Colors.red[700]!
                    : hasValue
                    ? Colors.grey[400]!
                    : _purple.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        // Inline error — only visible after a failed submit attempt
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.red[700]),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontFamily: 'Bitter',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final String dateButtonText = _selectedDate != null
        ? DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!)
        : 'Choose Date';

    final String timeButtonText = _selectedTime != null
        ? _selectedTime!.format(context)
        : 'Choose Time';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Suggest a Meeting',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _purple,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // ── Date ─────────────────────────────────────────────────────
              const Text(
                'Date *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Bitter',
                ),
              ),
              const SizedBox(height: 6),
              _pickerField(
                onPressed: _pickDate,
                icon: Icons.calendar_month,
                label: dateButtonText,
                hasValue: _selectedDate != null,
                hasError: _dateError,
                errorText: 'Please select a date.',
              ),
              const SizedBox(height: 16),

              // ── Time ─────────────────────────────────────────────────────
              const Text(
                'Time *',
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              _pickerField(
                onPressed: _pickTime,
                icon: Icons.access_time_filled,
                label: timeButtonText,
                hasValue: _selectedTime != null,
                hasError: _timeError,
                errorText: 'Please select a time.',
              ),
              const SizedBox(height: 16),

              // ── Location ─────────────────────────────────────────────────
              const Text(
                'Location (Optional)',
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Enter a venue or postcode...',
                  hintStyle: const TextStyle(fontFamily: 'Bitter'),
                  prefixIcon: Icon(
                    _pickedLatLng != null
                        ? Icons.location_pin
                        : Icons.location_on,
                    color: _pickedLatLng != null
                        ? const Color(0xFF84DCC6)
                        : _purple,
                  ),
                  suffixIcon: _pickedLatLng != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Remove map pin',
                          onPressed: () => setState(() => _pickedLatLng = null),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: _pickedLatLng != null
                      ? const Color(0xFF409A83)
                      : _purple,
                ),
                label: Text(
                  _pickedLatLng != null ? 'Map pin attached ✓' : 'Pick on Map',
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 13,
                    color: _pickedLatLng != null
                        ? const Color(0xFF409A83)
                        : _purple,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: _pickedLatLng != null
                        ? const Color(0xFF84DCC6)
                        : _purple.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Confirm ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    // Mark whichever fields are still empty
                    final dateInvalid = _selectedDate == null;
                    final timeInvalid = _selectedTime == null;

                    if (dateInvalid || timeInvalid) {
                      setState(() {
                        _dateError = dateInvalid;
                        _timeError = timeInvalid;
                      });
                      return; // stop here — errors are now shown inline
                    }

                    Navigator.pop(context, {
                      'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                      'time': _selectedTime!.format(context),
                      'location': _locationController.text.trim(),
                      'lat': _pickedLatLng?.latitude,
                      'lng': _pickedLatLng?.longitude,
                    });
                  },
                  child: Text(
                    widget.initialDate != null
                        ? 'Update Invitation'
                        : 'Send Invitation',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
