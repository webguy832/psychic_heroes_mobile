import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
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

  @override
  Widget build(BuildContext context) {
    final home = Provider.of<HomeProvider>(context);

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
                    // Search Bar (Matching Web App)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (q) => home.searchAdvisors(q),
                        style: const TextStyle(color: AppColors.textPrimaryLight),
                        decoration: const InputDecoration(
                          hintText: "Search psychics, tarot readers, advisors...",
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.accentPurple),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 1. Hero Banners Carousel (<app-hero>)
                    HomeSliderWidget(sliders: home.sliders),

                    const SizedBox(height: 24),

                    // 2. Specialized Services (<app-services>)
                    const HomeServicesWidget(),

                    const SizedBox(height: 24),

                    // 3. Zodiac Horoscopes (<app-zodiac>)
                    const HomeZodiacWidget(),

                    const SizedBox(height: 24),

                    // 4. Featured Advisors (<app-advisors>)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Top Live Advisors",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "View All",
                            style: TextStyle(color: AppColors.ctaGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CategoryChipWidget(
                      categories: home.categories,
                      selectedCategoryId: home.selectedCategoryId,
                      onCategorySelected: (catId) => home.selectCategory(catId),
                    ),
                    const SizedBox(height: 14),

                    if (home.isLoading) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: LoadingIndicator(message: "Finding top advisors..."),
                      ),
                    ] else if (home.advisors.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            "No advisors matching search criteria",
                            style: TextStyle(color: AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    ] else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: home.advisors.length,
                        itemBuilder: (ctx, idx) {
                          final advisor = home.advisors[idx];
                          return AdvisorCardWidget(advisor: advisor);
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 5. Gamification Rewards Strip (<app-gamification-section>)
                    const HomeGamificationWidget(),

                    const SizedBox(height: 24),

                    // 6. Why Choose PsychicHeroes (<app-psychic-heroes>)
                    const HomeWhyChooseWidget(),

                    const SizedBox(height: 24),

                    // 7. How It Works (<app-how-it-work>)
                    const HomeHowItWorksWidget(),

                    const SizedBox(height: 24),

                    // 8. Client Testimonials (<app-testimonials>)
                    const HomeTestimonialsWidget(),

                    const SizedBox(height: 24),

                    // 9. FAQ Accordion (<app-faq>)
                    const HomeFaqWidget(),
                  ],
                ),
              ),

              // 10. Footer (<app-footer>)
              const AppFooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
