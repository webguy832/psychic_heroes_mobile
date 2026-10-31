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
    } catch (_) {
      // Mock default slider if backend yields empty
      if (_sliders.isEmpty) {
        _sliders = [
          SliderDto(
            id: 1,
            title: "Unlock Your Future Today",
            subtitle: "First 3 minutes FREE with top Psychic Advisors",
            imageUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800&auto=format&fit=crop",
          ),
          SliderDto(
            id: 2,
            title: "Tarot & Astrology Insights",
            subtitle: "Get answers to your deepest love & life questions",
            imageUrl: "https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=800&auto=format&fit=crop",
          )
        ];
      }
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
    } catch (_) {
      if (_categories.isEmpty) {
        _categories = [
          CategoryDto(id: "1", name: "All Psychics"),
          CategoryDto(id: "2", name: "Love & Relationships"),
          CategoryDto(id: "3", name: "Tarot Reading"),
          CategoryDto(id: "4", name: "Astrology & Horoscope"),
          CategoryDto(id: "5", name: "Career & Finance"),
        ];
      }
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
    } catch (_) {
      if (_advisors.isEmpty) {
        _advisors = [
          AdvisorDto(
            id: "101",
            name: "Psychic Serena",
            status: "Online",
            rating: 4.9,
            reviewsCount: 342,
            pricePerMinute: 2.99,
            categoryName: "Love & Tarot",
            bio: "Clairvoyant reader specializing in love twin flames and deep life purpose.",
          ),
          AdvisorDto(
            id: "102",
            name: "Master Orion",
            status: "Busy",
            rating: 5.0,
            reviewsCount: 890,
            pricePerMinute: 3.49,
            categoryName: "Astrology",
            bio: "Vedic & Western astrology expert. Insights on career and relationship destiny.",
          ),
          AdvisorDto(
            id: "103",
            name: "Mystic Luna",
            status: "Online",
            rating: 4.8,
            reviewsCount: 156,
            pricePerMinute: 1.99,
            categoryName: "Psychic Medium",
            bio: "Empathetic channeler offering clarity and peace through spirit guide readings.",
          ),
        ];
      }
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
