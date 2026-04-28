import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/pages/modals/profile/profile_modal_shell.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/profile_service.dart';

class EditProfileModal extends ConsumerStatefulWidget {
  const EditProfileModal({super.key, required this.profile});

  final UserProfile profile;

  static Future<void> show(BuildContext context, UserProfile profile) {
    return ProfileModalShell.show<void>(
      context: context,
      builder: (context) => EditProfileModal(profile: profile),
    );
  }

  @override
  ConsumerState<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<EditProfileModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  DateTime? _selectedBirthDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.profile.resolvedFirstName,
    );
    _lastNameController = TextEditingController(
      text: widget.profile.resolvedLastName,
    );
    _emailController = TextEditingController(text: widget.profile.displayEmail);
    _phoneController = TextEditingController(
      text: widget.profile.phoneNumber ?? '',
    );
    _selectedBirthDate = widget.profile.birthDate;
    _birthDateController = TextEditingController(
      text: _formatDate(widget.profile.birthDate),
    );
    _locationController = TextEditingController(
      text: widget.profile.location ?? '',
    );
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final int safeDay = now.day > 28 ? 28 : now.day;
    final DateTime initialDate =
        _selectedBirthDate ??
        DateTime(now.year - 18, now.month, safeDay);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedBirthDate = picked;
      _birthDateController.text = _formatDate(picked);
    });
  }

  Future<void> _save() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(profileServiceProvider)
          .updateProfile(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            phoneNumber: _phoneController.text,
            birthDate: _selectedBirthDate,
            location: _locationController.text,
            bio: _bioController.text,
          );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } on ProfileFlowException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileModalShell(
      title: 'Edit Profile',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE9DAB8),
                            width: 4,
                          ),
                        ),
                        child: const CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            Icons.person,
                            size: 44,
                            color: Color(0xFF5B2CA0),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 0,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2F477A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap to change photo',
                    style: TextStyle(
                      color: Color(0xFF8B93A7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'First Name *',
                    controller: _firstNameController,
                    hintText: 'First name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Required';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    label: 'Last Name *',
                    controller: _lastNameController,
                    hintText: 'Last name',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Required';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Email Address *',
              controller: _emailController,
              hintText: 'Email Address',
              icon: Icons.mail_outline,
              enabled: false,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Phone Number',
              controller: _phoneController,
              hintText: '+ 1 (555) 000-0000',
              icon: Icons.call_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildField(
              label: 'Location',
              controller: _locationController,
              hintText: 'City, Country',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Bio',
              controller: _bioController,
              hintText: 'Tell us about yourself...',
              maxLines: 5,
            ),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: const Color(0xFFF1F3F7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF525D73),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25396F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Birth Date',
          style: TextStyle(
            color: Color(0xFF233866),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _birthDateController,
          readOnly: true,
          onTap: _pickBirthDate,
          decoration: _fieldDecoration(
            hintText: 'mm/dd/yyyy',
            icon: Icons.calendar_today_outlined,
            trailing: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFFA5AEBD),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF233866),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? const Color(0xFF223660) : const Color(0xFF7E889A),
          ),
          decoration: _fieldDecoration(hintText: hintText, icon: icon),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    IconData? icon,
    Widget? trailing,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFA5AEBD)),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: const Color(0xFFA5AEBD), size: 20),
      suffixIcon: trailing,
      filled: true,
      fillColor: const Color(0xFFF7F8FB),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E6EF)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E6EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF25396F)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }
}
