import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/advisor_model.dart';
import '../../providers/home_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/advisor_service.dart';
import '../advisors/advisor_detail_screen.dart';

class ServiceDetailInfo {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String categoryKeyword;
  final List<String> highlights;
  final List<String> whatToExpect;
  final List<String> whyChoose;

  const ServiceDetailInfo({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.categoryKeyword,
    required this.highlights,
    required this.whatToExpect,
    required this.whyChoose,
  });
}

class ServiceDetailScreen extends StatefulWidget {
  final String serviceType;

  const ServiceDetailScreen({Key? key, required this.serviceType}) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final AdvisorService _advisorService = AdvisorService();
  List<AdvisorDto> _matchingAdvisors = [];
  bool _isLoadingAdvisors = true;

  static const Map<String, ServiceDetailInfo> _servicesMap = {
    'psychic': ServiceDetailInfo(
      title: 'Psychic Readings',
      subtitle: 'General life guidance, intuitive insight & clarity',
      description:
          'Our gifted psychics provide direct answers to your most pressing questions about life, love, career, and spiritual growth. Get personalized intuitive guidance to help you navigate challenges, make important decisions, and find your true path with confidence and clarity.',
      icon: Icons.visibility_rounded,
      categoryKeyword: 'psychic',
      highlights: [
        'Direct answers to life\'s most pressing questions',
        'Intuitive guidance on love, career, and life path',
        'Spiritual insight and future predictions',
      ],
      whatToExpect: [
        'Direct answers to your specific questions',
        'Intuitive guidance on life decisions',
        'Spiritual insight and future predictions',
        'Connection with spiritual guides and energy',
      ],
      whyChoose: [
        'Gain clarity on confusing life situations',
        'Receive direct intuitive guidance and answers',
        'Understand your life\'s purpose and direction',
        'Get personalized spiritual insights and predictions',
      ],
    ),
    'tarot': ServiceDetailInfo(
      title: 'Tarot Card Reading',
      subtitle: 'Reveal answers through intuitive tarot readings',
      description:
          'Reveal answers through intuitive tarot readings that guide your life decisions. Our skilled tarot readers use ancient wisdom combined with modern intuition to provide you with accurate, personalized insights. Whether you\'re seeking guidance on love, career, or spiritual matters, our experts can help you find clarity through the cards.',
      icon: Icons.style_rounded,
      categoryKeyword: 'tarot',
      highlights: [
        'Personalized guidance tailored to your specific questions',
        'Love, career & life questions answered with clarity',
        'Chat, call & video sessions available 24/7',
      ],
      whatToExpect: [
        'Insight into love & relationships',
        'Career and financial clarity',
        'Decision-making guidance',
        'Emotional and spiritual understanding',
      ],
      whyChoose: [
        'Gain clarity in uncertain situations',
        'Understand emotional patterns',
        'Make confident life decisions',
        'Receive intuitive and personalized guidance',
      ],
    ),
    'love': ServiceDetailInfo(
      title: 'Love & Relationships',
      subtitle: 'Clarity on love, compatibility & soulmates',
      description:
          'Find clarity on love, compatibility, soulmates, and relationship decisions. Our experienced advisors provide compassionate guidance to help you navigate the complexities of romantic relationships, whether you\'re seeking your soulmate, working through challenges in your current partnership, or healing from past heartbreak.',
      icon: Icons.favorite_rounded,
      categoryKeyword: 'love',
      highlights: [
        'Expert guidance on love compatibility and soulmate connections',
        'Relationship problem-solving and communication advice',
        'Breakup healing and future relationship insights',
      ],
      whatToExpect: [
        'Insight into soulmate connections and compatibility',
        'Guidance on relationship challenges and solutions',
        'Timing predictions for relationship milestones',
        'Communication and intimacy improvement advice',
      ],
      whyChoose: [
        'Gain clarity on confusing relationship dynamics',
        'Understand your partner\'s true feelings and intentions',
        'Make confident decisions about your relationship future',
        'Receive healing guidance for past relationship wounds',
      ],
    ),
    'career': ServiceDetailInfo(
      title: 'Career & Money Insight',
      subtitle: 'Guidance on career paths, promotions & financial stability',
      description:
          'Get guidance on career paths, promotions, and financial stability. Our expert advisors help you navigate professional challenges, identify lucrative opportunities, and make strategic decisions about your financial future. Whether you\'re considering a career change or seeking advancement, our experienced readers provide insights you need.',
      icon: Icons.work_rounded,
      categoryKeyword: 'career',
      highlights: [
        'Expert career path analysis and guidance',
        'Financial planning and investment insights',
        'Business startup and entrepreneurship advice',
      ],
      whatToExpect: [
        'Career path analysis and optimal timing',
        'Financial opportunity identification',
        'Business and entrepreneurship guidance',
        'Investment and wealth-building insights',
      ],
      whyChoose: [
        'Gain clarity on career direction and purpose',
        'Understand financial patterns and opportunities',
        'Make confident professional and financial decisions',
        'Receive strategic guidance for business success',
      ],
    ),
    'spiritual': ServiceDetailInfo(
      title: 'Spiritual & Healing Sessions',
      subtitle: 'Aura reading, chakra balancing & spiritual wellness',
      description:
          'Our spiritual healers help you cleanse negative energy, balance your chakras, and restore your natural spiritual vitality. Experience deep relaxation, emotional release, and spiritual renewal through various healing modalities and energy work techniques.',
      icon: Icons.self_improvement_rounded,
      categoryKeyword: 'healing',
      highlights: [
        'Professional aura cleansing and energy clearing',
        'Chakra balancing and alignment sessions',
        'Energy healing and spiritual wellness guidance',
      ],
      whatToExpect: [
        'Comprehensive aura analysis and cleansing',
        'Chakra balancing and energy alignment',
        'Release of negative energy and emotional blockages',
        'Spiritual renewal and energy restoration',
      ],
      whyChoose: [
        'Clear energetic blockages affecting your life',
        'Restore balance to mind, body, and spirit',
        'Experience deep relaxation and stress relief',
        'Receive personalized energy healing guidance',
      ],
    ),
    'dream': ServiceDetailInfo(
      title: 'Dreams & Numerology Readings',
      subtitle: 'Symbol interpretation and life pattern analysis',
      description:
          'Our dream interpreters and numerology experts help you understand the hidden meanings in your dreams and decode the numerical patterns that shape your destiny. Get insights into your life path, soul purpose, and future opportunities through the wisdom of dreams and sacred numbers.',
      icon: Icons.nights_stay_rounded,
      categoryKeyword: 'dream',
      highlights: [
        'Expert dream symbol interpretation and analysis',
        'Personalized numerology readings and life path analysis',
        'Understanding of recurring dream patterns',
      ],
      whatToExpect: [
        'Detailed dream symbol interpretation and meaning',
        'Personalized numerology readings and life analysis',
        'Understanding of recurring patterns and cycles',
        'Insights into life purpose and destiny',
      ],
      whyChoose: [
        'Understand the hidden meanings in your dreams',
        'Decode the numerical patterns shaping your life',
        'Gain clarity on life path and soul purpose',
        'Receive personalized symbolic and mathematical guidance',
      ],
    ),
  };

