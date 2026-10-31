import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/advisor_model.dart';

class AdvisorService {
  Future<List<AdvisorDto>> getHomeAdvisors({String? categoryId, String? search}) async {
    final body = <String, dynamic>{
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await ApiClient.post(
      ApiEndpoints.homeAdvisors,
      body: body,
      requiresAuth: false,
    );

    if (response is Map && response.containsKey('advisors') && response['advisors'] is List) {
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
}
