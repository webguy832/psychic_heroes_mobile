import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_keys.dart';
import '../core/services/audio_service.dart';
import '../core/utils/storage_service.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/user_service.dart';
import '../services/advisor_service.dart';
import '../services/signalr_service.dart';
import '../views/advisors/advisor_premium_requests_screen.dart';
import '../views/advisors/advisor_text_readings_screen.dart';
import '../views/menu_pages/customer_premium_requests_screen.dart';
import '../views/menu_pages/reading_history_screen.dart';
import '../views/user/notifications_screen.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final AdvisorService _advisorService = AdvisorService();

  UserModel? _user;
  String? _advisorProfileId;
  UserWalletSummary? _walletSummary;
  List<BillingAddressDto> _billingAddresses = [];
  List<NotificationDto> _notifications = [];
  List<TransactionHistoryDto> _transactions = [];
  List<ReadingHistoryItem> _readingHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get advisorProfileId => _advisorProfileId;
  UserWalletSummary? get walletSummary => _walletSummary;
  List<BillingAddressDto> get billingAddresses => _billingAddresses;
  List<NotificationDto> get notifications => _notifications;
  List<TransactionHistoryDto> get transactions => _transactions;
  List<ReadingHistoryItem> get readingHistory => _readingHistory;
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get userBalance => _walletSummary?.balance ?? _user?.walletBalance ?? 0.0;
  int get freeMinutes => _walletSummary != null ? _walletSummary!.minBalance.toInt() : (_user?.freeMinutes ?? 0);
  int get karmaPoints => _user?.karmaPoints ?? 0;
  int get currentStreak => _user?.streakCount ?? 1;
  String get tierLevel => _user?.tierLevel ?? "Member";

  bool get isAdvisor => _user?.role?.toUpperCase().contains('ADVISOR') == true || _user?.email.toLowerCase().contains('advisor') == true;
  bool get isCustomer => !isAdvisor;

  void updateWalletBalance(double newBalance) {
    if (_user != null) {
      _user = _user!.copyWith(walletBalance: newBalance);
      notifyListeners();
    }
  }

  void addKarmaPoints(int pts) {
    if (_user != null) {
      _user = _user!.copyWith(karmaPoints: _user!.karmaPoints + pts);
      notifyListeners();
    }
  }

  void clearUser() {
    stopNotificationPolling();
    _user = null;
    _advisorProfileId = null;
    _walletSummary = null;
    _billingAddresses = [];
    _notifications = [];
    _transactions = [];
    _readingHistory = [];
    SignalRService().disconnect();
    notifyListeners();
  }

  /// Resolves the actual Advisor Profile GUID for this advisor user (parity with Angular GetAdvisorProfileDetails)
  Future<String?> getOrFetchAdvisorProfileId() async {
    if (_advisorProfileId != null && _advisorProfileId!.isNotEmpty) {
      return _advisorProfileId;
    }
    final saved = await StorageService.getAdvisorProfileId();
    if (saved != null && saved.isNotEmpty) {
      _advisorProfileId = saved;
      return saved;
    }
    if (isAdvisor) {
      try {
        final advDetails = await _advisorService.getAdvisorProfileDetails();
        if (advDetails != null) {
          final profId = advDetails['id']?.toString() ??
              advDetails['Id']?.toString() ??
              advDetails['userProfile']?['id']?.toString() ??
              advDetails['userProfile']?['Id']?.toString();
          if (profId != null && profId.isNotEmpty) {
            _advisorProfileId = profId;
            await StorageService.saveAdvisorProfileId(profId);
            return profId;
          }
        }
      } catch (_) {}
    }
    return _user?.id;
  }

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }
      final savedUser = await StorageService.getUser();
      if (savedUser != null && savedUser.isNotEmpty) {
        _user = UserModel.fromJson(savedUser);
      }

      final apiUser = await _userService.getUserProfile();
      Map<String, dynamic> balanceSummary = {};
      try {
        balanceSummary = await _userService.getUserBalanceSummary();
      } catch (_) {}

      final bal = (balanceSummary['balance'] ?? balanceSummary['walletBalance'] ?? apiUser.walletBalance);
      final freeMins = (balanceSummary['minsBalance'] ?? balanceSummary['freeMinutes'] ?? apiUser.freeMinutes);
      final pts = (balanceSummary['totalPoints'] ?? balanceSummary['pointsBalance'] ?? apiUser.karmaPoints);
      final streak = (balanceSummary['currentStreak'] ?? apiUser.streakCount);
      final tier = (balanceSummary['tierLevel'] ?? apiUser.tierLevel);

      _user = apiUser.copyWith(
        walletBalance: (bal is num) ? bal.toDouble() : apiUser.walletBalance,
        freeMinutes: (freeMins is num) ? freeMins.toInt() : apiUser.freeMinutes,
        karmaPoints: (pts is num) ? pts.toInt() : apiUser.karmaPoints,
        streakCount: (streak is num) ? streak.toInt() : apiUser.streakCount,
        tierLevel: tier?.toString() ?? apiUser.tierLevel,
      );

      await StorageService.saveUser(_user!.toJson());

      // If advisor, fetch and cache the true advisor profile GUID (matching web_angular_2025 GetAdvisorProfileDetails)
      String effectiveAdvProfileId = '';
      if (isAdvisor) {
        try {
          final savedAdvId = await StorageService.getAdvisorProfileId();
          if (savedAdvId != null && savedAdvId.isNotEmpty) {
            effectiveAdvProfileId = savedAdvId;
            _advisorProfileId = savedAdvId;
          }
          final advDetails = await _advisorService.getAdvisorProfileDetails();
          if (advDetails != null) {
            final profId = advDetails['id']?.toString() ??
                advDetails['Id']?.toString() ??
                advDetails['userProfile']?['id']?.toString() ??
                advDetails['userProfile']?['Id']?.toString();
            if (profId != null && profId.isNotEmpty) {
              effectiveAdvProfileId = profId;
              _advisorProfileId = profId;
              await StorageService.saveAdvisorProfileId(profId);
            }
          }
        } catch (e) {
          debugPrint("Failed to fetch advisor profile details: $e");
        }
      }

      // Register presence on SignalR Hub (matching web_angular_2025 parity)
      try {
        SignalRService().ensureConnected(
          userName: _user!.displayName.isNotEmpty ? _user!.displayName : 'User',
          userId: _user!.id,
          advisorProfileId: effectiveAdvProfileId,
          isAdvisor: isAdvisor,
        );
      } catch (e) {
        debugPrint("SignalR auto-connect error: $e");
      }

      // Start background real-time notification polling
      startNotificationPolling();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile(UserModel updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = updatedUser;
      await StorageService.saveUser(updatedUser.toJson());
      await _userService.editProfile(updatedUser.toJson());
      await fetchUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchWalletSummary() async {
    try {
      _walletSummary = await _userService.getWalletSummary(isAdvisor: isAdvisor);
      if (_walletSummary != null && _user != null) {
        _user = _user!.copyWith(
          walletBalance: _walletSummary!.balance,
          freeMinutes: _walletSummary!.minBalance.toInt(),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint("fetchWalletSummary error: $e");
    }
  }

  Future<void> loadWalletData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _userService.getWalletSummary(isAdvisor: isAdvisor),
        _userService.getTransactions(isAdvisor: isAdvisor),
      ]);
      _walletSummary = results[0] as UserWalletSummary?;
      _transactions = results[1] as List<TransactionHistoryDto>;

      if (_walletSummary != null && _user != null) {
        _user = _user!.copyWith(
          walletBalance: _walletSummary!.balance,
          freeMinutes: _walletSummary!.minBalance.toInt(),
        );
      }
    } catch (e) {
      _errorMessage = "Failed to load wallet details";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransactions() async {
    try {
      _transactions = await _userService.getTransactions(isAdvisor: isAdvisor);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchReadingHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _readingHistory = await _userService.getReadingHistory(isAdvisor: isAdvisor);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBillingAddresses() async {
    try {
      _billingAddresses = await _userService.getBillingAddresses();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await _userService.getNotifications(isAdvisor: isAdvisor);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    final success = await _userService.markNotificationAsRead(id, isAdvisor: isAdvisor);
    if (success) {
      _notifications = _notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final success = await _userService.readAllNotifications(isAdvisor: isAdvisor);
    if (success) {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    }
  }

  // --- Real-time Notification Background Polling & In-App Alerts ---
  Timer? _notificationPollingTimer;
  final Set<int> _knownNotificationIds = {};
  bool _isFirstNotificationFetch = true;

  void startNotificationPolling() {
    _notificationPollingTimer?.cancel();
    _isFirstNotificationFetch = true;
    _knownNotificationIds.clear();
    // Immediate initial poll
    pollNotificationsSilently();
    // Background polling every 5 seconds
    _notificationPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      pollNotificationsSilently();
    });
  }

  void stopNotificationPolling() {
    _notificationPollingTimer?.cancel();
    _notificationPollingTimer = null;
    _knownNotificationIds.clear();
  }

  Future<void> pollNotificationsSilently() async {
    if (_user == null) return;
    try {
      final list = await _userService.getNotifications(isAdvisor: isAdvisor);
      if (_user == null) return;

      if (_isFirstNotificationFetch) {
        _isFirstNotificationFetch = false;
        _knownNotificationIds.addAll(list.map((n) => n.id));
        _notifications = list;
        notifyListeners();
        return;
      }

      // Detect brand new notifications that were not present in previous snapshot
      NotificationDto? latestNewNotification;
      for (var n in list) {
        if (!_knownNotificationIds.contains(n.id)) {
          _knownNotificationIds.add(n.id);
          if (!n.isRead && latestNewNotification == null) {
            latestNewNotification = n;
          }
        }
      }

      _notifications = list;
      notifyListeners();

      if (latestNewNotification != null) {
        // Play notification chime sound
        AudioService.playMessageChime();
        // Show in-app banner toast with 1-tap navigation
        _showInAppNotificationBanner(latestNewNotification);
      }
    } catch (_) {}
  }

  void _showInAppNotificationBanner(NotificationDto notification) {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final detail = notification.message;
    final isPremium = detail.toLowerCase().contains('premium') || detail.toLowerCase().contains('luxe');
    final isTextReading = detail.toLowerCase().contains('text reading');

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: const Color(0xFF281145),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isPremium ? AppColors.accentGold : AppColors.onlineGreen,
            width: 1.5,
          ),
        ),
        elevation: 10,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isPremium ? AppColors.accentGold : AppColors.onlineGreen).withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPremium
                    ? Icons.diamond_rounded
                    : (isTextReading ? Icons.mail_rounded : Icons.notifications_active_rounded),
                color: isPremium ? AppColors.accentGold : AppColors.onlineGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium
                        ? "Platinum / Luxe Update"
                        : (isTextReading ? "Text Reading Update" : "New Notification"),
                    style: TextStyle(
                      color: isPremium ? AppColors.accentGold : AppColors.onlineGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isPremium ? AppColors.accentGold : AppColors.onlineGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                final nav = appNavigatorKey.currentState;
                if (nav == null) return;

                if (isAdvisor) {
                  if (isPremium) {
                    nav.push(MaterialPageRoute(builder: (_) => const AdvisorPremiumRequestsScreen()));
                  } else if (isTextReading) {
                    nav.push(MaterialPageRoute(builder: (_) => const AdvisorTextReadingsScreen()));
                  } else {
                    nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  }
                } else {
                  if (isPremium) {
                    nav.push(MaterialPageRoute(builder: (_) => const CustomerPremiumRequestsScreen()));
                  } else if (isTextReading) {
                    nav.push(MaterialPageRoute(builder: (_) => const ReadingHistoryScreen()));
                  } else {
                    nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  }
                }
              },
              child: const Text("View", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> createBillingAddress(BillingAddressDto dto) async {
    try {
      final success = await _userService.createBillingAddress(dto);
      if (success) {
        await fetchBillingAddresses();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
