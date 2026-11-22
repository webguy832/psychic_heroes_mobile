import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/text_reading_model.dart';
import '../../services/text_reading_service.dart';
import 'advisor_text_reading_reply_screen.dart';

class AdvisorTextReadingsScreen extends StatefulWidget {
  const AdvisorTextReadingsScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorTextReadingsScreen> createState() => _AdvisorTextReadingsScreenState();
}

class _AdvisorTextReadingsScreenState extends State<AdvisorTextReadingsScreen> {
  final _service = TextReadingService();

  int _selectedTab = 0; // 0 = Pending, 1 = All
  int _pageNumber = 1;
  final int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 1;

  bool _isLoading = true;
  List<TextReadingModel> _readings = [];

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() => _isLoading = true);
    try {
      final res = _selectedTab == 0
          ? await _service.getPendingAdvisorTextReadings(pageNumber: _pageNumber, pageSize: _pageSize)
          : await _service.getAdvisorTextReadings(pageNumber: _pageNumber, pageSize: _pageSize);

      if (mounted) {
        setState(() {
          _readings = (res['data'] as List<TextReadingModel>?) ?? [];
          _totalCount = res['totalCount'] ?? _readings.length;
          _totalPages = res['totalPages'] ?? ((_totalCount / _pageSize).ceil() == 0 ? 1 : (_totalCount / _pageSize).ceil());
        });
      }
    } catch (e) {
      debugPrint("Error fetching advisor text readings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTabChanged(int index) {
    if (_selectedTab != index) {
      setState(() {
        _selectedTab = index;
        _pageNumber = 1;
      });
      _loadReadings();
    }
  }

  void _onPrevPage() {
    if (_pageNumber > 1) {
      setState(() => _pageNumber--);
      _loadReadings();
    }
  }

  void _onNextPage() {
    if (_pageNumber < _totalPages) {
      setState(() => _pageNumber++);
      _loadReadings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Text Reading Requests",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs (Pending vs All)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgDarkCard,
              border: Border(bottom: BorderSide(color: AppColors.borderDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab(
                    title: "Pending Requests",
                    index: 0,
                    icon: Icons.hourglass_top_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterTab(
                    title: "All Readings",
                    index: 1,
                    icon: Icons.auto_stories_rounded,
                  ),
                ),
              ],
            ),
          ),

          // Content List with RefreshIndicator
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold)))
                : _readings.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadReadings,
                        color: AppColors.accentGold,
                        backgroundColor: AppColors.bgDarkCard,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.mail_outline_rounded, size: 54, color: AppColors.textSecondaryDark.withOpacity(0.5)),
                                  const SizedBox(height: 14),
                                  Text(
                                    _selectedTab == 0 ? "No Pending Text Readings" : "No Text Readings Found",
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    "When customers submit text readings, they will appear here.",
                                    style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReadings,
                        color: AppColors.accentGold,
                        backgroundColor: AppColors.bgDarkCard,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _readings.length,
                          itemBuilder: (context, index) {
                            final reading = _readings[index];
                            return _buildReadingCard(reading);
                          },
                        ),
                      ),
          ),

          // Pagination Bottom Bar (Exact Web App Parity)
          if (_totalPages > 1 || _readings.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.bgDarkCard,
                border: Border(top: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _pageNumber > 1 ? _onPrevPage : null,
                    child: Text(
                      "PREV",
                      style: TextStyle(
                        color: _pageNumber > 1 ? Colors.white : AppColors.textSecondaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF369A23), Color(0xFF2E5626)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$_pageNumber / $_totalPages",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _pageNumber < _totalPages ? _onNextPage : null,
                    child: Text(
                      "NEXT",
                      style: TextStyle(
                        color: _pageNumber < _totalPages ? Colors.white : AppColors.textSecondaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({required String title, required int index, required IconData icon}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => _onTabChanged(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGold.withOpacity(0.15) : AppColors.bgDarkCardElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : AppColors.borderDark,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.accentGold : AppColors.textSecondaryDark),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.accentGold : AppColors.textPrimaryDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingCard(TextReadingModel reading) {
    final hasQuestion = reading.specQuestion != null && reading.specQuestion!.trim().isNotEmpty;
    final questionText = hasQuestion ? reading.specQuestion! : reading.generalDescription;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Client Name, Date & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.bgDarkCardElevated,
                    child: Text(
                      reading.customerName.isNotEmpty ? reading.customerName[0].toUpperCase() : 'C',
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    reading.customerName.isNotEmpty ? reading.customerName : "Customer",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: reading.isCompleted
                      ? AppColors.onlineGreen.withOpacity(0.15)
                      : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: reading.isCompleted
                        ? AppColors.onlineGreen.withOpacity(0.4)
                        : Colors.amber.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  reading.isCompleted ? "COMPLETED" : (reading.readingType ? "FAST TRACK" : "PENDING"),
                  style: TextStyle(
                    color: reading.isCompleted ? AppColors.onlineGreen : Colors.amber,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Question Snippet
          Text(
            questionText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 12),

          // Price & Date & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "\$${reading.price.toStringAsFixed(2)}",
                    style: const TextStyle(color: AppColors.onlineGreen, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (reading.createdOn != null)
                    Text(
                      DateFormat('dd/MM/yyyy, h:mm a').format(reading.createdOn!),
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10),
                    ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: reading.isCompleted ? AppColors.bgDarkCardElevated : const Color(0xFFB45309), // Amber-700
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: Icon(
                  reading.isCompleted ? Icons.visibility_rounded : Icons.edit_note_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  reading.isCompleted ? "View Reading" : "Review & Reply",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdvisorTextReadingReplyScreen(requestId: reading.id),
                    ),
                  ).then((_) => _loadReadings());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
