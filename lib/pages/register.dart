import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/login.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/auth_service.dart';

/// Only allows letters, spaces, hyphens, and apostrophes — blocks digits.
class _NameTextInputFormatter extends TextInputFormatter {
  // Matches any character that is NOT a Unicode letter, space, hyphen, or
  // apostrophe.
  static final RegExp _blocked = RegExp(r"[^a-zA-Z\s\-\u0027]");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = newValue.text.replaceAll(_blocked, '');
    if (filtered == newValue.text) {
      return newValue;
    }
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool isChecked = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool _isSubmitting = false;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Validators ──────────────────────────────────────────────────────────

  /// Regex that matches valid name characters: letters, spaces, hyphens,
  /// apostrophes.
  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");

  String? _validateName(String? value, String fieldName) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return '$fieldName is required.';
    }

    if (trimmed.length < 2) {
      return '$fieldName is too short.';
    }

    if (!_nameRegex.hasMatch(trimmed)) {
      return '$fieldName must contain letters only.';
    }

    return null;
  }

  String? _validateBirthDate(String? value) {
    if ((value ?? '').trim().isEmpty || _selectedBirthDate == null) {
      return 'Date of birth is required.';
    }

    final today = DateTime.now();
    final latestAllowed = DateTime(today.year - 13, today.month, today.day);
    if (_selectedBirthDate!.isAfter(latestAllowed)) {
      return 'You must be at least 13 years old.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }

    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 6) {
      return 'Use at least 6 characters.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final latestAllowed = DateTime(now.year - 13, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: latestAllowed,
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _dateController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions to continue.'),
        ),
      );
      return;
    }

    final birthDate = _selectedBirthDate;
    if (birthDate == null) {
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final String displayName = '$firstName $lastName';

    try {
      await ref
          .read(authServiceProvider)
          .register(
            email: email,
            password: _passwordController.text,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            birthDate: birthDate,
          );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/setgoals', (route) => false);
    } on AuthFlowException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C4A73), Color(0xFF0F223A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight > 48
                        ? constraints.maxHeight - 48
                        : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      //  TOP LOGO
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/imgs/Nutrisense.png',
                              height: 40,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "NUTRISENSE",
                              style: TextStyle(
                                color: Color(0xFFD6B97B),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      //  CARD
                      Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // TITLE
                              const Text(
                                "Sign up to create account",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      inputFormatters: [
                                        _NameTextInputFormatter(),
                                      ],
                                      validator: (value) =>
                                          _validateName(value, 'First name'),
                                      decoration: const InputDecoration(
                                        hintText: "First Name",
                                        hintStyle: TextStyle(
                                          color: Colors.white54,
                                        ),
                                        errorStyle: TextStyle(
                                          color: Colors.white70,
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      inputFormatters: [
                                        _NameTextInputFormatter(),
                                      ],
                                      validator: (value) =>
                                          _validateName(value, 'Last name'),
                                      decoration: const InputDecoration(
                                        hintText: "Last Name",
                                        hintStyle: TextStyle(
                                          color: Colors.white54,
                                        ),
                                        errorStyle: TextStyle(
                                          color: Colors.white70,
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // DATE
                              TextFormField(
                                controller: _dateController,
                                readOnly: true,
                                onTap: () => _selectDate(context),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: _validateBirthDate,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "mm/dd/yyyy",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  errorStyle: TextStyle(color: Colors.white70),
                                  suffixIcon: Icon(
                                    Icons.calendar_today,
                                    color: Colors.white54,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white38),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // EMAIL
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                style: const TextStyle(color: Colors.white),
                                validator: _validateEmail,
                                decoration: const InputDecoration(
                                  hintText: "Email Address",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: Colors.white54,
                                  ),
                                  errorStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white38),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // PASSWORD
                              TextFormField(
                                controller: _passwordController,
                                obscureText: obscurePassword,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                style: const TextStyle(color: Colors.white),
                                validator: _validatePassword,
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.white54,
                                  ),
                                  errorStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white38),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // CONFIRM PASSWORD
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: obscureConfirm,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                style: const TextStyle(color: Colors.white),
                                validator: _validateConfirmPassword,
                                decoration: InputDecoration(
                                  hintText: "Confirm Password",
                                  hintStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.white54,
                                  ),
                                  errorStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureConfirm
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureConfirm = !obscureConfirm;
                                      });
                                    },
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white38),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // CHECKBOX
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    onChanged: _isSubmitting
                                        ? null
                                        : (value) {
                                            setState(() {
                                              isChecked = value ?? false;
                                            });
                                          },
                                    activeColor: const Color(0xFFD6B97B),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      "I accept and agree to comply with Nutrisense Terms and Conditions and Privacy Policy",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // SIGN UP BUTTON
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: _isSubmitting || !isChecked
                                      ? null
                                      : _submit,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text("Sign Up"),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // SIGN IN LINK
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Already have an account? ",
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        color: Color(0xFFD6B97B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
  }
}
