import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/home_provider.dart';
import '../../providers/navigation_provider.dart';

class ZodiacSignInfo {
  final String name;
  final String symbol;
  final String? assetImage;
  final String dateRange;
  final String daily;
  final String weekly;
  final String monthly;

  const ZodiacSignInfo({
    required this.name,
    required this.symbol,
    this.assetImage,
    required this.dateRange,
    required this.daily,
    required this.weekly,
    required this.monthly,
  });
}

class HoroscopesScreen extends StatefulWidget {
  const HoroscopesScreen({Key? key}) : super(key: key);

  @override
  State<HoroscopesScreen> createState() => _HoroscopesScreenState();
}

class _HoroscopesScreenState extends State<HoroscopesScreen> {
  int _selectedSignIndex = 0;
  int _selectedTabIndex = 0; // 0 = Daily, 1 = Weekly, 2 = Monthly

  static const List<ZodiacSignInfo> _signs = [
    ZodiacSignInfo(
      name: 'Aries',
      symbol: '♈',
      assetImage: 'assets/images/zodiac/aries.png',
      dateRange: 'Mar 21 - Apr 19',
      daily: 'Today brings new opportunities for personal growth. Trust your intuition when making bold decisions.',
      weekly: 'This week focuses on communication and self-expression. A meaningful conversation opens new doors.',
      monthly: 'This month emphasizes transformation and new beginnings across career and personal relationships.',
    ),
    ZodiacSignInfo(
      name: 'Taurus',
      symbol: '♉',
      assetImage: 'assets/images/zodiac/taurus.png',
      dateRange: 'Apr 20 - May 20',
      daily: 'Stability is your keyword today. Stay grounded and take steady steps toward your goals.',
      weekly: 'This week supports material security and thoughtful financial planning.',
      monthly: 'Focus on values, possessions, and nurturing long-term commitments.',
    ),
    ZodiacSignInfo(
      name: 'Gemini',
      symbol: '♊',
      assetImage: 'assets/images/zodiac/gemini.png',
      dateRange: 'May 21 - Jun 20',
      daily: 'Your curiosity sparks inspiring connections today. Stay open to unexpected messages.',
      weekly: 'Social energy is high this week; collaborate with people who share your vision.',
      monthly: 'A dynamic month for learning, travel, and expanding your creative horizons.',
    ),
    ZodiacSignInfo(
      name: 'Cancer',
      symbol: '♋',
      assetImage: 'assets/images/zodiac/cancer.png',
      dateRange: 'Jun 21 - Jul 22',
      daily: 'Listen to your heart today. Emotional clarity helps you resolve lingering doubts.',
      weekly: 'Home and family take center stage, bringing warmth and comforting reassurance.',
      monthly: 'Deep emotional renewal prepares you for an exciting personal milestone.',
    ),
    ZodiacSignInfo(
      name: 'Leo',
      symbol: '♌',
      assetImage: 'assets/images/zodiac/leo.png',
      dateRange: 'Jul 23 - Aug 22',
      daily: 'Your natural confidence shines bright today. Step forward and share your talents.',
      weekly: 'Creative projects gain momentum and attract positive recognition.',
      monthly: 'Romance, passion, and self-expression flourish throughout the month.',
    ),
    ZodiacSignInfo(
      name: 'Virgo',
      symbol: '♍',
      assetImage: 'assets/images/zodiac/virgo.png',
      dateRange: 'Aug 23 - Sep 22',
      daily: 'Attention to detail brings a satisfying breakthrough in your daily routine.',
      weekly: 'Organizing your priorities frees up energy for meaningful personal growth.',
      monthly: 'A productive month for wellness, career refinement, and practical progress.',
    ),
    ZodiacSignInfo(
      name: 'Libra',
      symbol: '♎',
      assetImage: 'assets/images/zodiac/libra.png',
      dateRange: 'Sep 23 - Oct 22',
      daily: 'Harmony and balance guide your interactions today. Seek fair compromises.',
      weekly: 'Partnerships deepen through honest dialogue and mutual appreciation.',
      monthly: 'Relationships and creative collaborations bring lasting joy this month.',
    ),
    ZodiacSignInfo(
      name: 'Scorpio',
      symbol: '♏',
      assetImage: 'assets/images/zodiac/scorpio.png',
      dateRange: 'Oct 23 - Nov 21',
      daily: 'Your intuition is razor-sharp today. Look beneath the surface for hidden truths.',
      weekly: 'A week of empowerment where releasing old habits clears space for growth.',
      monthly: 'Transformation and emotional depth lead to a powerful new chapter.',
    ),
    ZodiacSignInfo(
      name: 'Sagittarius',
      symbol: '♐',
      assetImage: 'assets/images/zodiac/sagitarius.png',
      dateRange: 'Nov 22 - Dec 21',
      daily: 'Optimism and adventure call to you today. Embrace fresh perspectives.',
      weekly: 'Opportunities to explore new ideas or travel bring welcome excitement.',
      monthly: 'Expansion, wisdom, and personal freedom define your path ahead.',
    ),
    ZodiacSignInfo(
      name: 'Capricorn',
      symbol: '♑',
      dateRange: 'Dec 22 - Jan 19',
      daily: 'Disciplined effort pays off today. Stay focused on your long-term vision.',
      weekly: 'Leadership and steady determination earn respect from those around you.',
      monthly: 'Career milestones and solid achievements mark this rewarding month.',
    ),
    ZodiacSignInfo(
      name: 'Aquarius',
      symbol: '♒',
      dateRange: 'Jan 20 - Feb 18',
      daily: 'Innovative ideas flow freely today. Share your unique perspective with others.',
      weekly: 'Community and friendships bring inspiring collaborations your way.',
      monthly: 'Forward-thinking breakthroughs reshape your goals in exciting ways.',
    ),
    ZodiacSignInfo(
      name: 'Pisces',
      symbol: '♓',
      assetImage: 'assets/images/zodiac/pisces.png',
      dateRange: 'Feb 19 - Mar 20',
      daily: 'Spiritual sensitivity is heightened today. Pay attention to dreams and subtle signs.',
      weekly: 'Gentle reflection and creative flow restore your inner peace.',
      monthly: 'Compassion and intuition guide you toward soulful fulfillment.',
    ),
  ];

