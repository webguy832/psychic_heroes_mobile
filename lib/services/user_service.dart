import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
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

  Future<List<TransactionHistoryDto>> getTransactions() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return [];
    try {
      final response = await ApiClient.get(ApiEndpoints.walletTransactions);
      if (response is List) {
        return response.map((item) => TransactionHistoryDto.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<ReadingHistoryItem>> getReadingHistory() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return [];
    try {
      final response = await ApiClient.get(ApiEndpoints.readingHistory);
      if (response is List) {
        return response.map((item) => ReadingHistoryItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
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
