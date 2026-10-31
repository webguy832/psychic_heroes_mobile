import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/slider_model.dart';
import '../models/category_model.dart';

class HomeService {
  Future<List<SliderDto>> getSliders() async {
    final response = await ApiClient.get(ApiEndpoints.homeSliders, requiresAuth: false);
    if (response is Map && response.containsKey('sliders') && response['sliders'] is List) {
      final list = response['sliders'] as List;
      return list.map((item) => SliderDto.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is List) {
      return response.map((item) => SliderDto.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<CategoryDto>> getPsychicCategories() async {
    final response = await ApiClient.get(ApiEndpoints.psychicCategories, requiresAuth: false);
    if (response is Map && response.containsKey('parentPsychicCategory') && response['parentPsychicCategory'] is List) {
      final list = response['parentPsychicCategory'] as List;
      return list.map((item) => CategoryDto.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is List) {
      return response.map((item) => CategoryDto.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
