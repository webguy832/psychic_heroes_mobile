import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../shared/custom_button.dart';
import '../shared/custom_text_field.dart';

class BillingAddressScreen extends StatefulWidget {
  const BillingAddressScreen({Key? key}) : super(key: key);

  @override
  State<BillingAddressScreen> createState() => _BillingAddressScreenState();
}

class _BillingAddressScreenState extends State<BillingAddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchBillingAddresses();
    });
  }

  void _showAddDialog() {
    final address1Ctrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    final zipCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Billing Address"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: address1Ctrl, labelText: "Address Line 1"),
              const SizedBox(height: 12),
              CustomTextField(controller: cityCtrl, labelText: "City"),
              const SizedBox(height: 12),
              CustomTextField(controller: stateCtrl, labelText: "State / Region"),
              const SizedBox(height: 12),
              CustomTextField(controller: countryCtrl, labelText: "Country"),
              const SizedBox(height: 12),
              CustomTextField(controller: zipCtrl, labelText: "Postal / Zip Code"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final dto = BillingAddressDto(
                addressLine1: address1Ctrl.text.trim(),
                city: cityCtrl.text.trim(),
                state: stateCtrl.text.trim(),
                country: countryCtrl.text.trim(),
                postalCode: zipCtrl.text.trim(),
              );
              await Provider.of<UserProvider>(context, listen: false).createBillingAddress(dto);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Billing Addresses"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
      ),
      body: userProv.billingAddresses.isEmpty
          ? const Center(
              child: Text("No billing addresses saved.", style: TextStyle(color: AppColors.textSecondaryDark)),
            )
          : ListView.builder(
              padding: AppStyles.paddingPage,
              itemCount: userProv.billingAddresses.length,
              itemBuilder: (ctx, i) {
                final addr = userProv.billingAddresses[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: AppStyles.paddingCard,
                  decoration: BoxDecoration(
                    color: AppColors.bgDarkCard,
                    borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.accentGold),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(addr.addressLine1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text("${addr.city}, ${addr.state} ${addr.postalCode}", style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                            Text(addr.country, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
