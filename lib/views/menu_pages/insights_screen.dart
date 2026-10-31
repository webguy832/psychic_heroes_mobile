import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../shared/app_footer_widget.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedPeriod = "daily";

  final List<Map<String, String>> _zodiacs = const [
    {'name': 'Aries', 'dates': 'Mar 21 - Apr 19', 'symbol': '♈', 'element': 'Fire', 'horoscope': 'Today brings dynamic energy and bold breakthroughs in your career path. Trust your inner instinct!'},
    {'name': 'Taurus', 'dates': 'Apr 20 - May 20', 'symbol': '♉', 'element': 'Earth', 'horoscope': 'Financial stability and peace surround you today. A heart-to-heart conversation strengthens bonds.'},
    {'name': 'Gemini', 'dates': 'May 21 - Jun 20', 'symbol': '♊', 'element': 'Air', 'horoscope': 'Your communication skills are at an all-time peak. Clear expression opens new spiritual doors.'},
    {'name': 'Cancer', 'dates': 'Jun 21 - Jul 22', 'symbol': '♋', 'element': 'Water', 'horoscope': 'Deep emotional healing and warmth surround your aura today. Focus on self-care and meditation.'},
    {'name': 'Leo', 'dates': 'Jul 23 - Aug 22', 'symbol': '♌', 'element': 'Fire', 'horoscope': 'Your natural charisma shines bright today. Leadership opportunities will manifest seamlessly.'},
    {'name': 'Virgo', 'dates': 'Aug 23 - Sep 22', 'symbol': '♍', 'element': 'Earth', 'horoscope': 'Precision and clarity allow you to solve long-standing puzzles. Clarity fills your spirit.'},
    {'name': 'Libra', 'dates': 'Sep 23 - Oct 22', 'symbol': '♎', 'element': 'Air', 'horoscope': 'Balance, harmony, and graceful partnerships are highlighted. A positive aura surrounds your connections.'},
    {'name': 'Scorpio', 'dates': 'Oct 23 - Nov 21', 'symbol': '♏', 'element': 'Water', 'horoscope': 'Transformative insights illuminate secret truths. Embrace your deep intuitive psychic powers.'},
    {'name': 'Sagittarius', 'dates': 'Nov 22 - Dec 21', 'symbol': '♐', 'element': 'Fire', 'horoscope': 'An exciting spiritual journey or new perspective awaits. Optimism attracts great fortune.'},
    {'name': 'Capricorn', 'dates': 'Dec 22 - Jan 19', 'symbol': '♑', 'element': 'Earth', 'horoscope': 'Long-term dedication pays off today. Your ambition aligns with divine cosmic timing.'},
    {'name': 'Aquarius', 'dates': 'Jan 20 - Feb 18', 'symbol': '♒', 'element': 'Air', 'horoscope': 'Innovative ideas and visionary dreams guide your path today. Express your uniqueness.'},
    {'name': 'Pisces', 'dates': 'Feb 19 - Mar 20', 'symbol': '♓', 'element': 'Water', 'horoscope': 'Vivid dreams and heightened empathy reveal key answers. Trust the universe guiding you.'},
  ];

  void _showHoroscopeModal(Map<String, String> z) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDarkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.accentGold.withOpacity(0.15), shape: BoxShape.circle),
              child: Text(z['symbol']!, style: const TextStyle(fontSize: 48, color: AppColors.accentGold)),
            ),
            const SizedBox(height: 12),
            Text("${z['name']} (${z['dates']})", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Text("Element: ${z['element']}", style: const TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(
              z['horoscope']!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRatingMini("Love", "98%"),
                _buildRatingMini("Career", "92%"),
                _buildRatingMini("Luck", "95%"),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 44)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close Horoscope", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingMini(String label, String score) {
    return Column(
      children: [
        Text(score, style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 1,
        title: const Text("Astrology & Daily Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppStyles.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarot Card of the Day Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderGold.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(color: AppColors.accentGold.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.3), shape: BoxShape.circle),
                          child: const Icon(Icons.style_rounded, color: AppColors.accentGold, size: 36),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Tarot Card of the Day", style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
                              SizedBox(height: 2),
                              Text("The Star ⭐ (Major Arcana)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text("Hope, inspiration, and renewed faith fill your path today.", style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Zodiac Horoscopes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Row(
                        children: [
                          ChoiceChip(
                            selected: _selectedPeriod == "daily",
                            label: const Text("Daily"),
                            selectedColor: AppColors.accentGold,
                            backgroundColor: AppColors.bgDarkCard,
                            labelStyle: TextStyle(color: _selectedPeriod == "daily" ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            onSelected: (_) => setState(() => _selectedPeriod = "daily"),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            selected: _selectedPeriod == "weekly",
                            label: const Text("Weekly"),
                            selectedColor: AppColors.accentGold,
                            backgroundColor: AppColors.bgDarkCard,
                            labelStyle: TextStyle(color: _selectedPeriod == "weekly" ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            onSelected: (_) => setState(() => _selectedPeriod = "weekly"),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.45,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _zodiacs.length,
                    itemBuilder: (ctx, i) {
                      final z = _zodiacs[i];
                      return GestureDetector(
                        onTap: () => _showHoroscopeModal(z),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgDarkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Row(
                            children: [
                              Text(z['symbol']!, style: const TextStyle(fontSize: 32, color: AppColors.accentGold)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(z['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text(z['dates']!, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 9)),
                                    const SizedBox(height: 4),
                                    const Text("Tap for reading >", style: TextStyle(color: AppColors.accentCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
}

