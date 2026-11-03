import 'package:flutter/material.dart';
import '../models/slider_model.dart';
import '../models/category_model.dart';
import '../models/advisor_model.dart';
import '../services/home_service.dart';
import '../services/advisor_service.dart';

class HomeProvider extends ChangeNotifier {
  final HomeService _homeService = HomeService();
  final AdvisorService _advisorService = AdvisorService();

  List<SliderDto> _sliders = [];
  List<CategoryDto> _categories = [];
  List<AdvisorDto> _advisors = [];
  
  String? _selectedCategoryId;
  String _searchQuery = '';
  
  bool _isLoadingBanners = false;
  bool _isLoadingCategories = false;
  bool _isLoadingAdvisors = false;
  String? _errorMessage;

  List<SliderDto> get sliders => _sliders;
  List<CategoryDto> get categories => _categories;
  List<AdvisorDto> get advisors => _advisors;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoadingBanners || _isLoadingCategories || _isLoadingAdvisors;

  Future<void> initHomeData() async {
    await Future.wait([
      fetchBanners(),
      fetchCategories(),
      fetchAdvisors(),
    ]);
  }

  Future<void> fetchBanners() async {
    _isLoadingBanners = true;
    notifyListeners();
    try {
      _sliders = await _homeService.getSliders();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingBanners = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    notifyListeners();
    try {
      _categories = await _homeService.getPsychicCategories();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdvisors() async {
    _isLoadingAdvisors = true;
    notifyListeners();
    try {
      _advisors = await _advisorService.getHomeAdvisors(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingAdvisors = false;
      notifyListeners();
    }
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    fetchAdvisors();
  }

  void searchAdvisors(String query) {
    _searchQuery = query;
    fetchAdvisors();
  }
}
