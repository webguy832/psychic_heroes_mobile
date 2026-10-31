import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../advisors/advisor_dashboard_screen.dart';
import '../shared/custom_button.dart';
import '../shared/custom_text_field.dart';
import '../shared/app_logo.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleLogin({bool forceLogin = false}) async {
    if (_tabController.index == 0 && !_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final emailOrPhone = _tabController.index == 0
        ? _emailController.text.trim()
        : _phoneController.text.trim();
    final password = _tabController.index == 0 ? _passwordController.text.trim() : null;
    final otp = _tabController.index == 1 ? _otpController.text.trim() : null;

    final response = await auth.login(
      emailOrPhone,
      password,
      otp: otp,
      forceLogin: forceLogin,
    );

    if (response.success && response.token != null && mounted) {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      await userProv.fetchUserProfile();
      final user = userProv.user;
      final role = (response.userRole ?? user?.role ?? '').toLowerCase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Welcome back, ${user?.fullName ?? 'User'}!"),
          backgroundColor: AppColors.successGreen,
        ),
      );

      Navigator.pop(context);

      if (role.contains('advisor') || role.contains('psychic')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdvisorDashboardScreen()),
        );
      }
    } else if ((response.requiresConfirmation || response.isAlreadyLoggedIn) && !forceLogin && mounted) {
      _showDuplicateLoginModal();
    } else if (auth.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showDuplicateLoginModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Active Session Detected",
                style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          "You are already signed in on another device or session. Would you like to terminate the existing session and sign in here?",
          style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogin(forceLogin: true);
            },
            child: const Text("Force Sign In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
            // Top Tonal Curved Banner (Matching Original Web App)
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
                    "Speak with trusted psychic advisors for peace, insight, and confidence.",
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
                    // Auth Method Tabs (Email/Passkey vs OTP)
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondaryLight,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(text: "Email / Passkey"),
                        Tab(text: "Phone OTP"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.errorRed.withOpacity(0.4)),
                        ),
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      height: 280,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Email & Passkey
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  controller: _emailController,
                                  labelText: "Email or Mobile Number",
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => v == null || v.isEmpty ? "Email/Mobile is required" : null,
                                ),
                                const SizedBox(height: 14),
                                CustomTextField(
                                  controller: _passwordController,
                                  labelText: "Passkey / Password",
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: !_isPasswordVisible,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? "Passkey is required" : null,
                                ),
                                const SizedBox(height: 20),
                                CustomButton(
                                  text: "Sign In",
                                  isLoading: auth.isLoading,
                                  onPressed: () => _handleLogin(),
                                ),
                              ],
                            ),
                          ),

                          // Tab 2: Phone OTP
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomTextField(
                                controller: _phoneController,
                                labelText: "Mobile Phone Number",
                                prefixIcon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              if (_otpSent) ...[
                                CustomTextField(
                                  controller: _otpController,
                                  labelText: "Enter 6-digit OTP Code",
                                  prefixIcon: Icons.pin_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 12),
                              ] else ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentGold,
                                      foregroundColor: AppColors.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    onPressed: () => setState(() => _otpSent = true),
                                    child: const Text("Get OTP", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              CustomButton(
                                text: _otpSent ? "Verify & Sign In" : "Send Verification OTP",
                                isLoading: auth.isLoading,
                                onPressed: () {
                                  if (!_otpSent) {
                                    setState(() => _otpSent = true);
                                  } else {
                                    _handleLogin();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Switch to Register
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(color: AppColors.ctaGreen, fontWeight: FontWeight.bold),
                  ),
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