  void _browseAstrologyAdvisors() {
    final homeProv = Provider.of<HomeProvider>(context, listen: false);
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final matchedCat = homeProv.categories.where(
      (c) => c.name.toLowerCase().contains('astrolog') || c.name.toLowerCase().contains('horoscope'),
    );
    if (matchedCat.isNotEmpty) {
      homeProv.selectCategory(matchedCat.first.id);
    } else {
      homeProv.selectCategory(null);
      homeProv.searchAdvisors('astrology');
    }
    nav.setTab(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _signs[_selectedSignIndex];
    final tabTitles = ['Daily', 'Weekly', 'Monthly'];
    final content = _selectedTabIndex == 0
        ? selected.daily
        : (_selectedTabIndex == 1 ? selected.weekly : selected.monthly);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Astrology & Horoscope",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Horoscopes",
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Get personalized guidance for Daily Horoscopes 2026",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
            ),
            const SizedBox(height: 18),

            // Horizontal Zodiac Sign Selector (matching web app cards)
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _signs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, index) {
                  final sign = _signs[index];
                  final isSelected = index == _selectedSignIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSignIndex = index),
                    child: Container(
                      width: 112,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.8 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (sign.assetImage != null)
                            Image.asset(
                              sign.assetImage!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Text(
                                sign.symbol,
                                style: const TextStyle(fontSize: 32, color: AppColors.primary),
                              ),
                            )
                          else
                            Text(
                              sign.symbol,
                              style: const TextStyle(fontSize: 32, color: AppColors.primary),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            sign.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF312E81) : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sign.dateRange,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Selected Sign Header + Tabs (matching web app underline tabs)
            Text(
              selected.name.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: List.generate(tabTitles.length, (i) {
                  final active = _selectedTabIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = i),
                    child: Container(
                      padding: const EdgeInsets.only(right: 24, bottom: 10, top: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: active ? const Color(0xFF4F46E5) : Colors.transparent,
                            width: 2.2,
                          ),
                        ),
                      ),
                      child: Text(
                        tabTitles[i],
                        style: TextStyle(
                          color: active ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                          fontWeight: active ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 18),

            // Forecast Content Card
            Container(
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
                    "Horoscope for ${tabTitles[_selectedTabIndex].toLowerCase()} — ${selected.name}",
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // CTA Banner matching Psychic Heroes purple & green
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Want a Personalized Birth Chart Reading?",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Connect live with experienced astrologers for synastry, transits, and cosmic timing insights.",
                    style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF369A23),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text(
                      "BROWSE ASTROLOGY ADVISORS",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _browseAstrologyAdvisors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
