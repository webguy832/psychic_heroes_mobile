import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/home_provider.dart';
import '../../providers/navigation_provider.dart';

class ZodiacSignInfo {
  final String name;
  final String symbol;
  final String dateRange;
  final String daily;
  final String weekly;
  final String monthly;

  const ZodiacSignInfo({
    required this.name,
    required this.symbol,
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
      dateRange: 'Mar 21 - Apr 19',
      daily: 'Today brings new opportunities for personal growth. Trust your intuition when making bold decisions.',
      weekly: 'This week focuses on communication and self-expression. A meaningful conversation opens new doors.',
      monthly: 'This month emphasizes transformation and new beginnings across career and personal relationships.',
    ),
    ZodiacSignInfo(
      name: 'Taurus',
      symbol: '♉',
      dateRange: 'Apr 20 - May 20',
      daily: 'Stability is your keyword today. Stay grounded and take steady steps toward your goals.',
      weekly: 'This week supports material security and thoughtful financial planning.',
      monthly: 'Focus on values, possessions, and nurturing long-term commitments.',
    ),
    ZodiacSignInfo(
      name: 'Gemini',
      symbol: '♊',
      dateRange: 'May 21 - Jun 20',
      daily: 'Your curiosity sparks inspiring connections today. Stay open to unexpected messages.',
      weekly: 'Social energy is high this week; collaborate with people who share your vision.',
      monthly: 'A dynamic month for learning, travel, and expanding your creative horizons.',
    ),
    ZodiacSignInfo(
      name: 'Cancer',
      symbol: '♋',
      dateRange: 'Jun 21 - Jul 22',
      daily: 'Listen to your heart today. Emotional clarity helps you resolve lingering doubts.',
      weekly: 'Home and family take center stage, bringing warmth and comforting reassurance.',
      monthly: 'Deep emotional renewal prepares you for an exciting personal milestone.',
    ),
    ZodiacSignInfo(
      name: 'Leo',
      symbol: '♌',
      dateRange: 'Jul 23 - Aug 22',
      daily: 'Your natural confidence shines bright today. Step forward and share your talents.',
      weekly: 'Creative projects gain momentum and attract positive recognition.',
      monthly: 'Romance, passion, and self-expression flourish throughout the month.',
    ),
    ZodiacSignInfo(
      name: 'Virgo',
      symbol: '♍',
      dateRange: 'Aug 23 - Sep 22',
      daily: 'Attention to detail brings a satisfying breakthrough in your daily routine.',
      weekly: 'Organizing your priorities frees up energy for meaningful personal growth.',
      monthly: 'A productive month for wellness, career refinement, and practical progress.',
    ),
    ZodiacSignInfo(
      name: 'Libra',
      symbol: '♎',
      dateRange: 'Sep 23 - Oct 22',
      daily: 'Harmony and balance guide your interactions today. Seek fair compromises.',
      weekly: 'Partnerships deepen through honest dialogue and mutual appreciation.',
      monthly: 'Relationships and creative collaborations bring lasting joy this month.',
    ),
    ZodiacSignInfo(
      name: 'Scorpio',
      symbol: '♏',
      dateRange: 'Oct 23 - Nov 21',
      daily: 'Your intuition is razor-sharp today. Look beneath the surface for hidden truths.',
      weekly: 'A week of empowerment where releasing old habits clears space for growth.',
      monthly: 'Transformation and emotional depth lead to a powerful new chapter.',
    ),
    ZodiacSignInfo(
      name: 'Sagittarius',
      symbol: '♐',
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 0,
        title: const Text(
          "Astrology & Horoscopes",
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
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Get personalized cosmic guidance for your zodiac sign",
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Horizontal Zodiac Sign Selector
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _signs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, index) {
                  final sign = _signs[index];
                  final isSelected = index == _selectedSignIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSignIndex = index),
                    child: Container(
                      width: 108,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.bgDarkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.accentGold : AppColors.borderDark,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sign.symbol,
                            style: TextStyle(
                              fontSize: 28,
                              color: isSelected ? AppColors.accentGold : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sign.name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
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
                            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 9.5),
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

            const SizedBox(height: 20),

            // Selected Sign Horoscope Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        selected.symbol,
                        style: const TextStyle(fontSize: 30, color: AppColors.accentGold),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            selected.dateRange,
                            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Daily / Weekly / Monthly Tabs
                  Row(
                    children: List.generate(tabTitles.length, (i) {
                      final active = _selectedTabIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(tabTitles[i]),
                          selected: active,
                          selectedColor: AppColors.accentGold,
                          backgroundColor: AppColors.bgDark,
                          labelStyle: TextStyle(
                            color: active ? Colors.black : AppColors.textPrimaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                          onSelected: (_) => setState(() => _selectedTabIndex = i),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "${tabTitles[_selectedTabIndex]} Forecast for ${selected.name}",
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CTA to connect with an Astrology Advisor
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.35)),
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
                    style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
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
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text(
                        "BROWSE ASTROLOGY ADVISORS",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _browseAstrologyAdvisors,
                    ),
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
