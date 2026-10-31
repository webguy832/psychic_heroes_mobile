import 'package:flutter/material.dart';
import '../core/utils/storage_service.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? _user;
  List<BillingAddressDto> _billingAddresses = [];
  List<NotificationDto> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _karmaPoints = 150;

  UserModel? get user => _user;
  List<BillingAddressDto> get billingAddresses => _billingAddresses;
  List<NotificationDto> get notifications => _notifications;
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get userBalance => _user?.walletBalance ?? 0.0;
  int get karmaPoints => _karmaPoints;

  bool get isAdvisor => _user?.role?.toUpperCase().contains('ADVISOR') == true || _user?.email.toLowerCase().contains('advisor') == true;
  bool get isCustomer => !isAdvisor;

  void updateWalletBalance(double newBalance) {
    if (_user != null) {
      _user = _user!.copyWith(walletBalance: newBalance);
    } else {
      _user = UserModel(
        id: '1',
        email: 'user@example.com',
        fullName: 'User',
        walletBalance: newBalance,
      );
    }
    notifyListeners();
  }

  void addKarmaPoints(int pts) {
    _karmaPoints += pts;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _billingAddresses = [];
    _notifications = [];
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
      if (_user == null) {
        _user = apiUser;
      } else {
        // Merge real logged in user state
        _user = _user!.copyWith(
          fullName: (_user!.fullName?.isNotEmpty == true) ? _user!.fullName : apiUser.fullName,
          email: (_user!.email.isNotEmpty) ? _user!.email : apiUser.email,
          phoneNumber: (_user!.phoneNumber?.isNotEmpty == true) ? _user!.phoneNumber : apiUser.phoneNumber,
          walletBalance: apiUser.walletBalance > 0 ? apiUser.walletBalance : _user!.walletBalance,
        );
      }
      await StorageService.saveUser(_user!.toJson());
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
