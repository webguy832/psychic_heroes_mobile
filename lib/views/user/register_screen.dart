import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../shared/custom_button.dart';
import '../shared/custom_text_field.dart';
import '../shared/app_logo.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? referrerName;

  const RegisterScreen({
    Key? key,
    this.referrerName,
  }) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Customer Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  // Advisor Controllers
  final _advisorNameController = TextEditingController();
  final _advisorContactController = TextEditingController();
  final _advisorPasswordController = TextEditingController();
  final _advisorCountryController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _advisorFormKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _otpSent = false;
  String? _verificationId;
  int _registrationType = 0; // 0: Customer, 1: Advisor

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();

    _advisorNameController.dispose();
    _advisorContactController.dispose();
    _advisorPasswordController.dispose();
    _advisorCountryController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await auth.sendMemberLeadOtp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
      );

      if (mounted) {
        if (res['success'] != false) {
          setState(() {
            _otpSent = true;
            _verificationId = res['verificationId']?.toString();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? "OTP sent to your phone number"),
              backgroundColor: AppColors.successGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? "Failed to send OTP"),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  void _completeRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_otpController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter the 6-digit OTP verification code"), backgroundColor: AppColors.errorRed),
        );
        return;
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await auth.signUpUsingVerification(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        _passwordController.text.trim(),
        _otpController.text.trim(),
        _verificationId,
      );

      if (res.token != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Welcome to PsychicHeroes! Your account is active."),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      } else if (mounted && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _submitAdvisorRegistration() async {
    if (_advisorFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Advisor registration submitted! Verification team will contact you."),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const AppLogo(height: 32, isDarkBackground: true),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Tonal Curved Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF9F7FF), Color(0xFFEEF3FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const AppLogo(height: 44, showSubtitle: true, isDarkBackground: false),
                  const SizedBox(height: 8),
                  const Text(
                    "Your path to clarity begins here",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Join PsychicHeroes to connect with trusted spiritual & psychic guides.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Registration Type Pill Switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _registrationType = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _registrationType == 0 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  "Customer Sign Up",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _registrationType == 0 ? Colors.white : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _registrationType = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _registrationType == 1 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  "Advisor Registration",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _registrationType == 1 ? Colors.white : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Referrer Invitation Banner if present
                    if (widget.referrerName != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFCFAF7), Color(0xFFF4EADB)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "✨ Invited by ${widget.referrerName}!",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Complete sign up to claim your free session reward.",
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.errorRed.withOpacity(0.4)),
                        ),
                        child: Text(auth.errorMessage!, style: const TextStyle(color: AppColors.errorRed, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Customer Form (Type 0)
                    if (_registrationType == 0)
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _nameController,
                              labelText: "Enter Your Full Name",
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (v) => v == null || v.isEmpty ? "Name is required" : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _emailController,
                              labelText: "Email Address",
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || v.isEmpty ? "Email is required" : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _phoneController,
                              labelText: "Mobile Phone Number",
                              prefixIcon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty ? "Phone number is required" : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _passwordController,
                              labelText: "Password",
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: !_isPasswordVisible,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: AppColors.textSecondaryLight,
                                ),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                              validator: (v) => v == null || v.length < 6 ? "Minimum 6 characters" : null,
                            ),

                            if (_otpSent) ...[
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _otpController,
                                labelText: "Enter 6-Digit OTP Verification Code",
                                prefixIcon: Icons.mark_email_read_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ],

                            const SizedBox(height: 20),

                            CustomButton(
                              text: _otpSent ? "Verify & Create Customer Account" : "Send Verification OTP",
                              isLoading: auth.isLoading,
                              onPressed: _otpSent ? _completeRegistration : _sendOtp,
                            ),
                          ],
                        ),
                      )
                    // Advisor Form (Type 1)
                    else
                      Form(
                        key: _advisorFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _advisorNameController,
                              labelText: "Full Legal Name",
                              prefixIcon: Icons.badge_outlined,
                              validator: (v) => v == null || v.isEmpty ? "Full name is required" : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _advisorContactController,
                              labelText: "Email or Phone Number",
                              prefixIcon: Icons.contact_mail_outlined,
                              validator: (v) => v == null || v.isEmpty ? "Contact details required" : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _advisorPasswordController,
                              labelText: "Account Password",
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: !_isPasswordVisible,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: AppColors.textSecondaryLight,
                                ),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                              validator: (v) => v == null || v.length < 8 ? "Minimum 8 characters" : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _advisorCountryController,
                              labelText: "Country of Residence",
                              prefixIcon: Icons.public_rounded,
                              validator: (v) => v == null || v.isEmpty ? "Country is required" : null,
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: "Submit Advisor Application",
                              isLoading: auth.isLoading,
                              onPressed: _submitAdvisorRegistration,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?", style: TextStyle(color: AppColors.textSecondaryLight)),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text("Sign In", style: TextStyle(color: AppColors.ctaGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

