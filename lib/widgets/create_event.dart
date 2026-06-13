import 'package:drp/services/supabase_client.dart';
import 'package:drp/widgets/pick_location_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Data class returned when the user confirms the form.
class NewEventData {
  final String name;
  final DateTime startDate;
  final TimeOfDay startTime;
  final DateTime endDate;
  final TimeOfDay endTime;
  final String location;
  final double? latitude;
  final double? longitude;
  final double price;
  final String? description;
  final XFile? image;
  final bool committeeCanMeet;
  final String? committeeMeetingLocation;
  final TimeOfDay? committeeMeetingTime;
  final String? committeeMemberId;

  const NewEventData({
    required this.name,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.price,
    this.description,
    this.image,
    required this.committeeCanMeet,
    this.committeeMeetingLocation,
    this.committeeMeetingTime,
    this.committeeMemberId,
  });
}

/// Shows the popup and returns [NewEventData] if the user saves, or null if cancelled.
Future<NewEventData?> showNewEventPopup(
  BuildContext context, {
  String? existingName,
  DateTime? existingStartDate,
  TimeOfDay? existingStartTime,
  DateTime? existingEndDate,
  TimeOfDay? existingEndTime,
  String? existingLocation,
  double? existingLatitude,
  double? existingLongitude,
  double? existingPrice,
  String? existingDescription,
  bool existingCommitteeCanMeet = false,
  String? existingCommitteeMeetingLocation,
  TimeOfDay? existingCommitteeMeetingTime,
  String? existingCommitteeMemberId,
  String? societyId,
}) {
  return showDialog<NewEventData>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CreateEventForm(
      existingName: existingName,
      existingStartDate: existingStartDate,
      existingStartTime: existingStartTime,
      existingEndDate: existingEndDate,
      existingEndTime: existingEndTime,
      existingLocation: existingLocation,
      existingLongitude: existingLongitude,
      existingLatitude: existingLatitude,
      existingPrice: existingPrice,
      existingDescription: existingDescription,
      existingCommitteeCanMeet: existingCommitteeCanMeet,
      existingCommitteeMeetingLocation: existingCommitteeMeetingLocation,
      existingCommitteeMeetingTime: existingCommitteeMeetingTime,
      existingCommitteeMemberId: existingCommitteeMemberId,
      societyId: societyId,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _CreateEventForm extends StatefulWidget {
  final String? existingName;
  final DateTime? existingStartDate;
  final TimeOfDay? existingStartTime;
  final DateTime? existingEndDate;
  final TimeOfDay? existingEndTime;
  final String? existingLocation;
  final double? existingLatitude;
  final double? existingLongitude;
  final double? existingPrice;
  final String? existingDescription;
  final bool existingCommitteeCanMeet;
  final String? existingCommitteeMeetingLocation;
  final TimeOfDay? existingCommitteeMeetingTime;
  final String? existingCommitteeMemberId;
  final String? societyId;

  const _CreateEventForm({
    this.existingName,
    this.existingStartDate,
    this.existingStartTime,
    this.existingEndDate,
    this.existingEndTime,
    this.existingLocation,
    this.existingLongitude,
    this.existingLatitude,
    this.existingPrice,
    this.existingDescription,
    this.existingCommitteeCanMeet = false,
    this.existingCommitteeMeetingLocation,
    this.existingCommitteeMeetingTime,
    this.existingCommitteeMemberId,
    this.societyId,
  });

  @override
  State<_CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<_CreateEventForm> {
  static const _teal = Color(0XFF84DCC6);
  static const _dark = Color(0XFF222222);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;
  late final TextEditingController _committeeMeetingLocationController;

  bool _committeeCanMeet = false;
  TimeOfDay? _committeeMeetingTime;

  String? _selectedCommitteeMemberId;
  List<Map<String, dynamic>> _committeeMembers = [];
  bool _loadingMembers = false;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  LatLng? _pickedLocation;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isSaving = false;

  // ── Inline error messages ─────────────────────────────────────────────────
  // Each nullable string holds the current error for that field.
  // null  → no error shown
  // non-null → red error text rendered beneath the field
  String? _startDateError;
  String? _endDateError;
  String? _locationError;
  String? _committeeMemberError;
  String? _committeeMeetingLocationError;
  String? _committeeMeetingTimeError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingName ?? '');
    _locationController = TextEditingController(
      text: widget.existingLocation ?? '',
    );
    _priceController = TextEditingController(
      text: widget.existingPrice != null
          ? widget.existingPrice!
                .toStringAsFixed(2)
                .replaceAll(RegExp(r'\.00$'), '')
          : '',
    );
    _descController = TextEditingController(
      text: widget.existingDescription ?? '',
    );
    _committeeCanMeet = widget.existingCommitteeCanMeet;
    _committeeMeetingLocationController = TextEditingController(
      text: widget.existingCommitteeMeetingLocation ?? '',
    );
    _committeeMeetingTime = widget.existingCommitteeMeetingTime;
    _selectedCommitteeMemberId = widget.existingCommitteeMemberId;

    _startDate = widget.existingStartDate;
    _startTime = widget.existingStartTime;
    _endDate = widget.existingEndDate;
    _endTime = widget.existingEndTime;

    _pickedLocation =
        (widget.existingLatitude != null && widget.existingLongitude != null)
        ? LatLng(widget.existingLatitude!, widget.existingLongitude!)
        : null;

    if (widget.societyId != null) {
      _loadCommitteeMembers();
    }

    // Clear location error when the user types
    _locationController.addListener(() {
      if (_locationError != null &&
          _locationController.text.trim().isNotEmpty) {
        setState(() => _locationError = null);
      }
    });

    // Clear committee meeting location error when the user types
    _committeeMeetingLocationController.addListener(() {
      if (_committeeMeetingLocationError != null &&
          _committeeMeetingLocationController.text.trim().isNotEmpty) {
        setState(() => _committeeMeetingLocationError = null);
      }
    });
  }

  Future<void> _loadCommitteeMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final data = await supabase
          .from('committee_members')
          .select('id, name, role, avatar_url')
          .eq('society_id', widget.societyId!);
      setState(() {
        _committeeMembers = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Error loading committee members: $e');
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _committeeMeetingLocationController.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  String _fmtTime(TimeOfDay? t) =>
      t == null ? 'Select time' : t.format(context);

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final first = isStart
        ? (widget.existingStartDate ?? now)
        : (_startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _teal,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // Clear the start date/time error as soon as a date is picked
        _startDateError = null;
        _endDate ??= picked;
        if (_endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
        // Clear the end date/time error as soon as a date is picked
        _endDateError = null;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? _startTime ?? const TimeOfDay(hour: 10, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _teal,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
        // Clear start error once both date+time are set
        if (_startDate != null) _startDateError = null;
        _endTime ??= TimeOfDay(
          hour: (picked.hour + 1) % 24,
          minute: picked.minute,
        );
      } else {
        _endTime = picked;
        // Clear end error once both date+time are set
        if (_endDate != null) _endDateError = null;
      }
    });
  }

  Future<void> _pickCommitteeMeetingTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _committeeMeetingTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _teal,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _committeeMeetingTime = picked;
      // Clear the meeting time error once a time is chosen
      _committeeMeetingTimeError = null;
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationMap(initialLocation: _pickedLocation),
      ),
    );
    if (result != null) {
      setState(() {
        _pickedLocation = result;
        // A map pin counts as a valid location — clear the error
        _locationError = null;
      });
    }
  }

  Future<void> _save() async {
    // ── 1. Run Flutter form validators (name, price) ──────────────────────
    final formValid = _formKey.currentState!.validate();

    // ── 2. Validate every custom (non-TextFormField) field ────────────────
    //       Collect ALL errors before returning so every field lights up at once.
    String? startDateErr;
    String? endDateErr;
    String? locationErr;
    String? committeeMemberErr;
    String? committeeMeetingLocationErr;
    String? committeeMeetingTimeErr;

    final textLocation = _locationController.text.trim();
    if (textLocation.isEmpty && _pickedLocation == null) {
      locationErr = 'Enter an address or pick a location on the map';
    }

    if (_startDate == null || _startTime == null) {
      startDateErr = _startDate == null && _startTime == null
          ? 'Please select a start date and time'
          : _startDate == null
          ? 'Please select a start date'
          : 'Please select a start time';
    }

    if (_endDate == null || _endTime == null) {
      endDateErr = _endDate == null && _endTime == null
          ? 'Please select an end date and time'
          : _endDate == null
          ? 'Please select an end date'
          : 'Please select an end time';
    }

    // Only validate end > start when both are fully set
    if (startDateErr == null && endDateErr == null) {
      final startDT = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDT = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );
      if (!endDT.isAfter(startDT)) {
        endDateErr = 'End date/time must be after the start';
      }
    }

    if (_committeeCanMeet) {
      if (_selectedCommitteeMemberId == null) {
        committeeMemberErr = 'Please select a committee member';
      }
      if (_committeeMeetingLocationController.text.trim().isEmpty) {
        committeeMeetingLocationErr = 'Please enter a meeting location';
      }
      if (_committeeMeetingTime == null) {
        committeeMeetingTimeErr = 'Please select a meeting time';
      }
    }

    // ── 3. Push all errors into state at once ─────────────────────────────
    setState(() {
      _startDateError = startDateErr;
      _endDateError = endDateErr;
      _locationError = locationErr;
      _committeeMemberError = committeeMemberErr;
      _committeeMeetingLocationError = committeeMeetingLocationErr;
      _committeeMeetingTimeError = committeeMeetingTimeErr;
    });

    // ── 4. Bail out if anything is invalid ────────────────────────────────
    if (!formValid ||
        startDateErr != null ||
        endDateErr != null ||
        locationErr != null ||
        committeeMemberErr != null ||
        committeeMeetingLocationErr != null ||
        committeeMeetingTimeErr != null) {
      return;
    }

    setState(() => _isSaving = true);

    final startDT = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final result = NewEventData(
      name: _nameController.text.trim(),
      startDate: _startDate!,
      startTime: _startTime!,
      endDate: _endDate!,
      endTime: _endTime!,
      location: textLocation.isNotEmpty
          ? textLocation
          : '${_pickedLocation!.latitude.toStringAsFixed(5)}, '
                '${_pickedLocation!.longitude.toStringAsFixed(5)}',
      latitude: _pickedLocation?.latitude,
      longitude: _pickedLocation?.longitude,
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      image: _imageFile,
      committeeCanMeet: _committeeCanMeet,
      committeeMeetingLocation: _committeeCanMeet
          ? _committeeMeetingLocationController.text.trim()
          : null,
      committeeMeetingTime: _committeeCanMeet ? _committeeMeetingTime : null,
      committeeMemberId: _committeeCanMeet ? _selectedCommitteeMemberId : null,
    );

    if (mounted) Navigator.of(context).pop(result);
  }

  // ── Inline error text widget ──────────────────────────────────────────────
  // Renders a red error line that matches Flutter's native TextFormField style.
  Widget _errorText(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 14),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 13, color: Colors.redAccent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              error,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Date/time row with inline error ──────────────────────────────────────
  Widget _buildDateTimeRow({required bool isStart, required String? error}) {
    final date = isStart ? _startDate : _endDate;
    final time = isStart ? _startTime : _endTime;
    final hasError = error != null;

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(isStart: isStart),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                      color: hasError ? Colors.redAccent : null,
                    ),
                    labelStyle: hasError
                        ? const TextStyle(color: Colors.redAccent)
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: hasError ? errorBorder : null,
                    focusedBorder: hasError ? errorBorder : null,
                  ),
                  child: Text(
                    _fmt(date),
                    style: TextStyle(
                      color: date == null
                          ? (hasError ? Colors.redAccent : Colors.grey.shade500)
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(isStart: isStart),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Time',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(
                      Icons.access_time_outlined,
                      color: hasError ? Colors.redAccent : null,
                    ),
                    labelStyle: hasError
                        ? const TextStyle(color: Colors.redAccent)
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: hasError ? errorBorder : null,
                    focusedBorder: hasError ? errorBorder : null,
                  ),
                  child: Text(
                    _fmtTime(time),
                    style: TextStyle(
                      color: time == null
                          ? (hasError ? Colors.redAccent : Colors.grey.shade500)
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _errorText(error),
      ],
    );
  }

  // ── Committee member picker widget ────────────────────────────────────────
  Widget _buildCommitteeMemberPicker() {
    if (_loadingMembers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_committeeMembers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'No committee members added yet. Add some in your profile.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    // Use the dedicated state variable instead of a local derived bool so the
    // error persists until the user actually selects a member.
    final bool showError = _committeeMemberError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select Committee Member',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Text(
              ' *',
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _committeeMembers.map((member) {
              final id = '${member['id']}';
              final name = member['name'] as String? ?? '';
              final role = member['role'] as String? ?? '';
              final avatarUrl = member['avatar_url'] as String?;
              final isSelected = _selectedCommitteeMemberId == id;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCommitteeMemberId = isSelected ? null : id;
                  // Clear error as soon as a member is tapped
                  if (!isSelected) _committeeMemberError = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10, bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF84DCC6).withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF84DCC6)
                          : showError
                          ? Colors.redAccent
                          : Colors.grey.shade300,
                      width: isSelected || showError ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                            (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF4D5359)
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            role,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF84DCC6),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        _errorText(_committeeMemberError),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditingMode = widget.existingName != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: const Color.fromARGB(255, 131, 187, 219),
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                isEditingMode ? 'EDIT EVENT' : 'NEW EVENT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ImagePicker(bytes: _imageBytes, onTap: _pickImage),
                      const SizedBox(height: 25),

                      // ── Event name ───────────────────────────────────────
                      _field(
                        controller: _nameController,
                        label: 'Event Name',
                        icon: Icons.celebration_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter an event name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // ── Start date & time ────────────────────────────────
                      _SectionLabel(
                        label: 'Start Date & Time',
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      _buildDateTimeRow(isStart: true, error: _startDateError),
                      const SizedBox(height: 14),

                      // ── End date & time ──────────────────────────────────
                      _SectionLabel(
                        label: 'End Date & Time',
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      _buildDateTimeRow(isStart: false, error: _endDateError),
                      const SizedBox(height: 14),

                      // ── Location ─────────────────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              hintText: 'Type an address or pick on map',
                              prefixIcon: Icon(
                                _pickedLocation != null
                                    ? Icons.location_pin
                                    : Icons.location_on_outlined,
                                color: _locationError != null
                                    ? Colors.redAccent
                                    : _pickedLocation != null
                                    ? const Color(0xFF84DCC6)
                                    : null,
                              ),
                              labelStyle: _locationError != null
                                  ? const TextStyle(color: Colors.redAccent)
                                  : null,
                              enabledBorder: _locationError != null
                                  ? OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    )
                                  : null,
                              focusedBorder: _locationError != null
                                  ? OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    )
                                  : null,
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_pickedLocation != null)
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      tooltip: 'Clear map pin',
                                      onPressed: () => setState(
                                        () => _pickedLocation = null,
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.map_outlined),
                                    tooltip: 'Pick on map',
                                    onPressed: _pickLocation,
                                  ),
                                ],
                              ),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_pickedLocation != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.push_pin,
                                    size: 14,
                                    color: Color(0xFF84DCC6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Map pin attached',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _errorText(_locationError),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Price ────────────────────────────────────────────
                      _field(
                        controller: _priceController,
                        label: 'Price (£)',
                        icon: Icons.currency_pound_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a price (use 0 for free events)';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Description ──────────────────────────────────────
                      _field(
                        controller: _descController,
                        label: 'Description (optional)',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      // ── Committee member meeting section ─────────────────
                      const Divider(),
                      const SizedBox(height: 4),
                      _SectionLabel(
                        label: 'Committee Member Availability',
                        color: Colors.black,
                      ),
                      const SizedBox(height: 4),

                      Container(
                        decoration: BoxDecoration(
                          color: _committeeCanMeet
                              ? const Color(0xFF84DCC6).withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _committeeCanMeet
                                ? const Color(0xFF84DCC6)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          title: const Text(
                            'Is a committee member willing to meet before the event?',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: _committeeCanMeet,
                          activeThumbColor: const Color(0xFF84DCC6),
                          onChanged: (val) {
                            setState(() {
                              _committeeCanMeet = val;
                              if (!val) {
                                _committeeMeetingLocationController.clear();
                                _committeeMeetingTime = null;
                                _selectedCommitteeMemberId = null;
                                // Clear all committee-related errors
                                _committeeMemberError = null;
                                _committeeMeetingLocationError = null;
                                _committeeMeetingTimeError = null;
                              }
                            });
                          },
                        ),
                      ),

                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: _committeeCanMeet
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Member picker ────────────────────────────
                              if (widget.societyId != null)
                                _buildCommitteeMemberPicker(),

                              // ── Meeting location ─────────────────────────
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller:
                                        _committeeMeetingLocationController,
                                    decoration: InputDecoration(
                                      labelText: 'Meeting Location',
                                      hintText: 'e.g. Main entrance, Room 4B…',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      prefixIcon: Icon(
                                        Icons.meeting_room_outlined,
                                        color:
                                            _committeeMeetingLocationError !=
                                                null
                                            ? Colors.redAccent
                                            : null,
                                      ),
                                      labelStyle:
                                          _committeeMeetingLocationError != null
                                          ? const TextStyle(
                                              color: Colors.redAccent,
                                            )
                                          : null,
                                      enabledBorder:
                                          _committeeMeetingLocationError != null
                                          ? OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.redAccent,
                                                width: 1.5,
                                              ),
                                            )
                                          : null,
                                      focusedBorder:
                                          _committeeMeetingLocationError != null
                                          ? OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.redAccent,
                                                width: 1.5,
                                              ),
                                            )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  _errorText(_committeeMeetingLocationError),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ── Meeting time ─────────────────────────────
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: _pickCommitteeMeetingTime,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Meeting Time',
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        prefixIcon: Icon(
                                          Icons.access_time_outlined,
                                          color:
                                              _committeeMeetingTimeError != null
                                              ? Colors.redAccent
                                              : null,
                                        ),
                                        labelStyle:
                                            _committeeMeetingTimeError != null
                                            ? const TextStyle(
                                                color: Colors.redAccent,
                                              )
                                            : null,
                                        enabledBorder:
                                            _committeeMeetingTimeError != null
                                            ? OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Colors.redAccent,
                                                  width: 1.5,
                                                ),
                                              )
                                            : null,
                                        focusedBorder:
                                            _committeeMeetingTimeError != null
                                            ? OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Colors.redAccent,
                                                  width: 1.5,
                                                ),
                                              )
                                            : null,
                                        suffixIcon:
                                            _committeeMeetingTime != null
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                ),
                                                tooltip: 'Clear time',
                                                onPressed: () => setState(
                                                  () => _committeeMeetingTime =
                                                      null,
                                                ),
                                              )
                                            : null,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _fmtTime(_committeeMeetingTime),
                                        style: TextStyle(
                                          color: _committeeMeetingTime == null
                                              ? (_committeeMeetingTimeError !=
                                                        null
                                                    ? Colors.redAccent
                                                    : Colors.grey.shade500)
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _errorText(_committeeMeetingTimeError),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 24),

                      _ActionButton(
                        label: _isSaving
                            ? ''
                            : (isEditingMode ? 'SAVE CHANGES' : 'CREATE EVENT'),
                        color: const Color.fromARGB(255, 164, 204, 228),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),

                      _ActionButton(
                        label: 'Cancel',
                        color: const Color.fromARGB(255, 217, 218, 219),
                        foreground: _dark,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 1.2,
        color: color,
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onTap;
  const _ImagePicker({required this.bytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          image: bytes != null
              ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover)
              : null,
        ),
        child: bytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: Color(0xFF4D5359),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add banner image (optional)',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4D5359)),
                  ),
                ],
              )
            : const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0XFF84DCC6),
                    child: Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback? onPressed;
  final Widget? child;

  const _ActionButton({
    required this.label,
    required this.color,
    this.foreground = Colors.white,
    this.onPressed,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            child ??
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
      ),
    );
  }
}
