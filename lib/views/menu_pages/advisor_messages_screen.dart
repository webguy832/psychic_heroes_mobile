import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/home_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/user_provider.dart';
import '../advisors/live_session_screen.dart';
import '../shared/app_footer_widget.dart';

class AdvisorMessagesScreen extends StatefulWidget {
  const AdvisorMessagesScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorMessagesScreen> createState() => _AdvisorMessagesScreenState();
}

class _AdvisorMessagesScreenState extends State<AdvisorMessagesScreen> {
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProv = Provider.of<HomeProvider>(context, listen: false);
      if (homeProv.advisors.isEmpty) {
        homeProv.fetchAdvisors();
      }
      Provider.of<UserProvider>(context, listen: false).fetchReadingHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeProv = Provider.of<HomeProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final sessionProv = Provider.of<SessionProvider>(context, listen: false);

    // Build threads dynamically from reading history + available advisors
    final List<Map<String, dynamic>> dynamicThreads = [];
    final seenAdvisorNames = <String>{};

    for (var r in userProv.readingHistory) {
      if (!seenAdvisorNames.contains(r.advisorName)) {
        seenAdvisorNames.add(r.advisorName);
        dynamicThreads.add({
          'id': r.id,
          'name': r.advisorName,
          'specialty': r.type,
          'lastMessage': r.summary.isNotEmpty ? r.summary : 'Completed session with ${r.advisorName}',
          'time': r.date,
          'unread': 0,
          'isOnline': true,
          'photo': null,
          'avatarColor': AppColors.accentGold,
        });
      }
    }

    for (var adv in homeProv.advisors) {
      if (!seenAdvisorNames.contains(adv.name)) {
        seenAdvisorNames.add(adv.name);
        dynamicThreads.add({
          'id': adv.id,
          'name': adv.name,
          'specialty': adv.categoryName ?? 'Spiritual Psychic Advisor',
          'lastMessage': (adv.bio != null && adv.bio!.isNotEmpty) ? adv.bio! : 'Available for live chat and guidance session.',
          'time': adv.status.toLowerCase() == 'online' ? 'Online Now' : 'Offline',
          'unread': 0,
          'isOnline': adv.status.toLowerCase() == 'online',
          'photo': adv.profilePhoto,
          'avatarColor': AppColors.primary,
        });
      }
    }

    final filteredThreads = dynamicThreads.where((t) {
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
                                      backgroundImage: (thread['photo'] != null && (thread['photo'] as String).isNotEmpty)
                                          ? NetworkImage((thread['photo'] as String).startsWith('http')
                                              ? (thread['photo'] as String)
                                              : '${ApiEndpoints.imageBaseUrl}${thread['photo']}')
                                          : null,
                                      child: (thread['photo'] == null || (thread['photo'] as String).isEmpty)
                                          ? Text(
                                              (thread['name'] as String)[0],
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                            )
                                          : null,
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

