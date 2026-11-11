import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyToken = "jwt_token";
  static const String keyUser = "user_data";
  static const String keyDevMode = "dev_mode_enabled";

  static Future<void> saveDevMode(bool isDev) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyDevMode, isDev);
  }

  static Future<bool> getDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyDevMode) ?? false;
  }

  static Map<String, dynamic>? decodeTokenPayload(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payloadString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) return null;
        String output = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        switch (output.length % 4) {
          case 0:
            break;
          case 2:
            output += '==';
            break;
          case 3:
            output += '=';
            break;
          default:
            return null;
        }
        final payloadString = utf8.decode(base64.decode(output));
        final decoded = jsonDecode(payloadString);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
      return null;
    }
  }

  /// Checks if JWT token is expired based on 'exp' claim (matching web_angular_2025 shared.interceptor)
  static bool isTokenExpired(String? token) {
    if (token == null || token.trim().isEmpty) return true;
    final payload = decodeTokenPayload(token);
    if (payload == null) return true;

    final exp = payload['exp'];
    if (exp == null) return false;

    final expSeconds = (exp is num) ? exp.toInt() : int.tryParse(exp.toString());
    if (expSeconds == null) return false;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds >= expSeconds;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(keyToken);
    if (token != null && isTokenExpired(token)) {
      // Auto-clear expired token and user session (matching Angular shared.interceptor)
      await clearSession();
      return null;
    }
    return token;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> saveUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUser, jsonEncode(userMap));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(keyUser);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyToken);
    await prefs.remove(keyUser);
  }
}
