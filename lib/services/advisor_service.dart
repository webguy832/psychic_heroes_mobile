import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/advisor_model.dart';

class AdvisorService {
  /// Fetches home page advisors with filtering & search
  Future<List<AdvisorDto>> getHomeAdvisors({String? categoryId, String? search}) async {
    final body = <String, dynamic>{
      'page': 1,
      'pageSize': 10,
      'recordCount': 0,
      'sortColumn': 'displayName',
      'sortOrder': 'asc',
      'searchName': search ?? '',
      'categoryId': (categoryId != null && categoryId.isNotEmpty) ? categoryId : null,
      'items': [],
    };

    final response = await ApiClient.post(
      ApiEndpoints.homeAdvisors,
      body: body,
      requiresAuth: false,
    );

    if (response is Map && response.containsKey('items') && response['items'] is List) {
      final list = response['items'] as List;
      return list.map((item) => AdvisorDto.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is Map && response.containsKey('advisors') && response['advisors'] is List) {
      final list = response['advisors'] as List;
      return list.map((item) => AdvisorDto.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is Map && response.containsKey('data') && response['data'] is List) {
      final list = response['data'] as List;
      return list.map((item) => AdvisorDto.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is List) {
      return response.map((item) => AdvisorDto.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Fetches full Advisor profile details by ID from api/advisor/{id}?userId={userId} (matching web_angular_2025)
  Future<AdvisorDto> getAdvisorById(String advisorId, {String? userId}) async {
    final queryParams = <String, String>{};
    if (userId != null && userId.isNotEmpty) {
      queryParams['userId'] = userId;
    }

    final endpoint = '${ApiEndpoints.advisorDetail}/$advisorId';
    final response = await ApiClient.get(
      endpoint,
      requiresAuth: false,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is Map<String, dynamic>) {
      final data = response.containsKey('data') && response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      return AdvisorDto.fromJson(data);
    }
    throw Exception("Failed to load advisor details from API");
  }

  /// Fetches real advisor customer reviews from api/Web/GetAdvisorReviews (matching web_angular_2025)
  Future<Map<String, dynamic>> getAdvisorReviews(String advisorId, {int pageNumber = 1, int pageSize = 10}) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.advisorReviews,
        requiresAuth: false,
        queryParams: {
          'advisorId': advisorId,
          'pageNumber': pageNumber.toString(),
          'pageSize': pageSize.toString(),
        },
      );

      List<AdvisorReviewDto> reviews = [];
      int totalCount = 0;

      if (response is Map<String, dynamic>) {
        totalCount = (response['totalCount'] is num)
            ? (response['totalCount'] as num).toInt()
            : int.tryParse(response['totalCount']?.toString() ?? '0') ?? 0;

        final rawData = response['data'];
        if (rawData is List) {
          reviews = rawData.map((item) => AdvisorReviewDto.fromJson(item as Map<String, dynamic>)).toList();
        }
      } else if (response is List) {
        reviews = response.map((item) => AdvisorReviewDto.fromJson(item as Map<String, dynamic>)).toList();
        totalCount = reviews.length;
      }

      return {
        'reviews': reviews,
        'totalCount': totalCount,
      };
    } catch (_) {
      return {
        'reviews': <AdvisorReviewDto>[],
        'totalCount': 0,
      };
    }
  }

  /// Fetches user free minutes discount from api/web/GetUserFreeMinutes (matching web_angular_2025)
  Future<int> getUserFreeMinutes(String? userId) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }

      final response = await ApiClient.get(
        ApiEndpoints.userFreeMinutes,
        requiresAuth: false,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response is num) {
        return response.toInt();
      } else if (response is String) {
        return int.tryParse(response) ?? 0;
      } else if (response is Map && response.containsKey('data')) {
        final d = response['data'];
        if (d is num) return d.toInt();
        if (d is String) return int.tryParse(d) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Checks session eligibility, balance, and advisor online status from api/user/checkSessionEligibilty (matching web_angular_2025)
  Future<SessionEligibilityDto> checkSessionEligibility(String advisorId) async {
    final response = await ApiClient.post(
      ApiEndpoints.checkSessionEligibility,
      requiresAuth: true,
      queryParams: {'advisorId': advisorId},
    );

    if (response is Map<String, dynamic>) {
      return SessionEligibilityDto.fromJson(response);
    }
    throw Exception("Failed to check session eligibility");
  }

  /// Fetches advisor's own profile details (including Guid profile ID) via api/advisor/GetAdvisorProfileDetails
  Future<Map<String, dynamic>?> getAdvisorProfileDetails() async {
    try {
      final response = await ApiClient.get("api/advisor/GetAdvisorProfileDetails", requiresAuth: true);
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
