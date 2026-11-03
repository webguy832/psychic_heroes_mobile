import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/payment_service.dart';
import '../../services/user_service.dart';
import '../shared/app_footer_widget.dart';
import '../shared/custom_button.dart';
import '../shared/custom_text_field.dart';

class AddFundsScreen extends StatefulWidget {
  const AddFundsScreen({Key? key}) : super(key: key);

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  int _currentStep = 1;
  final PaymentService _paymentService = PaymentService();
  final UserService _userService = UserService();

  // Data state
  List<PackageDto> _packages = [];
  List<CountryDto> _countries = [];
  PackageDto? _selectedPackage;
  String _selectedPaymentMethod = 'credit';
  String _couponCode = '';
  String? _couponStatus; // 'valid', 'invalid', 'checking'

  // Step 2 Form Controllers
  final _formKeyStep2 = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  CountryDto? _selectedCountry;
  BillingAddressDto? _existingBilling;

  // Step 3 Payment Controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvcController = TextEditingController();
  bool _isProcessing = false;
  String? _paymentErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final pkgs = await _paymentService.getPackages();
    final ctrs = await _paymentService.getCountries();
    final billings = await _userService.getBillingAddresses();

    if (mounted) {
      setState(() {
        _packages = pkgs;
        _countries = ctrs;
        if (_packages.isNotEmpty) {
          _selectedPackage = _packages.length > 1 ? _packages[1] : _packages.first;
        }
        if (_countries.isNotEmpty) {
          _selectedCountry = _countries.first;
        }

        if (billings.isNotEmpty) {
          _existingBilling = billings.first;
          _firstNameController.text = _existingBilling!.firstName ?? '';
          _lastNameController.text = _existingBilling!.lastName ?? '';
          _dobController.text = _existingBilling!.dateOfBirth ?? '';
          _emailController.text = _existingBilling!.email ?? '';
          _addressController.text = _existingBilling!.addressLine1;
          _cityController.text = _existingBilling!.city;
          _stateController.text = _existingBilling!.state;
          _postalCodeController.text = _existingBilling!.postalCode;
          _phoneController.text = _existingBilling!.phone ?? '';

          final matchCountry = _countries.firstWhere(
            (c) => c.countryText.toLowerCase() == _existingBilling!.country.toLowerCase() || c.id.toString() == _existingBilling!.country,
            orElse: () => _countries.first,
          );
          _selectedCountry = matchCountry;
        } else {
          final userProv = Provider.of<UserProvider>(context, listen: false);
          final u = userProv.user;
          if (u != null) {
            _firstNameController.text = u.firstName ?? (u.displayName.isNotEmpty ? u.displayName.split(' ').first : '');
            _lastNameController.text = u.lastName ?? (u.displayName.split(' ').length > 1 ? u.displayName.split(' ').sublist(1).join(' ') : '');
            _emailController.text = u.email;
            _phoneController.text = (u.phoneNumber?.isNotEmpty == true) ? u.phoneNumber! : (u.addressPhone ?? '');
            _dobController.text = u.dateOfBirth ?? '';
            _addressController.text = u.addressStreet ?? '';
            _cityController.text = u.addressCity ?? '';
            _stateController.text = u.addressState ?? '';
            _postalCodeController.text = u.addressZip ?? '';
          }
        }
      });
    }
  }

  void _validateCoupon() async {
    if (_couponCode.trim().isEmpty) return;
    setState(() => _couponStatus = 'checking');
    final valid = await _paymentService.validateCoupon(_couponCode.trim());
    setState(() => _couponStatus = valid ? 'valid' : 'invalid');
  }

  void _submitStep2() async {
    if (_formKeyStep2.currentState?.validate() == true) {
      final dto = BillingAddressDto(
        billingId: _existingBilling?.billingId ?? 0,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        email: _emailController.text.trim(),
        addressLine1: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _selectedCountry?.countryText ?? "United States",
        countryCode: _selectedCountry?.countryCode ?? "US",
        postalCode: _postalCodeController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      _existingBilling = dto;
      await _userService.createBillingAddress(dto);

      setState(() {
        _currentStep = 3;
      });
    }
  }

  void _handlePayNow(UserProvider userProv) async {
    if (_selectedPackage == null) return;
    setState(() {
      _isProcessing = true;
      _paymentErrorMessage = null;
    });

    final billingMap = _existingBilling?.toJson() ?? {};
    final clientSecret = await _paymentService.createPaymentIntent(_selectedPackage!.amount, billingMap);

    if (clientSecret != null) {
      final success = await _paymentService.confirmPayment("txn_${DateTime.now().millisecondsSinceEpoch}");

      if (success) {
        userProv.updateWalletBalance(userProv.userBalance + _selectedPackage!.amount + _selectedPackage!.promoAmount);
        userProv.addKarmaPoints((_selectedPackage!.amount * 10).toInt());

        setState(() => _isProcessing = false);

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgDarkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 28),
                SizedBox(width: 8),
                Text("Payment Successful!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Recharged \$${_selectedPackage!.amount.toStringAsFixed(2)} + \$${_selectedPackage!.promoAmount.toStringAsFixed(2)} Bonus into your wallet.", style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("New Wallet Balance:", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                      Text("\$${userProv.userBalance.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text("Earned +${(_selectedPackage!.amount * 10).toInt()} Karma Reward Points! 🎉", style: const TextStyle(color: AppColors.accentCyan, fontSize: 12)),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4E7E2A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("Done & Back to Wallet", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _isProcessing = false;
          _paymentErrorMessage = "Payment confirmation failed. Please check your card.";
        });
      }
    } else {
      setState(() {
        _isProcessing = false;
        _paymentErrorMessage = "Unable to create payment session. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 1,
        title: const Text("Add Funds & Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: AppStyles.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main Stepper Card matching Web App
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      children: [
                        // Stepper Header
                        _buildStepperHeader(),

                        const SizedBox(height: 28),

                        // Switch Step Content
                        if (_currentStep == 1)
                          _buildStep1Content()
                        else if (_currentStep == 2)
                          _buildStep2Content()
                        else
                          _buildStep3Content(userProv),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const AppFooterWidget(),
          ],
        ),
      ),
    );
  }

  // Web Stepper Header Component
  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Step 1 Circle
          _buildStepCircle(1, "Payment Mode"),
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep >= 2 ? const Color(0xFF4E7E2A) : AppColors.borderDark,
            ),
          ),
          // Step 2 Circle
          _buildStepCircle(2, "Billing Info"),
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep >= 3 ? const Color(0xFF4E7E2A) : AppColors.borderDark,
            ),
          ),
          // Step 3 Circle
          _buildStepCircle(3, "Confirm & Pay"),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF4E7E2A) : AppColors.bgDark,
            border: Border.all(
              color: isActive ? const Color(0xFF4E7E2A) : AppColors.borderDark,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(color: const Color(0xFF4E7E2A).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              "$step",
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  // STEP 1: Select Payment Mode & Amount Package
  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Select Payment Method",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            "Choose how you'd like to pay and select a package.",
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),

        // Payment Method Radio Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4E7E2A).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4E7E2A), width: 2),
          ),
          child: Row(
            children: const [
              Text("💳", style: TextStyle(fontSize: 28)),
              SizedBox(width: 14),
              Text(
                "Credit / Debit Card (Stripe)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Spacer(),
              Icon(Icons.check_circle_rounded, color: Color(0xFF4E7E2A), size: 22),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text("Select Amount Package", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),

        // Package Select Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PackageDto>(
              value: _selectedPackage,
              dropdownColor: AppColors.bgDarkCard,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
              items: _packages.map((pkg) {
                return DropdownMenuItem<PackageDto>(
                  value: pkg,
                  child: Text(
                    "Add \$${pkg.amount.toStringAsFixed(0)} — Free Bonus \$${pkg.promoAmount.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPackage = val);
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Package Card Grid Preview
        if (_packages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _packages.length,
            itemBuilder: (ctx, i) {
              final pkg = _packages[i];
              final isSelected = _selectedPackage?.id == pkg.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedPackage = pkg),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4E7E2A).withOpacity(0.2) : AppColors.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4E7E2A) : AppColors.borderDark,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "\$${pkg.amount.toStringAsFixed(0)}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? AppColors.accentGold : Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text("+ \$${pkg.promoAmount.toStringAsFixed(0)} Bonus Mins", style: const TextStyle(color: AppColors.onlineGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 20),

        // Coupon Input Option
        const Text("Promo / Coupon Code", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: TextEditingController(text: _couponCode),
                hintText: "Enter promo code (e.g. MAGIC10)",
                prefixIcon: Icons.local_offer_rounded,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bgDarkCardElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: _validateCoupon,
              child: const Text("Apply", style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_couponStatus == 'valid')
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text("✓ Coupon code applied successfully!", style: TextStyle(color: AppColors.onlineGreen, fontSize: 12)),
          )
        else if (_couponStatus == 'invalid')
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text("✕ Invalid promo code", style: TextStyle(color: AppColors.errorRed, fontSize: 12)),
          ),

        const SizedBox(height: 28),

        // Continue Button
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF369A23), Color(0xFF2E5626)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: const Color(0xFF369A23).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _currentStep = 2),
            child: const Text("Continue to Billing Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // STEP 2: Billing Info Form
  Widget _buildStep2Content() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Billing Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              "Provide your billing address as required for payment verification.",
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),

          // First Name & Last Name
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _firstNameController,
                  labelText: "First Name",
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: _lastNameController,
                  labelText: "Last Name",
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Date of Birth & Email
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _dobController,
                  labelText: "Date of Birth (YYYY-MM-DD)",
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: _emailController,
                  labelText: "Email Address",
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? "Valid email required" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Address Line 1
          CustomTextField(
            controller: _addressController,
            labelText: "Address Line 1",
            validator: (v) => (v == null || v.trim().isEmpty) ? "Address required" : null,
          ),
          const SizedBox(height: 14),

          // City & State
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _cityController,
                  labelText: "City",
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: _stateController,
                  labelText: "State / Province",
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Country & Postal Code
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Country", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CountryDto>(
                          value: _selectedCountry,
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                          items: _countries.map((c) {
                            return DropdownMenuItem<CountryDto>(
                              value: c,
                              child: Text(c.countryText),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCountry = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: _postalCodeController,
                  labelText: "Postal Code",
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Phone Number
          CustomTextField(
            controller: _phoneController,
            labelText: "Phone Number (International)",
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? "Phone number required" : null,
          ),

          const SizedBox(height: 28),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderDark),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => setState(() => _currentStep = 1),
                  child: const Text("Back", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF369A23), Color(0xFF2E5626)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitStep2,
                    child: const Text("Save & Continue", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 3: Confirm Order & Pay with Stripe
  Widget _buildStep3Content(UserProvider userProv) {
    final pkg = _selectedPackage ?? PackageDto(id: 1, amount: 25, promoAmount: 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Confirm & Pay",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            "Review package breakdown and enter card details to complete payment.",
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
        ),
        const SizedBox(height: 20),

        // Order Summary Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Selected Package:", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                  Text("\$${pkg.amount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Free Promo Bonus:", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                  Text("+\$${pkg.promoAmount.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.onlineGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const Divider(color: AppColors.borderDark, height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Credit Added:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("\$${(pkg.amount + pkg.promoAmount).toStringAsFixed(2)}", style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text("Payment Method: Credit / Debit Card (Stripe)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),

        // Card Details Input Fields
        CustomTextField(
          controller: _cardNumberController,
          labelText: "Card Number",
          hintText: "•••• •••• •••• ••••",
          prefixIcon: Icons.credit_card_rounded,
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _cardExpiryController,
                labelText: "Expiration (MM/YY)",
                hintText: "MM / YY",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: _cardCvcController,
                labelText: "CVC / CVV",
                hintText: "CVC",
                obscureText: true,
              ),
            ),
          ],
        ),

        if (_paymentErrorMessage != null) ...[
          const SizedBox(height: 10),
          Text(_paymentErrorMessage!, style: const TextStyle(color: AppColors.errorRed, fontSize: 12)),
        ],

        const SizedBox(height: 24),

        // Pay Button
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF369A23), Color(0xFF2E5626)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: const Color(0xFF369A23).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isProcessing ? null : () => _handlePayNow(userProv),
            child: _isProcessing
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text("Pay \$${pkg.amount.toStringAsFixed(2)} Now", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),

        const SizedBox(height: 10),

        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 2),
            child: const Text("Back to Billing Info", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
