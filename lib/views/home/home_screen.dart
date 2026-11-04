import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/advisor_model.dart';
import '../../providers/home_provider.dart';
import '../shared/loading_indicator.dart';
import '../shared/app_footer_widget.dart';
import 'widgets/home_slider_widget.dart';
import 'widgets/home_services_widget.dart';
import 'widgets/home_zodiac_widget.dart';
import 'widgets/category_chip_widget.dart';
import 'widgets/advisor_card_widget.dart';
import 'widgets/home_gamification_widget.dart';
import 'widgets/home_why_choose_widget.dart';
import 'widgets/home_how_it_works_widget.dart';
import 'widgets/home_testimonials_widget.dart';
import 'widgets/home_faq_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridMode = true;
  String _currentSort = 'featured'; // 'featured', 'rating', 'readings', 'price_asc', 'price_desc', 'online'
  bool _onlineOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeProvider>(context, listen: false).initHomeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdvisorDto> _processAdvisors(List<AdvisorDto> original) {
    var list = List<AdvisorDto>.from(original);

    if (_onlineOnly) {
      list = list.where((a) => a.status.toLowerCase() == 'online').toList();
    }

    switch (_currentSort) {
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'reviews':
      case 'readings':
        list.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
        break;
      case 'price_asc':
        list.sort((a, b) => a.pricePerMinute.compareTo(b.pricePerMinute));
        break;
      case 'price_desc':
        list.sort((a, b) => b.pricePerMinute.compareTo(a.pricePerMinute));
        break;
      case 'online':
        list.sort((a, b) {
          if (a.status.toLowerCase() == 'online' && b.status.toLowerCase() != 'online') return -1;
          if (b.status.toLowerCase() == 'online' && a.status.toLowerCase() != 'online') return 1;
          return 0;
        });
        break;
      default:
        break;
    }
    return list;
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sort Advisors",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                _buildSortOption(ctx, "Featured / Recommended", 'featured', Icons.star_outline_rounded),
                _buildSortOption(ctx, "Highest Rating (★ 5.0)", 'rating', Icons.star_rounded),
                _buildSortOption(ctx, "Most Client Reviews", 'reviews', Icons.rate_review_outlined),
                _buildSortOption(ctx, "Price: Low to High", 'price_asc', Icons.arrow_upward_rounded),
                _buildSortOption(ctx, "Price: High to Low", 'price_desc', Icons.arrow_downward_rounded),
                _buildSortOption(ctx, "Online First", 'online', Icons.circle_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext ctx, String label, String sortKey, IconData icon) {
    final isSelected = _currentSort == sortKey;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSelected ? AppColors.ctaGreen : AppColors.primary),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.ctaGreen : AppColors.textPrimaryLight,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.ctaGreen) : null,
      onTap: () {
        setState(() => _currentSort = sortKey);
        Navigator.pop(ctx);
      },
    );
  }

  void _showFilterModal(HomeProvider home) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Filter Advisors",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _onlineOnly = false;
                              });
                              setState(() {
                                _onlineOnly = false;
                                home.selectCategory(null);
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text("Reset", style: TextStyle(color: AppColors.errorRed)),
                          ),
                        ],
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text(
                          "Show Only Online Now",
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                        ),
                        secondary: const Icon(Icons.circle, color: AppColors.onlineGreen, size: 14),
                        value: _onlineOnly,
                        activeColor: AppColors.ctaGreen,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setModalState(() => _onlineOnly = val);
                          setState(() => _onlineOnly = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Categories",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text("All Specialties"),
                            selected: home.selectedCategoryId == null,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: home.selectedCategoryId == null ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              home.selectCategory(null);
                              Navigator.pop(ctx);
                            },
                          ),
                          ...home.categories.map((c) {
                            final isSel = home.selectedCategoryId == c.id;
                            return ChoiceChip(
                              label: Text(c.name),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppColors.primary,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                home.selectCategory(c.id);
                                Navigator.pop(ctx);
                              },
                            );
                          }).toList(),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = Provider.of<HomeProvider>(context);
    final displayedAdvisors = _processAdvisors(home.advisors);

    // Split advisors into two batches for between-feed engagement cards (matching Pocket Insight)
    final firstBatch = displayedAdvisors.take(4).toList();
    final secondBatch = displayedAdvisors.skip(4).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: RefreshIndicator(
        color: AppColors.accentGoldDark,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await home.initHomeData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: AppStyles.paddingPage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Pocket Insight Style Search & Filter Toolbar
                    Row(
                      children: [
                        // Search Input
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEADBFF)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2B0844).withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (q) => home.searchAdvisors(q),
                              style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: "Search by advisor name or any key wo...",
                                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                                prefixIcon: Icon(Icons.search_rounded, color: AppColors.accentGold, size: 20),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Sort Button (≡)
                        InkWell(
                          onTap: _showSortModal,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 38,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEADBFF)),
                            ),
                            child: const Icon(Icons.sort_rounded, color: AppColors.primary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Filter Funnel Button (⧩)
                        InkWell(
                          onTap: () => _showFilterModal(home),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 38,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (_onlineOnly || home.selectedCategoryId != null)
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEADBFF)),
                            ),
                            child: Icon(
                              Icons.filter_alt_outlined,
                              color: (_onlineOnly || home.selectedCategoryId != null)
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Grid/List Toggle Button (⊞⊞)
                        InkWell(
                          onTap: () => setState(() => _isGridMode = !_isGridMode),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 38,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEADBFF)),
                            ),
                            child: Icon(
                              _isGridMode ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
                              color: AppColors.primary,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 2. Pocket Insight Style 50% OFF Promo Banner / Hero Carousel
                    if (home.sliders.isNotEmpty)
                      HomeSliderWidget(sliders: home.sliders)
                    else
                      _buildPromoHeroBanner(),

                    const SizedBox(height: 16),

                    // 3. Two Quick Action Feature Cards (Public Square & Flash Deal)
                    Row(
                      children: [
                        // Card 1: Public Square Reading & Chat
                        Expanded(
                          child: Container(
                            height: 94,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEADBFF)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2B0844).withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        "Public Square",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "Reading & Chat",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondaryLight,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.explore_rounded, color: AppColors.primary, size: 22),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Card 2: Flash Deal & Check-in (with OFF badge)
                        Expanded(
                          child: Container(
                            height: 94,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEADBFF)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2B0844).withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            "Flash Deal &",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            "Check-in",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondaryLight,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: -2,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorRed,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "OFF",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // 4. Section 1: Staff Pick with Concentric Circle Icon (◎ Staff Pick 💎)
                    _buildSectionHeader("Staff Pick", showDiamond: true),
                    const SizedBox(height: 12),

                    // Category Chips Filter
                    CategoryChipWidget(
                      categories: home.categories,
                      selectedCategoryId: home.selectedCategoryId,
                      onCategorySelected: (catId) => home.selectCategory(catId),
                    ),
                    const SizedBox(height: 14),

                    // Advisors Batch 1 (Top 4)
                    if (home.isLoading) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: LoadingIndicator(message: "Finding top advisors..."),
                      ),
                    ] else if (displayedAdvisors.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            "No advisors matching criteria",
                            style: TextStyle(color: AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    ] else ...[
                      _buildAdvisorsCollection(firstBatch),

                      const SizedBox(height: 20),

                      // 5. In-Feed Engagement Card 1: 5-Star Rating Card (Pocket Insight Architecture)
                      _buildRateUsCard(),

                      const SizedBox(height: 16),

                      // 6. In-Feed Engagement Card 2: Find Your Favorite Advisor / Palmistry Match
                      _buildMatchingCard(home),

                      const SizedBox(height: 24),

                      // 7. Section 2: Top Accuracy Advisors (◎ Top Accuracy)
                      if (secondBatch.isNotEmpty) ...[
                        _buildSectionHeader("Top Accuracy"),
                        const SizedBox(height: 14),
                        _buildAdvisorsCollection(secondBatch),
                        const SizedBox(height: 24),
                      ],
                    ],

                    // 8. Specialized Services (<app-services>)
                    const HomeServicesWidget(),

                    const SizedBox(height: 24),

                    // 9. Zodiac Horoscopes (<app-zodiac>)
                    const HomeZodiacWidget(),

                    const SizedBox(height: 24),

                    // 10. Gamification Rewards Strip (<app-gamification-section>)
                    const HomeGamificationWidget(),

                    const SizedBox(height: 24),

                    // 11. Why Choose PsychicHeroes (<app-psychic-heroes>)
                    const HomeWhyChooseWidget(),

                    const SizedBox(height: 24),

                    // 12. How It Works (<app-how-it-work>)
                    const HomeHowItWorksWidget(),

                    const SizedBox(height: 24),

                    // 13. Client Testimonials (<app-testimonials>)
                    const HomeTestimonialsWidget(),

                    const SizedBox(height: 24),

                    // 14. FAQ Accordion (<app-faq>)
                    const HomeFaqWidget(),
                  ],
                ),
              ),

              // 15. Footer (<app-footer>)
              const AppFooterWidget(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds concentric circle section header matching Pocket Insight screenshot (◎ Title 💎)
  Widget _buildSectionHeader(String title, {bool showDiamond = false}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentGold, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            color: AppColors.primary,
          ),
        ),
        if (showDiamond) ...[
          const SizedBox(width: 6),
          const Icon(Icons.diamond_rounded, size: 18, color: AppColors.accentGold),
        ],
      ],
    );
  }

  /// Builds advisors in responsive Grid or List view with zero empty space
  Widget _buildAdvisorsCollection(List<AdvisorDto> advisors) {
    if (_isGridMode) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxisCount = 2;
          if (width > 1100) {
            crossAxisCount = 4;
          } else if (width > 700) {
            crossAxisCount = 3;
          } else {
            crossAxisCount = 2;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: advisors.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 290,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (ctx, idx) {
              return AdvisorCardWidget(advisor: advisors[idx], isGrid: true);
            },
          );
        },
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: advisors.length,
      itemBuilder: (ctx, idx) {
        return AdvisorCardWidget(advisor: advisors[idx], isGrid: false);
      },
    );
  }

  /// Pocket Insight 50% OFF Hero Promo Banner styled in Psychic Heroes theme colors
  Widget _buildPromoHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B0844), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B0844).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "ENJOY",
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "50% OFF",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Discount Of Your 1st 24H Reading",
                  style: TextStyle(
                    color: Color(0xFFE9D5FF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: AppColors.accentGold, size: 36),
          ),
        ],
      ),
    );
  }

  /// Pocket Insight 5-Star Rating Card (rendered in light pastel/gold Psychic Heroes theme, not black)
  Widget _buildRateUsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE2CD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mystical Stars Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD97706), size: 32),
          ),
          const SizedBox(width: 14),

          // Rating Text & Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "We really appreciate if you give Psychic Heroes a 5-star rating and leave a good review.",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimaryLight,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Thank you for your rating and love!"),
                        backgroundColor: AppColors.ctaGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.thumb_up_alt_rounded, size: 14, color: Colors.white),
                  label: const Text(
                    "Rate us",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pocket Insight Palmistry Matching Card (rendered in light lavender/gold Psychic Heroes theme, not black)
  Widget _buildMatchingCard(HomeProvider home) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBFF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B0844).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Palmistry / Third Eye Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.pan_tool_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 14),

          // Matching Description & CTA Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Find your favorite advisor",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "Explore categories and find the right advisor for you.",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondaryLight,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _showFilterModal(home),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: const Color(0xFF2B0844),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Get Matched",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2B0844)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

