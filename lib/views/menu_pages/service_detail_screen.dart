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
  final String description;
  final String assetImage;
  final String categoryKeyword;
  final List<String> highlights;
  final List<String> whatToExpect;
  final List<String> whyChoose;

  const ServiceDetailInfo({
    required this.title,
    required this.description,
    required this.assetImage,
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
      description:
          'General life guidance, intuitive insight, clarity. Our gifted psychics provide direct answers to your most pressing questions about life, love, career, and spiritual growth. Get personalized intuitive guidance to help you navigate challenges, make important decisions, and find your true path with confidence and clarity.',
      assetImage: 'assets/images/servicess/psychic-reading.jpg',
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
      description:
          'Reveal answers through intuitive tarot readings that guide your life decisions. Our skilled tarot readers use ancient wisdom combined with modern intuition to provide you with accurate, personalized insights. Whether you\'re seeking guidance on love, career, or spiritual matters, our experts can help you find clarity through the cards.',
      assetImage: 'assets/images/servicess/Tarot-Reading.jpg',
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
      description:
          'Find clarity on love, compatibility, soulmates, and relationship decisions. Our experienced advisors provide compassionate guidance to help you navigate the complexities of romantic relationships, whether you\'re seeking your soulmate, working through challenges in your current partnership, or healing from past heartbreak.',
      assetImage: 'assets/images/servicess/Love-&-Relationships.jpg',
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
      title: 'Career & Money',
      description:
          'Get guidance on career paths, promotions, and financial stability. Our expert advisors help you navigate professional challenges, identify lucrative opportunities, and make strategic decisions about your financial future. Whether you\'re considering a career change, seeking advancement, or looking for investment guidance, our readers provide the insights you need.',
      assetImage: 'assets/images/servicess/Career-&-Money.jpg',
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
      title: 'Spiritual Healing & Energy Work',
      description:
          'Aura reading, chakra balancing, spiritual wellness. Our spiritual healers help you cleanse negative energy, balance your chakras, and restore your natural spiritual vitality. Experience deep relaxation, emotional release, and spiritual renewal through various healing modalities and energy work techniques.',
      assetImage: 'assets/images/servicess/spiritual-healing.jpg',
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
      title: 'Dream & Numerology Readings',
      description:
          'Symbol interpretation and life pattern analysis. Our dream interpreters and numerology experts help you understand the hidden meanings in your dreams and decode the numerical patterns that shape your destiny. Get insights into your life path, soul purpose, and future opportunities through the wisdom of dreams and sacred numbers.',
      assetImage: 'assets/images/servicess/dream.png',
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
            // Hero Image matching web app
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  info.assetImage,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 200,
                    color: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 48),
                  ),
                ),
              ),
            ),

            // Carousel Indicator Dots (matching web app)
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF15803D), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Title & Description (Editorial Light Theme)
            Text(
              info.title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              info.description,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 18),

            // Key Highlights
            const Text(
              "Key Highlights:",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 10),
            ...info.highlights.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, color: Color(0xFF16A34A), size: 7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        h,
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // BROWSE ADVISORS Green Gradient Button (Exact Web App Style)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF369A23), Color(0xFF2E5626)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF369A23).withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _browseAdvisorsOnHome,
                child: const Text(
                  "BROWSE ADVISORS",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, letterSpacing: 0.6),
                ),
              ),
            ),

            const SizedBox(height: 26),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 20),

            // What You Can Expect
            _buildInfoCard(
              title: "What You Can Expect:",
              items: info.whatToExpect,
              textColor: const Color(0xFF334155),
            ),

            const SizedBox(height: 16),

            // Why Choose
            _buildInfoCard(
              title: "Why Choose ${info.title}:",
              items: info.whyChoose,
              textColor: const Color(0xFF64748B),
            ),

            const SizedBox(height: 26),

            // Recommended Advisors Section
            const Text(
              "Recommended Advisors",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAdvisorsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<String> items,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, color: Color(0xFF16A34A), size: 7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: textColor, fontSize: 14, height: 1.45),
                    ),
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
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_matchingAdvisors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          "No advisors currently listed for this specialty.",
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
        ),
      );
    }

    return Column(
      children: _matchingAdvisors.take(6).map((adv) {
        final photoUrl = adv.profilePhoto != null && adv.profilePhoto!.isNotEmpty
            ? ApiEndpoints.resolveImageUrl(adv.profilePhoto!)
            : '';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFF3E8FF),
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          adv.name.isNotEmpty ? adv.name[0].toUpperCase() : 'A',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: adv.isOnline ? const Color(0xFF22C55E) : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              adv.name,
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
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
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                    const SizedBox(width: 3),
                    Text(
                      "${adv.rating.toStringAsFixed(1)} (${adv.reviewsCount})",
                      style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "\$${adv.fee.toStringAsFixed(2)}/min",
                      style: const TextStyle(color: Color(0xFF16A34A), fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A358),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
