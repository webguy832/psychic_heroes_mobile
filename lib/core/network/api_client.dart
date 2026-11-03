import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../utils/storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  static Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final base = (ApiEndpoints.baseUrl.isNotEmpty ? ApiEndpoints.baseUrl : "https://psychicheroes.online/").endsWith('/')
        ? (ApiEndpoints.baseUrl.isNotEmpty ? ApiEndpoints.baseUrl : "https://psychicheroes.online/")
        : '${ApiEndpoints.baseUrl}/';
    final fullPath = '$base$cleanPath';
    return Uri.parse(fullPath).replace(queryParameters: queryParameters);
  }

  static Future<dynamic> get(String endpoint, {bool requiresAuth = true, Map<String, String>? queryParams}) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.get(uri, headers: headers);
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Network connection error: ${e.toString()}");
    }
  }

  static Future<dynamic> post(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Network connection error: ${e.toString()}");
    }
  }

  static Future<dynamic> put(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Network connection error: ${e.toString()}");
    }
  }

  static Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.delete(uri, headers: headers);
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Network connection error: ${e.toString()}");
    }
  }

  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw ApiException("Failed to parse server response: ${e.toString()}", statusCode: response.statusCode);
      }
    } else {
      String errorMessage = "Request failed with status code ${response.statusCode}";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message'];
        } else if (decoded is Map && decoded.containsKey('error')) {
          errorMessage = decoded['error'];
        } else if (decoded is Map && decoded.containsKey('title')) {
          errorMessage = decoded['title'];
        }
      } catch (_) {}
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }
}