  ServiceDetailInfo get _info =>
      _servicesMap[widget.serviceType] ?? _servicesMap['psychic']!;

  @override
  void initState() {
    super.initState();
    _loadMatchingAdvisors();
  }

  Future<void> _loadMatchingAdvisors() async {
    setState(() => _isLoadingAdvisors = true);
    try {
      final homeProv = Provider.of<HomeProvider>(context, listen: false);
      final kw = _info.categoryKeyword.toLowerCase();
      final matchedCat = homeProv.categories.where(
        (c) => c.name.toLowerCase().contains(kw),
      );
      final categoryId = matchedCat.isNotEmpty ? matchedCat.first.id : null;

      var advisors = await _advisorService.getHomeAdvisors(categoryId: categoryId);
      if (advisors.isEmpty && categoryId != null) {
        advisors = await _advisorService.getHomeAdvisors();
      }
      if (mounted) {
        setState(() {
          _matchingAdvisors = advisors;
          _isLoadingAdvisors = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAdvisors = false);
    }
  }

  void _browseAdvisorsOnHome() {
    final homeProv = Provider.of<HomeProvider>(context, listen: false);
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final kw = _info.categoryKeyword.toLowerCase();
    final matchedCat = homeProv.categories.where(
      (c) => c.name.toLowerCase().contains(kw),
    );
    if (matchedCat.isNotEmpty) {
      homeProv.selectCategory(matchedCat.first.id);
    } else {
      homeProv.selectCategory(null);
      homeProv.searchAdvisors(kw);
    }
    nav.setTab(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 0,
        title: Text(
          info.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(info.icon, color: AppColors.accentGold, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              info.subtitle,
                              style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    info.description,
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Key Highlights",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...info.highlights.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(h, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF369A23),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text(
                        "BROWSE ADVISORS",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                      onPressed: _browseAdvisorsOnHome,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // What You Can Expect
            _buildBulletSection(
              title: "What You Can Expect",
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.accentGold,
              items: info.whatToExpect,
            ),

            const SizedBox(height: 14),

            // Why Choose
            _buildBulletSection(
              title: "Why Choose ${info.title}",
              icon: Icons.verified_rounded,
              iconColor: AppColors.onlineGreen,
              items: info.whyChoose,
            ),

            const SizedBox(height: 22),

            // Recommended Advisors for this Service
            const Text(
              "Recommended Advisors",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildAdvisorsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  Expanded(
                    child: Text(item, style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.35)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorsSection() {
    if (_isLoadingAdvisors) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
      );
    }

    if (_matchingAdvisors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgDarkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: const Text(
          "No advisors currently listed for this specialty.",
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
        ),
      );
    }

    return Column(
      children: _matchingAdvisors.take(6).map((adv) {
        final photoUrl = adv.profilePhoto != null && adv.profilePhoto!.isNotEmpty
            ? ApiEndpoints.resolveImageUrl(adv.profilePhoto!)
            : '';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.bgDarkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.bgDarkCardElevated,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      adv.name.isNotEmpty ? adv.name[0].toUpperCase() : 'A',
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 18),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    adv.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.circle,
                  size: 9,
                  color: adv.isOnline ? AppColors.onlineGreen : Colors.grey,
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  (adv.specialities != null && adv.specialities!.isNotEmpty)
                      ? adv.specialities!
                      : ((adv.categoryName != null && adv.categoryName!.isNotEmpty)
                          ? adv.categoryName!
                          : _info.title),
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  "\$${adv.fee.toStringAsFixed(2)}/min • ★ ${adv.rating.toStringAsFixed(1)}",
                  style: const TextStyle(color: AppColors.accentGold, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Connect", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdvisorDetailScreen(advisor: adv)),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdvisorDetailScreen(advisor: adv)),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
