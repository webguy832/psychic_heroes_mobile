import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/text_reading_model.dart';

class TextReadingService {
  /// Fetches customer's text readings
  Future<List<TextReadingModel>> getCustomerTextReadings() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.customerTextReadings);
      if (response is List) {
        return response
            .map((item) => TextReadingModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic>) {
        final list = response['data'] ?? response['value'] ?? response['items'];
        if (list is List) {
          return list
              .map((item) => TextReadingModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      // Return empty list on 404 or missing
      return [];
    }
  }

  /// Creates a new text reading request (Regular $9.99 or Fast Track $19.99)
  Future<dynamic> createTextReading(Map<String, dynamic> payload) async {
    return await ApiClient.post(ApiEndpoints.textReadingRequest, body: payload);
  }

  /// Uploads optional photo/doc attachment for the created text reading
  Future<dynamic> uploadTextReadingFile(int id, List<int> bytes, String fileName) async {
    return await ApiClient.uploadMultipart(
      ApiEndpoints.uploadTextReadingFile(id),
      fileBytes: bytes,
      fileName: fileName,
      fileField: 'file',
    );
  }

  /// Retrieves clarification thread messages between customer and advisor
  Future<List<ServiceMessageModel>> getServiceMessages(int entityId, {int entityType = 2}) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.getServiceMessages,
        queryParams: {
          'EntityId': entityId.toString(),
          'EntityType': entityType.toString(),
        },
      );

      if (response is List) {
        return response
            .map((item) => ServiceMessageModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic>) {
        final list = response['data'] ?? response['value'] ?? response['items'];
        if (list is List) {
          return list
              .map((item) => ServiceMessageModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Posts clarification question (advisor) or reply (customer)
  Future<dynamic> createServiceMessage(Map<String, dynamic> payload) async {
    return await ApiClient.post(ApiEndpoints.requestAdditionalMessage, body: payload);
  }

  /// Fetches advisor's all text readings with pagination
  Future<Map<String, dynamic>> getAdvisorTextReadings({int pageNumber = 1, int pageSize = 10}) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.advisorTextReadings,
        queryParams: {
          'pageNumber': pageNumber.toString(),
          'pageSize': pageSize.toString(),
        },
      );

      if (response is Map<String, dynamic>) {
        final list = (response['data'] is List)
            ? (response['data'] as List)
                .map((item) => TextReadingModel.fromJson(item as Map<String, dynamic>))
                .toList()
            : <TextReadingModel>[];
        final totalCount = response['totalCount'] is int
            ? response['totalCount']
            : int.tryParse(response['totalCount']?.toString() ?? '0') ?? list.length;
        return {
          'data': list,
          'totalCount': totalCount,
          'totalPages': response['totalPages'] ?? 1,
        };
      }
      return {'data': <TextReadingModel>[], 'totalCount': 0, 'totalPages': 1};
    } catch (e) {
      return {'data': <TextReadingModel>[], 'totalCount': 0, 'totalPages': 1};
    }
  }

  /// Fetches pending advisor text reading requests
  Future<Map<String, dynamic>> getPendingAdvisorTextReadings({int pageNumber = 1, int pageSize = 10}) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.pendingAdvisorTextReadings,
        queryParams: {
          'pageNumber': pageNumber.toString(),
          'pageSize': pageSize.toString(),
        },
      );

      if (response is Map<String, dynamic>) {
        final list = (response['data'] is List)
            ? (response['data'] as List)
                .map((item) => TextReadingModel.fromJson(item as Map<String, dynamic>))
                .toList()
            : <TextReadingModel>[];
        final totalCount = response['totalCount'] is int
            ? response['totalCount']
            : int.tryParse(response['totalCount']?.toString() ?? '0') ?? list.length;
        return {
          'data': list,
          'totalCount': totalCount,
          'totalPages': response['totalPages'] ?? 1,
        };
      }
      return {'data': <TextReadingModel>[], 'totalCount': 0, 'totalPages': 1};
    } catch (e) {
      return {'data': <TextReadingModel>[], 'totalCount': 0, 'totalPages': 1};
    }
  }

  /// Fetches single text reading details by request ID
  Future<TextReadingModel?> getTextReadingById(int requestId) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.getTextReadingById,
        queryParams: {'requestId': requestId.toString()},
      );

      if (response is Map<String, dynamic>) {
        final data = response.containsKey('data') && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return TextReadingModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Submits final reading text to complete reading and credit advisor
  Future<dynamic> submitFinalTextReading({required int id, required String text}) async {
    return await ApiClient.post(
      ApiEndpoints.submitTextReading,
      body: {
        'Id': id,
        'Text': text,
      },
    );
  }
}
