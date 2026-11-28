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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFF3E8FF), shape: BoxShape.circle),
              child: Text(z['symbol']!, style: const TextStyle(fontSize: 48, color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
            Text("${z['name']} (${z['dates']})", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
              child: Text("Element: ${z['element']}", style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(
              z['horoscope']!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.5),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF369A23), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)),
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
        Text(score, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.accentGold.withOpacity(0.2), shape: BoxShape.circle),
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
                              Text("Hope, inspiration, and renewed faith fill your path today.", style: TextStyle(color: Colors.white70, fontSize: 11.5)),
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
                      const Text("Zodiac Horoscopes", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Row(
                        children: [
                          ChoiceChip(
                            selected: _selectedPeriod == "daily",
                            label: const Text("Daily"),
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: _selectedPeriod == "daily" ? AppColors.primary : const Color(0xFFE2E8F0)),
                            labelStyle: TextStyle(color: _selectedPeriod == "daily" ? Colors.white : const Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold),
                            onSelected: (_) => setState(() => _selectedPeriod = "daily"),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            selected: _selectedPeriod == "weekly",
                            label: const Text("Weekly"),
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: _selectedPeriod == "weekly" ? AppColors.primary : const Color(0xFFE2E8F0)),
                            labelStyle: TextStyle(color: _selectedPeriod == "weekly" ? Colors.white : const Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(z['symbol']!, style: const TextStyle(fontSize: 32, color: AppColors.primary)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(z['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text(z['dates']!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5)),
                                    const SizedBox(height: 4),
                                    const Text("Tap for reading >", style: TextStyle(color: Color(0xFF4F46E5), fontSize: 9.5, fontWeight: FontWeight.bold)),
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

