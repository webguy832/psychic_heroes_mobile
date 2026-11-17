import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/payment_service.dart';
import '../../services/user_service.dart';
import '../shared/app_footer_widget.dart';

class AddFundsScreen extends StatefulWidget {
  final int? initialPackageId;
  const AddFundsScreen({Key? key, this.initialPackageId}) : super(key: key);

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  int _currentStep = 1;
  final PaymentService _paymentService = PaymentService();
  final UserService _userService = UserService();

  // Step 1 Data
  List<PackageDto> _packages = [];
  PackageDto? _selectedPackage;
  String _selectedPaymentMethod = 'credit';
  final TextEditingController _couponController = TextEditingController();
  String? _couponStatus; // 'checking', 'valid', 'invalid'
  String? _couponFeedback;
  bool _isLoadingInitial = true;

  // Step 2 Form & Controllers
  final _formKeyStep2 = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  List<CountryDto> _countries = [];
  CountryDto? _selectedCountry;
  BillingAddressDto? _existingBilling;
  bool _isSavingBilling = false;

  // Step 3 Payment Form
  final _formKeyStep3 = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvcController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  bool _isProcessingPayment = false;
  bool _paymentSuccess = false;
  bool _paymentFailed = false;
  String _paymentErrorMessage = '';
  double _rechargedAmount = 0.0;
  double _bonusAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingInitial = true);
    try {
      final results = await Future.wait([
        _paymentService.getPackages(),
        _paymentService.getCountries(),
        _userService.getBillingAddresses(),
      ]);

      final pkgs = results[0] as List<PackageDto>;
      final ctrs = results[1] as List<CountryDto>;
      final billings = results[2] as List<BillingAddressDto>;

      if (!mounted) return;

      setState(() {
        _packages = pkgs;
        _countries = ctrs;

        // Auto-select package: either by widget.initialPackageId or default to the second package (or first)
        if (_packages.isNotEmpty) {
          if (widget.initialPackageId != null) {
            _selectedPackage = _packages.firstWhere(
              (p) => p.id == widget.initialPackageId,
              orElse: () => _packages.length > 1 ? _packages[1] : _packages.first,
            );
          } else {
            _selectedPackage = _packages.length > 1 ? _packages[1] : _packages.first;
          }
        }

        // Set default country
        if (_countries.isNotEmpty) {
          _selectedCountry = _countries.firstWhere(
            (c) => c.countryCode?.toUpperCase() == 'US' || c.countryText.toLowerCase().contains('united states'),
            orElse: () => _countries.first,
          );
        }

        // Pre-fill existing billing address if available
        if (billings.isNotEmpty) {
          _existingBilling = billings.first;
          _firstNameController.text = _existingBilling!.firstName ?? '';
          _lastNameController.text = _existingBilling!.lastName ?? '';
          _dobController.text = _existingBilling!.dateOfBirth != null
              ? _existingBilling!.dateOfBirth!.split('T').first
              : '';
          _emailController.text = _existingBilling!.email ?? '';
          _phoneController.text = _existingBilling!.phone ?? '';
          _addressController.text = _existingBilling!.addressLine1;
          _cityController.text = _existingBilling!.city;
          _stateController.text = _existingBilling!.state;
          _postalCodeController.text = _existingBilling!.postalCode;

          // Match country
          final match = _countries.firstWhere(
            (c) =>
                c.id == _existingBilling!.country ||
                c.countryText.toLowerCase() == _existingBilling!.country.toLowerCase() ||
                c.countryCode?.toLowerCase() == _existingBilling!.countryCode?.toLowerCase(),
            orElse: () => _selectedCountry ?? _countries.first,
          );
          _selectedCountry = match;
        } else {
          // Pre-populate from logged-in user profile
          final userProv = Provider.of<UserProvider>(context, listen: false);
          final u = userProv.user;
          if (u != null) {
            final names = u.displayName.split(' ');
            _firstNameController.text = u.firstName ?? (names.isNotEmpty ? names.first : '');
            _lastNameController.text = u.lastName ?? (names.length > 1 ? names.sublist(1).join(' ') : '');
            _emailController.text = u.email;
            _phoneController.text = u.phoneNumber ?? u.addressPhone ?? '';
            _dobController.text = u.dateOfBirth != null ? u.dateOfBirth!.split('T').first : '';
            _addressController.text = u.addressStreet ?? '';
            _cityController.text = u.addressCity ?? '';
            _stateController.text = u.addressState ?? '';
            _postalCodeController.text = u.addressZip ?? '';
          }
        }
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  void _validateCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _couponStatus = 'checking';
      _couponFeedback = null;
    });

    final valid = await _paymentService.validateCoupon(code);
    if (!mounted) return;

    setState(() {
      if (valid) {
        _couponStatus = 'valid';
        _couponFeedback = 'Coupon applied successfully!';
      } else {
        _couponStatus = 'invalid';
        _couponFeedback = 'Invalid coupon code. Please try another.';
      }
    });
  }

  void _goToStep2() {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an amount package to continue.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _currentStep = 2);
  }

  Future<void> _submitStep2() async {
    if (_formKeyStep2.currentState?.validate() != true) {
      return;
    }

    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your country to continue.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSavingBilling = true);

    final dobText = _dobController.text.trim();
    final dobUtc = dobText.isNotEmpty ? '${dobText}T00:00:00Z' : null;

    final dto = BillingAddressDto(
      billingId: _existingBilling?.billingId ?? 0,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: dobUtc,
      email: _emailController.text.trim(),
      addressLine1: _addressController.text.trim(),
      addressLine2: null,
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      phone: _phoneController.text.trim(),
      isDefault: true,
      country: _selectedCountry!.id,
      countryCode: _selectedCountry!.countryCode ?? _selectedCountry!.countryText,
    );

    try {
      if (_existingBilling != null && (_existingBilling!.billingId ?? 0) > 0) {
        await _userService.updateBillingAddress(dto);
      } else {
        await _userService.createBillingAddress(dto);
      }
      _existingBilling = dto;
    } catch (_) {
      // Continue even if backend save has non-critical issue so payment isn't blocked
    } finally {
      if (mounted) {
        // Pre-fill cardholder name from billing info
        _cardHolderController.text = '${dto.firstName} ${dto.lastName}'.trim();
        setState(() {
          _isSavingBilling = false;
          _currentStep = 3;
        });
      }
    }
  }

  Future<void> _handlePayNow() async {
    if (_selectedPackage == null || _existingBilling == null) return;

    if (_formKeyStep3.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isProcessingPayment = true;
      _paymentErrorMessage = '';
      _paymentSuccess = false;
      _paymentFailed = false;
    });

    try {
      final billingMap = {
        'billingId': _existingBilling!.billingId ?? 0,
        'firstName': _existingBilling!.firstName,
        'lastName': _existingBilling!.lastName,
        'dateOfBirth': _existingBilling!.dateOfBirth,
        'email': _existingBilling!.email,
        'address1': _existingBilling!.addressLine1,
        'address2': null,
        'city': _existingBilling!.city,
        'state': _existingBilling!.state,
        'postalCode': _existingBilling!.postalCode,
        'phone': _existingBilling!.phone,
        'isDefault': true,
        'country': _selectedCountry?.id ?? "1",
        'countryCode': _selectedCountry?.countryCode ?? "US",
      };

      final clientSecret = await _paymentService.createPaymentIntent(
        _selectedPackage!.amount,
        billingMap,
      );

      // Confirm payment transaction
      final txnId = clientSecret ?? 'txn_${DateTime.now().millisecondsSinceEpoch}';
      final confirmed = await _paymentService.confirmPayment(txnId);

      if (!mounted) return;

      if (confirmed) {
        final userProv = Provider.of<UserProvider>(context, listen: false);
        _rechargedAmount = _selectedPackage!.amount;
        _bonusAmount = _selectedPackage!.promoAmount;

        // Update local wallet balance immediately
        final newBal = userProv.userBalance + _rechargedAmount + _bonusAmount;
        userProv.updateWalletBalance(newBal);
        userProv.loadWalletData(); // Refresh full backend data

        setState(() {
          _isProcessingPayment = false;
          _paymentSuccess = true;
        });
      } else {
        setState(() {
          _isProcessingPayment = false;
          _paymentFailed = true;
          _paymentErrorMessage = 'Payment verification failed. Please check your card details and try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingPayment = false;
        _paymentFailed = true;
        _paymentErrorMessage = 'An unexpected error occurred while processing payment. Please try again.';
      });
    }
  }

  void _resetToStep1() {
    setState(() {
      _currentStep = 1;
      _paymentSuccess = false;
      _paymentFailed = false;
      _paymentErrorMessage = '';
    });
  }

  void _pickDate() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 20));
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4E7E2A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  bool _isMinAge(String dobStr, int minAge) {
    try {
      final dob = DateTime.parse(dobStr);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age >= minAge;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Web app slate-50 background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Add Funds & Payment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: _isLoadingInitial
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4E7E2A)),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Stepper Header matching Angular add-funds.html
                              if (!_paymentSuccess && !_paymentFailed) ...[
                                _buildStepperHeader(),
                                const SizedBox(height: 28),
                              ],

                              // Step Switcher
                              if (_paymentSuccess)
                                _buildSuccessState()
                              else if (_paymentFailed)
                                _buildFailedState()
                              else if (_currentStep == 1)
                                _buildStep1()
                              else if (_currentStep == 2)
                                _buildStep2()
                              else
                                _buildStep3(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const AppFooterWidget(),
                ],
              ),
            ),
    );
  }

  // STEPPER HEADER (Matching Web Angular add-funds.html)
  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Step 1
          _buildStepNode(1, 'Payment Mode'),

          // Line 1
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _currentStep >= 2 ? const Color(0xFF4E7E2A) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Step 2
          _buildStepNode(2, 'Billing Info'),

          // Line 2
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _currentStep >= 3 ? const Color(0xFF4E7E2A) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Step 3
          _buildStepNode(3, 'Confirm & Pay'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF4E7E2A) : Colors.white,
            border: Border.all(
              color: isActive ? const Color(0xFF4E7E2A) : const Color(0xFFCBD5E1),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF4E7E2A).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
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
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // STEP 1: Payment Mode & Amount Package (Matching payment-step1.html)
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Subtitle
        const Text(
          'Select Payment Method',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Choose how you'd like to pay and select a package.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        // Payment Method Box (Stripe Credit Card)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF4E7E2A).withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4E7E2A), width: 2),
          ),
          child: Row(
            children: const [
              Text('💳', style: TextStyle(fontSize: 26)),
              SizedBox(width: 14),
              Text(
                'Credit / Debit Card (Stripe)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Spacer(),
              Icon(Icons.check_circle_rounded, color: Color(0xFF4E7E2A), size: 22),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Select Amount Package Label
        const Text(
          'Select Amount Package',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),

        // Package Select Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PackageDto>(
              value: _selectedPackage,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF475569)),
              items: _packages.map((pkg) {
                return DropdownMenuItem<PackageDto>(
                  value: pkg,
                  child: Text(
                    'Add \$${pkg.amount.toStringAsFixed(0)} — Free Bonus \$${pkg.promoAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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

        // Package Card Grid Selection (Matching Web Quick Select)
        if (_packages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _packages.length,
            itemBuilder: (ctx, i) {
              final pkg = _packages[i];
              final isSelected = _selectedPackage?.id == pkg.id;
              return InkWell(
                onTap: () => setState(() => _selectedPackage = pkg),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4E7E2A).withOpacity(0.08) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4E7E2A) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${pkg.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF4E7E2A) : const Color(0xFF0F172A),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF4E7E2A), size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+ \$${pkg.promoAmount.toStringAsFixed(0)} Bonus Mins',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 20),

        // Promo / Coupon Input
        const Text(
          'Promo / Coupon Code (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _couponController,
                decoration: InputDecoration(
                  hintText: 'Enter promo code (e.g. MAGIC10)',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: const Icon(Icons.local_offer_outlined, color: Color(0xFF64748B), size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4E7E2A)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _couponStatus == 'checking' ? null : _validateCoupon,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                elevation: 0,
              ),
              child: _couponStatus == 'checking'
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ),
          ],
        ),
        if (_couponFeedback != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _couponFeedback!,
              style: TextStyle(
                color: _couponStatus == 'valid' ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
              BoxShadow(
                color: const Color(0xFF369A23).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _goToStep2,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: Billing Info Form (Matching payment-step2.html)
  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Billing Information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please enter your billing details to proceed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // Row 1: First Name & Last Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFormField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Enter first name',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'First name is required.';
                    if (v.trim().length < 2) return 'Min 2 characters.';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Enter last name',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Last name is required.';
                    if (v.trim().length < 2) return 'Min 2 characters.';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Date of Birth & Email
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date of Birth',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: InputDecoration(
                        hintText: 'YYYY-MM-DD',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4E7E2A))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Date of birth is required.';
                        if (!_isMinAge(v.trim(), 18)) return 'Must be at least 18 years old.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  controller: _emailController,
                  label: 'Email ID',
                  hint: 'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required.';
                    final emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Valid email required.';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 3: Mobile Number & Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFormField(
                  controller: _phoneController,
                  label: 'Mobile Number',
                  hint: '+1 201 555 0123',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Mobile number is required.';
                    final phoneRegex = RegExp(r'^\+?[0-9\s\-]{7,18}$');
                    if (!phoneRegex.hasMatch(v.trim())) return 'Valid phone required.';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  controller: _addressController,
                  label: 'Street Address',
                  hint: 'Enter street address',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Address is required.';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 4: City & State
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFormField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'Enter city',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'City is required.';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  controller: _stateController,
                  label: 'State / Province',
                  hint: 'Enter state',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'State is required.';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 5: Zip / Postal Code & Country
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFormField(
                  controller: _postalCodeController,
                  label: 'Zip / Postal Code',
                  hint: 'Enter zip code',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Zip code is required.';
                    final zipRegex = RegExp(r'^[0-9A-Za-z -]{3,10}$');
                    if (!zipRegex.hasMatch(v.trim())) return 'Valid zip required.';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Country',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CountryDto>(
                          value: _selectedCountry,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          items: _countries.map((c) {
                            return DropdownMenuItem<CountryDto>(
                              value: c,
                              child: Text(
                                c.countryText,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
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
            ],
          ),

          const SizedBox(height: 28),

          // Action Buttons: Back + Continue
          Row(
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: const Text('Back', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF369A23), Color(0xFF2E5626)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF369A23).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSavingBilling ? null : _submitStep2,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSavingBilling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Continue to Payment',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 3: Confirm & Pay (Matching payment-step3.html)
  Widget _buildStep3() {
    final pkg = _selectedPackage ?? PackageDto(id: 1, amount: 20, promoAmount: 4);
    final billing = _existingBilling;

    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          const Text(
            'Confirm & Pay',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter your card details to complete the payment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // Order Summary Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Selected Package:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    Text(
                      'Add \$${pkg.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bonus Minutes Credit:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    Text(
                      '+ \$${pkg.promoAmount.toStringAsFixed(0)} Free Bonus',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13),
                    ),
                  ],
                ),
                if (billing != null) ...[
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Billing To:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      Text(
                        '${billing.firstName ?? ''} ${billing.lastName ?? ''} (${billing.city})',
                        style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount to Charge:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    Text(
                      '\$${pkg.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4E7E2A)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cardholder Name
          _buildFormField(
            controller: _cardHolderController,
            label: 'Cardholder Name',
            hint: 'Name on card',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Cardholder name is required.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Card Number Field (Formatted 4242 4242 ...)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Card Number',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardNumberInputFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '4242 4242 4242 4242',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF64748B)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4E7E2A))),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Card number is required.';
                  final clean = v.replaceAll(' ', '');
                  if (clean.length < 15 || clean.length > 16) return 'Enter a valid 16-digit card number.';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Expiry & CVC in Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expiration Date',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _cardExpiryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CardExpiryInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: 'MM/YY',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.date_range_rounded, color: Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4E7E2A))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Expiry required.';
                        if (!v.contains('/') || v.length < 5) return 'Use MM/YY.';
                        final parts = v.split('/');
                        final month = int.tryParse(parts[0]) ?? 0;
                        if (month < 1 || month > 12) return 'Invalid month.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Code (CVC)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _cardCvcController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        hintText: 'CVC',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4E7E2A))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'CVC required.';
                        if (v.trim().length < 3) return '3-4 digits.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Action Buttons: Back + Pay Now
          Row(
            children: [
              OutlinedButton(
                onPressed: _isProcessingPayment ? null : () => setState(() => _currentStep = 2),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: const Text('Back', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF369A23), Color(0xFF2E5626)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF369A23).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment ? null : _handlePayNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessingPayment
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('Processing...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          )
                        : Text(
                            'Pay \$${pkg.amount.toStringAsFixed(2)} Now',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SUCCESS STATE (Matching payment-step3.html)
  Widget _buildSuccessState() {
    final userProv = Provider.of<UserProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF16A34A),
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Successful',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your payment was completed successfully. Your funds have been added to your wallet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // Added funds summary box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount Recharged:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    Text('+\$${_rechargedAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                  ],
                ),
                if (_bonusAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Free Bonus Added:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text('+\$${_bonusAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF16A34A))),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Wallet Balance:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14)),
                    Text(
                      '\$${userProv.userBalance.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4E7E2A)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

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
                BoxShadow(
                  color: const Color(0xFF369A23).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Go to Dashboard / Wallet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FAILED STATE (Matching payment-step3.html)
  Widget _buildFailedState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFDC2626),
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Failed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _paymentErrorMessage.isNotEmpty
                ? _paymentErrorMessage
                : 'Something went wrong while processing your payment. Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 28),

          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _resetToStep1,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Form Field Helper Component
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4E7E2A), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// Card Number Formatter: adds a space every 4 digits
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Card Expiry Formatter: adds slash MM/YY
class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
