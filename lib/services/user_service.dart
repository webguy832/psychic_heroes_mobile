import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/utils/storage_service.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class UserService {
  Future<UserModel> getUserProfile() async {
    final response = await ApiClient.get(ApiEndpoints.userProfile);
    if (response is Map<String, dynamic>) {
      final userData = response.containsKey('data') ? response['data'] : response;
      return UserModel.fromJson(userData as Map<String, dynamic>);
    }
    throw Exception("Invalid user profile payload");
  }

  Future<bool> editProfile(Map<String, dynamic> updateDto) async {
    final response = await ApiClient.post(ApiEndpoints.editProfile, body: updateDto);
    return response != null;
  }

  Future<Map<String, dynamic>> getUserBalanceSummary() async {
    final response = await ApiClient.get(ApiEndpoints.userBalance);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {
      'balance': 0.0,
      'freeMinutes': 0,
      'totalPoints': 0,
      'currentStreak': 1,
      'tierLevel': 'Member'
    };
  }

  Future<double> getUserBalance() async {
    final summary = await getUserBalanceSummary();
    final bal = summary['balance'] ?? summary['walletBalance'] ?? 0;
    return (bal as num).toDouble();
  }

  Future<UserWalletSummary?> getWalletSummary({bool isAdvisor = false}) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return null;

    if (isAdvisor) {
      try {
        final response = await ApiClient.get(ApiEndpoints.advisorWalletSummary);
        if (response is Map<String, dynamic>) {
          final data = response.containsKey('data') && response['data'] is Map<String, dynamic>
              ? response['data']
              : response;
          return UserWalletSummary.fromJson(data as Map<String, dynamic>);
        }
      } catch (_) {}
    }

    try {
      final response = await ApiClient.get(ApiEndpoints.walletSummary);
      if (response is Map<String, dynamic>) {
        final data = response.containsKey('data') && response['data'] is Map<String, dynamic>
            ? response['data']
            : response;
        return UserWalletSummary.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      // If customer wallet summary fails, try advisor wallet summary
      try {
        final response = await ApiClient.get(ApiEndpoints.advisorWalletSummary);
        if (response is Map<String, dynamic>) {
          final data = response.containsKey('data') && response['data'] is Map<String, dynamic>
              ? response['data']
              : response;
          return UserWalletSummary.fromJson(data as Map<String, dynamic>);
        }
      } catch (_) {}
      return null;
    }
  }

  Future<List<TransactionHistoryDto>> getTransactions({bool isAdvisor = false}) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return [];

    if (isAdvisor) {
      try {
        final response = await ApiClient.get(ApiEndpoints.advisorWalletTransactions);
        final list = (response is List)
            ? response
            : (response is Map && response['data'] is List ? response['data'] : null);
        if (list != null && list.isNotEmpty) {
          return list.map((item) => TransactionHistoryDto.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (_) {}

      // Also try earnings history
      try {
        final earnResp = await ApiClient.get(ApiEndpoints.advisorEarningsHistory);
        final list = (earnResp is List)
            ? earnResp
            : (earnResp is Map && earnResp['data'] is List ? earnResp['data'] : null);
        if (list != null && list.isNotEmpty) {
          return list.map((item) => TransactionHistoryDto.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }

    try {
      final response = await ApiClient.get(ApiEndpoints.walletTransactions);
      if (response is List) {
        return response.map((item) => TransactionHistoryDto.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        return (response['data'] as List).map((item) => TransactionHistoryDto.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      // If customer transactions fail or unauthorized, fallback to advisor transactions
      try {
        final response = await ApiClient.get(ApiEndpoints.advisorWalletTransactions);
        final list = (response is List)
            ? response
            : (response is Map && response['data'] is List ? response['data'] : null);
        if (list != null && list.isNotEmpty) {
          return list.map((item) => TransactionHistoryDto.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
      return [];
    }
  }

  Future<List<ReadingHistoryItem>> getReadingHistory({bool isAdvisor = false}) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return [];

    if (isAdvisor) {
      try {
        final advResp = await ApiClient.get(ApiEndpoints.advisorBookingsHistory);
        final list = (advResp is List)
            ? advResp
            : (advResp is Map && advResp['data'] is List ? advResp['data'] : null);
        if (list != null && list.isNotEmpty) {
          return list.map((item) => ReadingHistoryItem.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (_) {}

      // If bookings history is empty, check earnings history
      try {
        final earnResp = await ApiClient.get(ApiEndpoints.advisorEarningsHistory);
        final list = (earnResp is List)
            ? earnResp
            : (earnResp is Map && earnResp['data'] is List ? earnResp['data'] : null);
        if (list != null && list.isNotEmpty) {
          return list.map((item) => ReadingHistoryItem.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
      return [];
    }

    // Customer flow
    try {
      final response = await ApiClient.get(ApiEndpoints.readingHistory);
      if (response is List) {
        return response.map((item) => ReadingHistoryItem.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        return (response['data'] as List).map((item) => ReadingHistoryItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      // If customer history 403s (e.g. user is logged in as advisor), fallback to advisor history
      try {
        final advResp = await ApiClient.get(ApiEndpoints.advisorBookingsHistory);
        final list = (advResp is List)
            ? advResp
            : (advResp is Map && advResp['data'] is List ? advResp['data'] : null);
        if (list != null && list.isNotEmpty) {
          return list.map((item) => ReadingHistoryItem.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
      return [];
    }
  }

  Future<List<NotificationDto>> getNotifications() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return [];
    try {
      final response = await ApiClient.get(ApiEndpoints.userNotifications);
      if (response is List) {
        return response.map((item) => NotificationDto.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    await ApiClient.post(ApiEndpoints.markNotificationRead(id));
  }

  Future<void> readAllNotifications() async {
    await ApiClient.post(ApiEndpoints.readAllNotifications);
  }

  Future<List<BillingAddressDto>> getBillingAddresses() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return [];
    try {
      final response = await ApiClient.get(ApiEndpoints.getBillingAddresses);
      if (response is List) {
        return response.map((item) => BillingAddressDto.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> createBillingAddress(BillingAddressDto dto) async {
    final response = await ApiClient.post(ApiEndpoints.createBillingAddress, body: dto.toJson());
    return response != null;
  }

  Future<bool> updateBillingAddress(BillingAddressDto dto) async {
    if (dto.billingId == null) return false;
    final response = await ApiClient.put(ApiEndpoints.updateBillingAddress(dto.billingId!), body: dto.toJson());
    return response != null;
  }
}
