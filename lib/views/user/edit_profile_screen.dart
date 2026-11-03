import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../shared/custom_button.dart';
import '../shared/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _screenNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedGender = "Not specified";
  String _selectedZodiac = "Aries";
  final _formKey = GlobalKey<FormState>();

  final List<String> _genders = ["Male", "Female", "Non-Binary", "Prefer Not to Say", "Not specified"];
  final List<String> _zodiacSigns = [
    "Aries", "Taurus", "Gemini", "Cancer",
    "Leo", "Virgo", "Libra", "Scorpio",
    "Sagittarius", "Capricorn", "Aquarius", "Pisces"
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _screenNameController.text = user.screenName ?? user.displayName;
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
      _dobController.text = (user.dateOfBirth != null && user.dateOfBirth != "Not set") ? user.dateOfBirth! : '';
      _streetController.text = user.addressStreet ?? '';
      _cityController.text = user.addressCity ?? '';
      _stateController.text = user.addressState ?? '';
      _zipController.text = user.addressZip ?? '';
      _countryController.text = user.addressCountry ?? user.country ?? '';
      _bioController.text = user.userDescription ?? '';

      if (user.gender != null && _genders.contains(user.gender)) {
        _selectedGender = user.gender!;
      }
      if (user.zodiacSign != null && _zodiacSigns.contains(user.zodiacSign)) {
        _selectedZodiac = user.zodiacSign!;
      }
    }
  }

  @override
  void dispose() {
    _screenNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProv.user;
      
      final updatedUser = (currentUser != null)
          ? currentUser.copyWith(
              email: _emailController.text.trim(),
              screenName: _screenNameController.text.trim(),
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
              phoneNumber: _phoneController.text.trim(),
              dateOfBirth: _dobController.text.trim(),
              gender: _selectedGender,
              zodiacSign: _selectedZodiac,
              country: _countryController.text.trim(),
              addressStreet: _streetController.text.trim(),
              addressCity: _cityController.text.trim(),
              addressState: _stateController.text.trim(),
              addressZip: _zipController.text.trim(),
              addressCountry: _countryController.text.trim(),
              addressPhone: _phoneController.text.trim(),
              userDescription: _bioController.text.trim(),
            )
          : UserModel(
              id: currentUser?.id ?? '',
              email: _emailController.text.trim(),
              screenName: _screenNameController.text.trim(),
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
              phoneNumber: _phoneController.text.trim(),
              dateOfBirth: _dobController.text.trim(),
              gender: _selectedGender,
              zodiacSign: _selectedZodiac,
              country: _countryController.text.trim(),
              addressStreet: _streetController.text.trim(),
              addressCity: _cityController.text.trim(),
              addressState: _stateController.text.trim(),
              addressZip: _zipController.text.trim(),
              addressCountry: _countryController.text.trim(),
              addressPhone: _phoneController.text.trim(),
              userDescription: _bioController.text.trim(),
            );

      final success = await userProv.updateUserProfile(updatedUser);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile & Contact Info"),
      ),
      body: SingleChildScrollView(
        padding: AppStyles.paddingPage,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Profile and Contact Info",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Update your personal profile, address, and contact details in sync with your account.",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Screen Name & Email
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _screenNameController,
                      labelText: "Screen Name *",
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _emailController,
                      labelText: "Email *",
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // First Name & Last Name
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstNameController,
                      labelText: "First Name",
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastNameController,
                      labelText: "Last Name",
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Phone & Country
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _phoneController,
                      labelText: "Mobile Number",
                      prefixIcon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _countryController,
                      labelText: "Country",
                      prefixIcon: Icons.public_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date of Birth & Zodiac Dropdown
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _dobController,
                      labelText: "Date of Birth (YYYY-MM-DD)",
                      prefixIcon: Icons.cake_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgDarkCard,
                        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedZodiac,
                          isExpanded: true,
                          dropdownColor: AppColors.bgDarkCard,
                          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentGold),
                          items: _zodiacSigns.map((z) => DropdownMenuItem(
                            value: z,
                            child: Text(z),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedZodiac = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Address Section (Matching Angular customer-dashboard-profile)
              const Text("Address Details", style: TextStyle(color: AppColors.accentGold, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              CustomTextField(
                controller: _streetController,
                labelText: "Street Address",
                prefixIcon: Icons.home_outlined,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      labelText: "City",
                      prefixIcon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      labelText: "State / Province",
                      prefixIcon: Icons.map_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              CustomTextField(
                controller: _zipController,
                labelText: "Postal / Zip Code",
                prefixIcon: Icons.markunread_mailbox_outlined,
              ),

              const SizedBox(height: 16),

              // About / User Description
              const Text("About & Spiritual Intentions", style: TextStyle(color: AppColors.accentGold, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _bioController,
                labelText: "User Description / Bio",
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Gender Selector
              const Text("Gender", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _genders.map((g) {
                  final isSelected = _selectedGender == g;
                  return ChoiceChip(
                    label: Text(g, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondaryDark, fontSize: 12)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.bgDarkCard,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedGender = g);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Green CTA Save Profile Button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF369A23), Color(0xFF2E5626)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF369A23).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium)),
                  ),
                  onPressed: userProv.isLoading ? null : _saveProfile,
                  child: userProv.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          "SAVE PROFILE",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
