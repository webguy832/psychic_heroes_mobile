import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/utils/storage_service.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isDevMode = false;

  NavigationProvider() {
    _initDevMode();
  }

  int get currentIndex => _currentIndex;
  bool get isDevMode => _isDevMode;
  bool get isDemoMode => !_isDevMode;

  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> _initDevMode() async {
    // 1. Check persistent storage first
    try {
      final storedDev = await StorageService.getDevMode();
      _isDevMode = storedDev;
    } catch (_) {}

    // 2. Check URL parameters if running on Web
    if (kIsWeb) {
      try {
        final uri = Uri.base;
        final urlLower = uri.toString().toLowerCase();

        // Check query parameters (e.g. ?dev=true, ?dev=1, ?mode=dev, ?devmode=true)
        final devParam = uri.queryParameters['dev']?.toLowerCase() ??
            uri.queryParameters['mode']?.toLowerCase() ??
            uri.queryParameters['development']?.toLowerCase() ??
            uri.queryParameters['devmode']?.toLowerCase() ??
            uri.queryParameters['demo']?.toLowerCase();

        if (devParam == 'true' || devParam == '1' || devParam == 'dev') {
          _isDevMode = true;
          await StorageService.saveDevMode(true);
        } else if (devParam == 'false' || devParam == '0' || devParam == 'demo') {
          _isDevMode = false;
          await StorageService.saveDevMode(false);
        } else if (urlLower.contains('dev=true') || urlLower.contains('dev=1') || urlLower.contains('mode=dev')) {
          _isDevMode = true;
          await StorageService.saveDevMode(true);
        } else if (urlLower.contains('dev=false') || urlLower.contains('dev=0') || urlLower.contains('mode=demo')) {
          _isDevMode = false;
          await StorageService.saveDevMode(false);
        }
      } catch (e) {
        debugPrint("Error parsing DevMode URL params: $e");
      }
    }

    notifyListeners();
  }

  Future<void> setDevMode(bool value) async {
    _isDevMode = value;
    await StorageService.saveDevMode(value);
    _currentIndex = 0; // Reset to Home when switching mode
    notifyListeners();
  }

  Future<void> toggleDevMode() async {
    await setDevMode(!_isDevMode);
  }
}
