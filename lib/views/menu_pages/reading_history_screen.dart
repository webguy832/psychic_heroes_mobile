import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../advisors/session_after_summary_screen.dart';
import '../shared/app_footer_widget.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  String _selectedCategory = "all";
  String _searchQuery = "";

  final List<Map<String, dynamic>> _mockReadings = [
    {
      'id': 'REQ-99218',
      'title': 'Love & Relationship Psychic Reading',
      'advisorName': 'Psychic Serena',
      'type': 'Live Chat',
      'typeKey': 'chat',
      'duration': '14 mins',
      'date': 'Sept 26, 2026 • 09:15 PM',
      'cost': 27.93,
      'rating': 5,
      'summary': 'Deep insight into soulmate connections, upcoming romantic milestones, and heart chakra alignment.',
      'icon': Icons.chat_bubble_rounded,
      'color': AppColors.accentGold,
    },
    {
      'id': 'REQ-98102',
      'title': 'Career & Destiny Guidance Call',
      'advisorName': 'Master Orion',
      'type': 'Voice Call',
      'typeKey': 'voice',
      'duration': '10 mins',
      'date': 'Sept 22, 2026 • 04:30 PM',
      'cost': 39.90,
      'rating': 5,
      'summary': 'Comprehensive astrology transit analysis covering job promotion, financials, and major decisions.',
      'icon': Icons.phone_in_talk_rounded,
      'color': AppColors.onlineGreen,
    },
    {
      'id': 'REQ-97551',
      'title': 'Tarot 3-Card Spread Video Reading',
      'advisorName': 'Tarot Empress Elena',
      'type': 'Video Call',
      'typeKey': 'video',
      'duration': '18 mins',
      'date': 'Sept 18, 2026 • 11:00 AM',
      'cost': 71.82,
      'rating': 5,
      'summary': 'The Empress, The Sun, and Wheel of Fortune cards revealed powerful positive shifts in spiritual energy.',
      'icon': Icons.videocam_rounded,
      'color': AppColors.accentCyan,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _mockReadings.where((r) {
      final matchesCategory = _selectedCategory == "all" || r['typeKey'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          r['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r['advisorName'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 1,
        title: const Text("Reading & Session History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: AppStyles.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search_rounded, color: AppColors.textSecondaryDark),
                        hintText: "Search by advisor or session topic...",
                        hintStyle: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("all", "All Sessions"),
                        const SizedBox(width: 8),
                        _buildFilterChip("chat", "Live Chat"),
                        const SizedBox(width: 8),
                        _buildFilterChip("voice", "Voice Calls"),
                        const SizedBox(width: 8),
                        _buildFilterChip("video", "Video Calls"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // History Readings List
                  filtered.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: AppColors.bgDarkCard, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: const [
                              Icon(Icons.auto_stories_rounded, color: AppColors.textSecondaryDark, size: 48),
                              SizedBox(height: 12),
                              Text("No Reading History Found", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text("Completed sessions and transcripts will appear here.", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final item = filtered[i];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.bgDarkCard,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.borderDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: (item['color'] as Color).withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                            const SizedBox(height: 2),
                                            Text("Advisor: ${item['advisorName']}", style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Text("\$${(item['cost'] as double).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onlineGreen)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(item['summary'] as String, style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12, height: 1.3)),
                                  const SizedBox(height: 12),
                                  const Divider(color: AppColors.borderDark, height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, color: AppColors.textSecondaryDark, size: 14),
                                          const SizedBox(width: 4),
                                          Text("${item['duration']} • ${item['date']}", style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryLight,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                        label: const Text("View Summary", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SessionAfterSummaryScreen(
                                                isAdvisorView: false,
                                                participantName: item['advisorName'] as String,
                                                formattedTime: item['duration'] as String,
                                                totalCost: item['cost'] as double,
                                                sessionTypeLabel: item['type'] as String,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.accentGold,
      backgroundColor: AppColors.bgDarkCard,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedCategory = value),
    );
  }
}

