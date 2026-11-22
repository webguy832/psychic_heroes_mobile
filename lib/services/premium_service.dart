import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/premium_service_model.dart';
import '../models/text_reading_model.dart';

class PremiumService {
  /// Fetches all active premium categories
  Future<List<PremiumCategoryModel>> getPremiumCategories({String? advisorId}) async {
    try {
      final queryParams = <String, String>{};
      if (advisorId != null && advisorId.isNotEmpty) {
        queryParams['advisorId'] = advisorId;
      }

      final response = await ApiClient.get(
        ApiEndpoints.premiumCategory,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response is List) {
        return response
            .map((item) => PremiumCategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic>) {
        final list = response['value'] ?? response['data'] ?? response['items'];
        if (list is List) {
          return list
              .map((item) => PremiumCategoryModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching premium categories: $e");
      return [];
    }
  }

  /// Fetches luxe / premium services by category or advisor
  Future<List<PremiumServiceModel>> getLuxeServices({
    String? advisorId,
    int? categoryId,
    bool activeOnly = false,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (advisorId != null && advisorId.isNotEmpty) {
        queryParams['advisorId'] = advisorId;
      }
      if (categoryId != null && categoryId > 0) {
        queryParams['categoryId'] = categoryId.toString();
      }
      if (activeOnly) {
        queryParams['activeOnly'] = 'true';
      }

      final response = await ApiClient.get(
        ApiEndpoints.premiumLuxeCategories,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response is List) {
        return response
            .map((item) => PremiumServiceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic>) {
        final list = response['value'] ?? response['data'] ?? response['items'];
        if (list is List) {
          return list
              .map((item) => PremiumServiceModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching luxe services: $e");
      return [];
    }
  }

  /// Fetches service details and advisor profile
  Future<Map<String, dynamic>?> getServiceDetails(int serviceId) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.premiumDetails,
        queryParams: {'serviceId': serviceId.toString()},
      );
      if (response is Map<String, dynamic>) {
        final data = response['value'] is Map<String, dynamic>
            ? response['value'] as Map<String, dynamic>
            : (response['data'] is Map<String, dynamic>
                ? response['data'] as Map<String, dynamic>
                : response);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching service details: $e");
      return null;
    }
  }

  /// Checks balance & eligibility for ordering a premium service
  Future<StartPremiumEligibilityModel?> loadPremiumEligibility(int serviceId) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.loadPremium,
        queryParams: {'serviceId': serviceId.toString()},
      );

      if (response is Map<String, dynamic>) {
        final data = response['value'] is Map<String, dynamic>
            ? response['value'] as Map<String, dynamic>
            : (response['data'] is Map<String, dynamic>
                ? response['data'] as Map<String, dynamic>
                : response);
        return StartPremiumEligibilityModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint("Error loading premium eligibility: $e");
      return null;
    }
  }

  /// Places a new premium service order for current customer
  Future<Map<String, dynamic>> startPremiumOrder(int serviceId) async {
    final response = await ApiClient.post(
      ApiEndpoints.startPremium,
      body: {'ServiceId': serviceId},
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'message': 'Order processed successfully'};
  }

  /// Retrieves list of premium requests (orders) for customer or advisor with pagination
  Future<Map<String, dynamic>> getPremiumRequests({int pageNumber = 1, int pageSize = 10}) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.premiumRequests,
        queryParams: {
          'pageNumber': pageNumber.toString(),
          'pageSize': pageSize.toString(),
        },
      );

      if (response is Map<String, dynamic>) {
        final rawData = response['data'];
        final list = (rawData is List)
            ? rawData.map((item) => PremiumRequestModel.fromJson(item as Map<String, dynamic>)).toList()
            : <PremiumRequestModel>[];

        final totalCount = response['totalCount'] is int
            ? response['totalCount'] as int
            : int.tryParse(response['totalCount']?.toString() ?? '0') ?? list.length;

        final totalPages = response['totalPages'] is int
            ? response['totalPages'] as int
            : int.tryParse(response['totalPages']?.toString() ?? '1') ?? 1;

        return {
          'data': list,
          'totalCount': totalCount,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
          'totalPages': totalPages,
        };
      }
      return {
        'data': <PremiumRequestModel>[],
        'totalCount': 0,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'totalPages': 0,
      };
    } catch (e) {
      debugPrint("Error fetching premium requests: $e");
      return {
        'data': <PremiumRequestModel>[],
        'totalCount': 0,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'totalPages': 0,
      };
    }
  }

  /// Fetches single premium request detail by requestId
  Future<PremiumRequestModel?> getPremiumRequestDetail(int requestId) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.premiumRequestDetail,
        queryParams: {'requestId': requestId.toString()},
      );

      if (response is Map<String, dynamic>) {
        final data = response['value'] is Map<String, dynamic>
            ? response['value'] as Map<String, dynamic>
            : (response['data'] is Map<String, dynamic>
                ? response['data'] as Map<String, dynamic>
                : response);
        return PremiumRequestModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching premium request detail: $e");
      return null;
    }
  }

  /// Advisor accepts a pending premium request offer
  Future<bool> acceptOffer(int requestId) async {
    final response = await ApiClient.post(
      ApiEndpoints.acceptPremiumRequest,
      body: {'RequestId': requestId},
    );

    if (response is Map<String, dynamic>) {
      return response['message'] != null || response['success'] == true;
    }
    return true;
  }

  /// Advisor marks an in-progress/processing premium request as completed
  Future<bool> markCompleted(int requestId) async {
    final response = await ApiClient.post(
      ApiEndpoints.markCompletedPremiumRequest,
      body: {'RequestId': requestId},
    );

    if (response is Map<String, dynamic>) {
      return response['message'] != null || response['success'] == true;
    }
    return true;
  }

  /// Advisor or customer cancels a premium service request
  Future<bool> cancelRequest(int requestId) async {
    final response = await ApiClient.post(
      ApiEndpoints.cancelPremiumRequest,
      body: {'RequestId': requestId},
    );

    if (response is Map<String, dynamic>) {
      return response['message'] != null || response['success'] == true;
    }
    return true;
  }

  /// Retrieves clarification conversation messages between customer and advisor
  /// EntityType = 1 for Premium Services (EntityType = 2 for Text Readings)
  Future<List<ServiceMessageModel>> getServiceMessages(int entityId) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.getServiceMessages,
        queryParams: {
          'EntityId': entityId.toString(),
          'EntityType': '1',
        },
      );

      if (response is List) {
        return response
            .map((item) => ServiceMessageModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => ServiceMessageModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching service messages: $e");
      return [];
    }
  }

  /// Sends a clarification message / query between customer and advisor
  Future<dynamic> createServiceMessage(Map<String, dynamic> payload) async {
    final body = Map<String, dynamic>.from(payload);
    body['entityTypeId'] = 1; // 1 for premium service
    return await ApiClient.post(ApiEndpoints.requestAdditionalMessage, body: body);
  }
}
