import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../advisors/session_after_summary_screen.dart';
import '../shared/app_footer_widget.dart';
import '../shared/loading_indicator.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  String _selectedCategory = "all";
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchReadingHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final readings = userProv.readingHistory;
    final isAdvisor = userProv.isAdvisor;

    final filtered = readings.where((r) {
      final matchesCategory = _selectedCategory == "all" || r.typeKey.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.advisorName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isAdvisor ? "Client Reading & Session History" : "Reading & Session History",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh History",
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => userProv.fetchReadingHistory(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => userProv.fetchReadingHistory(),
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          icon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                          hintText: isAdvisor
                              ? "Search by client name or session topic..."
                              : "Search by advisor or session topic...",
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
                          const SizedBox(width: 8),
                          _buildFilterChip("text", "Text Readings"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // History Readings List
                    userProv.isLoading && readings.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: LoadingIndicator(message: "Loading session history..."),
                            ),
                          )
                        : filtered.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.auto_stories_rounded, color: Color(0xFF94A3B8), size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                      isAdvisor ? "No Client Sessions Found" : "No Reading History Found",
                                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isAdvisor
                                          ? "Completed client sessions and readings will appear here."
                                          : "Completed sessions and transcripts will appear here.",
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                itemBuilder: (ctx, i) {
                                  final item = filtered[i];
                                  final isVideo = item.typeKey.toLowerCase() == 'video';
                                  final isVoice = item.typeKey.toLowerCase() == 'voice';
                                  final itemColor = isVideo ? const Color(0xFF4F46E5) : (isVoice ? const Color(0xFF16A34A) : AppColors.primary);
                                  final itemIcon = isVideo ? Icons.videocam_rounded : (isVoice ? Icons.phone_in_talk_rounded : Icons.chat_bubble_rounded);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: itemColor.withOpacity(0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(itemIcon, color: itemColor, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "${isAdvisor ? 'Client' : 'Advisor'}: ${item.advisorName}",
                                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              "\$${item.cost.toStringAsFixed(2)}",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(item.summary, style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5, height: 1.4)),
                                        const SizedBox(height: 12),
                                        const Divider(color: Color(0xFFE2E8F0), height: 1),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 14),
                                                const SizedBox(width: 4),
                                                Text("${item.duration} • ${item.date}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                                              ],
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
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
                                                      isAdvisorView: isAdvisor,
                                                      participantName: item.advisorName,
                                                      formattedTime: item.duration,
                                                      totalCost: item.cost,
                                                      sessionTypeLabel: item.type,
                                                      isLiveSessionEnd: false,
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
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedCategory = value),
    );
  }
}

