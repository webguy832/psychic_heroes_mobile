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

  Future<double> getUserBalance() async {
    final response = await ApiClient.get(ApiEndpoints.userBalance);
    if (response is Map && response.containsKey('balance')) {
      return (response['balance'] as num).toDouble();
    } else if (response is num) {
      return response.toDouble();
    }
    return 0.0;
  }

  Future<List<NotificationDto>> getNotifications() async {
    final response = await ApiClient.get(ApiEndpoints.userNotifications);
    if (response is List) {
      return response.map((item) => NotificationDto.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> markNotificationAsRead(int id) async {
    await ApiClient.post(ApiEndpoints.markNotificationRead(id));
  }

  Future<void> readAllNotifications() async {
    await ApiClient.post(ApiEndpoints.readAllNotifications);
  }

  Future<List<BillingAddressDto>> getBillingAddresses() async {
    final response = await ApiClient.get(ApiEndpoints.getBillingAddresses);
    if (response is List) {
      return response.map((item) => BillingAddressDto.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
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
