import 'package:flutter/material.dart';
import '../core/utils/storage_service.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/user_service.dart';
import '../services/signalr_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? _user;
  List<BillingAddressDto> _billingAddresses = [];
  List<NotificationDto> _notifications = [];
  List<TransactionHistoryDto> _transactions = [];
  List<ReadingHistoryItem> _readingHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  List<BillingAddressDto> get billingAddresses => _billingAddresses;
  List<NotificationDto> get notifications => _notifications;
  List<TransactionHistoryDto> get transactions => _transactions;
  List<ReadingHistoryItem> get readingHistory => _readingHistory;
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get userBalance => _user?.walletBalance ?? 0.0;
  int get freeMinutes => _user?.freeMinutes ?? 0;
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
    _user = null;
    _billingAddresses = [];
    _notifications = [];
    _transactions = [];
    _readingHistory = [];
    SignalRService().disconnect();
    notifyListeners();
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

      // Register presence on SignalR Hub (matching web_angular_2025 parity)
      try {
        SignalRService().ensureConnected(
          userName: _user!.displayName.isNotEmpty ? _user!.displayName : 'User',
          userId: _user!.id,
          advisorProfileId: isAdvisor ? _user!.id : '',
          isAdvisor: isAdvisor,
        );
      } catch (e) {
        debugPrint("SignalR auto-connect error: $e");
      }
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

  Future<void> fetchTransactions() async {
    try {
      _transactions = await _userService.getTransactions();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchReadingHistory() async {
    try {
      _readingHistory = await _userService.getReadingHistory();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
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
    try {
      _notifications = await _userService.getNotifications();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
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
