import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/session_provider.dart';
import '../advisors/live_session_screen.dart';
import '../shared/app_footer_widget.dart';

class AdvisorMessagesScreen extends StatefulWidget {
  const AdvisorMessagesScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorMessagesScreen> createState() => _AdvisorMessagesScreenState();
}

class _AdvisorMessagesScreenState extends State<AdvisorMessagesScreen> {
  String _searchQuery = "";

  final List<Map<String, dynamic>> _mockThreads = [
    {
      'id': 'adv_101',
      'name': 'Psychic Serena',
      'specialty': 'Love & Soulmate Specialist',
      'lastMessage': 'Thank you for our wonderful session! Your energy is glowing...',
      'time': '2m ago',
      'unread': 1,
      'isOnline': true,
      'avatarColor': AppColors.accentPurple,
    },
    {
      'id': 'adv_102',
      'name': 'Master Orion',
      'specialty': 'Vedic Astrology & Tarot Master',
      'lastMessage': 'Your astrology planetary chart analysis has been updated.',
      'time': '1h ago',
      'unread': 0,
      'isOnline': true,
      'avatarColor': AppColors.primary,
    },
    {
      'id': 'adv_103',
      'name': 'Tarot Empress Elena',
      'specialty': 'Tarot & Spiritual Guidance',
      'lastMessage': 'The Star card came up strongly in your spread today.',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
      'avatarColor': Colors.indigo,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final sessionProv = Provider.of<SessionProvider>(context, listen: false);

    final filteredThreads = _mockThreads.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t['specialty'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 1,
        title: const Text("Advisor Chat Messages", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
                        hintText: "Search conversations or advisor name...",
                        hintStyle: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),

                  const SizedBox(height: 18),

                  filteredThreads.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: AppColors.bgDarkCard, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: const [
                              Icon(Icons.forum_rounded, color: AppColors.textSecondaryDark, size: 44),
                              SizedBox(height: 12),
                              Text("No Messages Found", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(height: 4),
                              Text("Start a live chat with an advisor to send messages.", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredThreads.length,
                          itemBuilder: (ctx, i) {
                            final thread = filteredThreads[i];
                            final unread = thread['unread'] as int;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.bgDarkCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: unread > 0 ? AppColors.accentGold.withOpacity(0.5) : AppColors.borderDark),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: thread['avatarColor'] as Color,
                                      child: Text(
                                        (thread['name'] as String)[0],
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ),
                                    if (thread['isOnline'] == true)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.onlineGreen,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.bgDarkCard, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(thread['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                    Text(thread['time'] as String, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(thread['specialty'] as String, style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      thread['lastMessage'] as String,
                                      style: TextStyle(
                                        color: unread > 0 ? Colors.white : AppColors.textPrimaryDark,
                                        fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: unread > 0
                                    ? CircleAvatar(
                                        radius: 10,
                                        backgroundColor: AppColors.accentGold,
                                        child: Text("$unread", style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryDark, size: 20),
                                onTap: () {
                                  sessionProv.startDemoSession(
                                    advisorId: thread['id'] as String,
                                    advisorName: thread['name'] as String,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LiveSessionScreen(isAdvisorView: false)),
                                  );
                                },
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

