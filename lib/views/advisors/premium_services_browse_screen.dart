import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/premium_service_model.dart';
import '../../services/premium_service.dart';
import '../menu_pages/customer_premium_requests_screen.dart';
import 'customer_premium_order_screen.dart';

class PremiumServicesBrowseScreen extends StatefulWidget {
  final bool showBackButton;

  const PremiumServicesBrowseScreen({
    Key? key,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  State<PremiumServicesBrowseScreen> createState() => _PremiumServicesBrowseScreenState();
}

class _PremiumServicesBrowseScreenState extends State<PremiumServicesBrowseScreen> {
  final _premiumService = PremiumService();

  bool _isLoading = true;
  List<PremiumCategoryModel> _categories = [];
  List<PremiumServiceModel> _services = [];

  int _selectedCategoryId = 0; // 0 = All

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load active categories
      final cats = await _premiumService.getPremiumCategories();
      _categories = cats;

      // 2. Load luxe services
      final servs = await _premiumService.getLuxeServices(
        categoryId: _selectedCategoryId > 0 ? _selectedCategoryId : null,
        activeOnly: true,
      );
      _services = servs;
    } catch (e) {
      debugPrint("Error loading luxe services: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _filterByCategory(int catId) async {
    setState(() {
      _selectedCategoryId = catId;
      _isLoading = true;
    });

    try {
      final servs = await _premiumService.getLuxeServices(
        categoryId: catId > 0 ? catId : null,
        activeOnly: true,
      );
      if (mounted) {
        setState(() {
          _services = servs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkHeader,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: const [
            Icon(Icons.diamond_rounded, color: AppColors.accentGold, size: 20),
            SizedBox(width: 8),
            Text(
              "Platinum Luxe Services",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentGold,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.receipt_long_rounded, size: 16),
            label: const Text(
              "My Orders",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerPremiumRequestsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accentGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              _buildHeroBanner(),

              const SizedBox(height: 16),

              // Categories Chips
              if (_categories.isNotEmpty) _buildCategoriesSection(),

              const SizedBox(height: 16),

              // Services List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategoryId == 0
                          ? "All Premium Offerings (${_services.length})"
                          : "Filtered Offerings (${_services.length})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedCategoryId != 0)
                      TextButton(
                        onPressed: () => _filterByCategory(0),
                        child: const Text("Show All", style: TextStyle(color: AppColors.accentGold, fontSize: 12)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
                )
              else if (_services.isEmpty)
                _buildEmptyState()
              else
                _buildServicesGrid(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B0D5D), Color(0xFF1F0433)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.workspace_premium, color: Colors.black, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "EXCLUSIVE RITUALS",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Custom Platinum Spiritual Work",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Browse specialized high-vibration spiritual services, custom spells, astrological deep-dives, and energy cleanings handcrafted by verified psychic masters.",
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSel = _selectedCategoryId == 0;
            return ChoiceChip(
              label: const Text("All Services"),
              selected: isSel,
              selectedColor: AppColors.accentGold,
              backgroundColor: AppColors.bgDarkCard,
              labelStyle: TextStyle(
                color: isSel ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => _filterByCategory(0),
            );
          }

          final cat = _categories[index - 1];
          final isSel = _selectedCategoryId == cat.id;

          return ChoiceChip(
            label: Text(cat.title),
            selected: isSel,
            selectedColor: AppColors.accentGold,
            backgroundColor: AppColors.bgDarkCard,
            labelStyle: TextStyle(
              color: isSel ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (_) => _filterByCategory(cat.id),
          );
        },
      ),
    );
  }

  Widget _buildServicesGrid() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final s = _services[index];
        final advPhotoUrl = ApiEndpoints.resolveImageUrl(s.advisorPhoto);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgDarkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Advisor Info & Price
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          backgroundImage: advPhotoUrl.isNotEmpty ? NetworkImage(advPhotoUrl) : null,
                          child: advPhotoUrl.isEmpty
                              ? Text(
                                  (s.advisorDisplayName != null && s.advisorDisplayName!.isNotEmpty)
                                      ? s.advisorDisplayName![0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.advisorDisplayName ?? "Psychic Master",
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: const [
                                  Icon(Icons.star, color: AppColors.accentGold, size: 13),
                                  SizedBox(width: 3),
                                  Text("5.0 Verified Advisor", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "\$${s.price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${s.duration} ${s.duration == 1 ? 'day' : 'days'} delivery",
                              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (s.serviceDescription != null && s.serviceDescription!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        s.serviceDescription!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12.5, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.diamond_rounded, size: 16, color: Colors.black),
                        label: Text(
                          "Order Service - \$${s.price.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerPremiumOrderScreen(
                                serviceId: s.id,
                                initialService: s,
                                advisorName: s.advisorDisplayName,
                                advisorPhoto: s.advisorPhoto,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.diamond_outlined, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text(
              "No premium services available in this category yet.",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              "Select 'All Services' or check back soon as verified advisors publish new rituals.",
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
