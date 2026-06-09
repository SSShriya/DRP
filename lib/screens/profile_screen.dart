import 'dart:io';
import 'package:drp/screens/main_shell.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/session_manager.dart';
import '../models/useful_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestInputController = TextEditingController();

  // All three dropdowns managed as plain Strings
  String? _selectedUniversity;
  String? _selectedBorough;
  String? _selectedYearGroup;

  File? _imageFile;
  String? _existingAvatarUrl;
  final List<String> _interests = [];
  bool _isLoading = false;

  static const int _maxInterests = 10;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userdata = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      final interestsData = await supabase
          .from('user_interests')
          .select('interest')
          .eq('user_id', userId);

      if (userdata != null) {
        setState(() {
          _nameController.text = userdata['name'] ?? '';
          _courseController.text = userdata['course'] ?? '';
          _bioController.text = userdata['bio'] ?? '';

          // University — only accept known values
          final savedUniversity = userdata['university'] as String?;
          _selectedUniversity = londonUniversities.contains(savedUniversity)
              ? savedUniversity
              : null;

          // Borough — only accept known values
          final savedLocation = userdata['location'] as String?;
          _selectedBorough = londonBoroughs.contains(savedLocation)
              ? savedLocation
              : null;

          // Year group — only accept known values
          final savedYear = userdata['year_group'] as String?;
          _selectedYearGroup = yearGroups.contains(savedYear)
              ? savedYear
              : null;

          _existingAvatarUrl = userdata['avatar_url'];

          _interests.clear();
          _interests.addAll(
            (interestsData as List).map((e) => e['interest'] as String),
          );
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) _showError('Failed to load profile: ${e.message}');
    } catch (e) {
      if (mounted) _showError('Unexpected error loading profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _bioController.dispose();
    _interestInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _addInterest() {
    final text = _interestInputController.text.trim().toLowerCase();
    if (text.isEmpty) return;

    if (_interests.length >= _maxInterests) {
      _showError('You can add a maximum of $_maxInterests interests.');
      return;
    }
    if (_interests.contains(text)) {
      _showError('You\'ve already added "$text".');
      return;
    }

    setState(() {
      _interests.add(text);
      _interestInputController.clear();
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _showError('User session not found. Please log in again.');
      return;
    }

    // University is required — guard here too in case form validator is bypassed
    if (_selectedUniversity == null) {
      _showError('Please select your university.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_imageFile != null) {
        await uploadProfilePicture(_imageFile!, userId);
      }

      await updateDetails(
        userId,
        _nameController.text.trim(),
        _selectedUniversity!, // ← university
        _courseController.text.trim(),
        _bioController.text.trim(),
        _selectedYearGroup ?? '', // ← year group
        _selectedBorough ?? '', // ← borough
        _interests,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('An unexpected error occurred while saving.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out? Any unsaved changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await supabase.auth.signOut();
    await SessionManager.clearSession();

    if (mounted) Navigator.pushReplacementNamed(context, '/signup');
  }

  // ── Shared Autocomplete builder ───────────────────────────────────────────
  // Reusable so borough and university stay visually identical
  Widget _buildAutocompleteField({
    required String initialValue,
    required List<String> options,
    required String label,
    required IconData prefixIcon,
    required IconData itemIcon,
    required Color itemIconColor,
    required ValueChanged<String> onSelected,
    // Pass a key so Flutter can distinguish the two Autocomplete widgets
    Key? key,
    // Optional form validator — supply for required fields
    String? Function(String?)? validator,
  }) {
    return Autocomplete<String>(
      key: key,
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return options;
        return options.where(
          (option) => option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          ),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, filteredOptions) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = filteredOptions.elementAt(index);
                  return InkWell(
                    onTap: () => onSelectedOption(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(itemIcon, size: 18, color: itemIconColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          // Wire up the validator so the Form key catches it on save
          validator: validator,
        );
      },
      onSelected: (String value) {
        onSelected(value);
        FocusScope.of(context).unfocus();
      },
    );
  }

  // ── University Field ──────────────────────────────────────────────────────
  Widget _buildUniversityField() {
    return _buildAutocompleteField(
      key: const ValueKey('university'),
      initialValue: _selectedUniversity ?? '',
      options: londonUniversities,
      label: 'University',
      prefixIcon: Icons.school_outlined,
      itemIcon: Icons.school_outlined,
      itemIconColor: const Color(0xFF84DCC6),
      onSelected: (value) => setState(() => _selectedUniversity = value),
      // Required — must pick a university before saving
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Please select your university'
          : null,
    );
  }

  // ── Borough Field ─────────────────────────────────────────────────────────
  Widget _buildBoroughField() {
    return _buildAutocompleteField(
      key: const ValueKey('borough'),
      initialValue: _selectedBorough ?? '',
      options: londonBoroughs,
      label: 'Borough (optional)',
      prefixIcon: Icons.location_on_outlined,
      itemIcon: Icons.location_on_outlined,
      itemIconColor: const Color(0xFF84DCC6),
      onSelected: (value) => setState(() => _selectedBorough = value),
    );
  }

  // ── Year Group Dropdown ───────────────────────────────────────────────────
  Widget _buildYearGroupField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedYearGroup,
      decoration: InputDecoration(
        labelText: 'Year Group (optional)',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      hint: const Text('Select year group'),
      items: yearGroups.map((year) {
        final bool isPostgrad = year == 'Masters' || year == 'PhD';
        return DropdownMenuItem<String>(
          value: year,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPostgrad
                      ? const Color(0xFF84DCC6)
                      : year == 'Alumnus'
                      ? Colors.grey.shade400
                      : Colors.blue.shade200,
                ),
              ),
              Text(year),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedYearGroup = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Setup Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF84DCC6)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Profile Picture ──────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!) as ImageProvider
                                    : _existingAvatarUrl != null
                                    ? NetworkImage(_existingAvatarUrl!)
                                    : null,
                                child:
                                    (_imageFile == null &&
                                        _existingAvatarUrl == null)
                                    ? Icon(
                                        Icons.camera_alt_outlined,
                                        size: 40,
                                        color: Colors.grey.shade600,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0XFF84DCC6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Name ─────────────────────────────────────────────
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        required: true,
                      ),
                      const SizedBox(height: 16),

                      // ── University Autocomplete ──────────────────────────
                      _buildUniversityField(),
                      const SizedBox(height: 16),

                      // ── Course ───────────────────────────────────────────
                      _buildTextField(
                        controller: _courseController,
                        label: 'Course / Major',
                        icon: Icons.book_outlined,
                        required: false,
                      ),
                      const SizedBox(height: 16),

                      // ── Year Group ───────────────────────────────────────
                      _buildYearGroupField(),
                      const SizedBox(height: 16),

                      // ── Borough ──────────────────────────────────────────
                      _buildBoroughField(),
                      const SizedBox(height: 16),

                      // ── Interests ────────────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Interests',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_interests.length}/$_maxInterests',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add things you enjoy - e.g. tennis',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _interestInputController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onFieldSubmitted: (_) => _addInterest(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addInterest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0XFF84DCC6),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _interests.map((interest) {
                          return Chip(
                            label: Text(
                              interest,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            backgroundColor: Colors.grey.shade200,
                            deleteIcon: const Icon(
                              Icons.cancel,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onDeleted: () =>
                                setState(() => _interests.remove(interest)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // ── Bio ──────────────────────────────────────────────────────────
                      const Text(
                        'Bio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Introduce yourself!',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Save Button ──────────────────────────────────────
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFF84DCC6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SAVE PROFILE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Logout Button ────────────────────────────────────
                      ElevatedButton(
                        onPressed: _isLoading ? null : _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFFD5757),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'LOG OUT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool required,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: required ? label : '$label (optional)',
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter your $label'
                : null
          : null,
    );
  }
}
