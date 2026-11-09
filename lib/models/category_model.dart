/// Helper to identify raw GUIDs, hexadecimal tokens, or comma-separated lists of GUIDs
/// so that database foreign keys/category IDs are never rendered as user-facing text.
bool isGuidOrIdString(String? val) {
  if (val == null) return false;
  final trimmed = val.trim();
  if (trimmed.isEmpty) return false;

  final guidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  if (guidRegex.hasMatch(trimmed)) return true;

  if (trimmed.contains(',')) {
    final parts = trimmed.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty && parts.every((p) => guidRegex.hasMatch(p) || RegExp(r'^[0-9a-fA-F\-]{8,}$').hasMatch(p))) {
      return true;
    }
  }

  // Any string matching standard GUID structure
  if (RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}').hasMatch(trimmed)) {
    return true;
  }

  return false;
}

class CategoryDto {
  final String id;
  final String name;
  final String? icon;
  final String? description;

  CategoryDto({
    required this.id,
    required this.name,
    this.icon,
    this.description,
  });

  static final Map<String, String> _knownCategories = {
    '11111111-1111-1111-1111-111111111111': 'Love & Relationships',
    '22222222-2222-2222-2222-222222222222': 'Career & Finance',
    '33333333-3333-3333-3333-333333333333': 'Health & Wellness',
    '44444444-4444-4444-4444-444444444444': 'Spiritual Guidance',
    '55555555-5555-5555-5555-555555555555': 'Personal Growth',
    '45689f54-ab9b-4ffd-b206-2cf98df83918': 'Tarot Cards',
    '702efc13-124d-447f-8100-1a7a7f1f79d4': 'Healing & Aura Cleansing',
    '7a5a8afb-4f9b-433f-8d4b-4ef4f82ca1ed': 'Spiritual Reading',
    '7e710ed0-9c77-4a2c-aaab-980cbf9eeffd': 'Psychic Reading',
    '83362572-0f21-454f-8634-44a6d9819ace': 'Career & Financial Guidance',
    '9a5f9651-032e-47f4-863e-a539112e375d': 'Love Psychics',
    'b6ee6b79-d428-4792-917d-0d6bc84f0051': 'Astrology Reading',
    'bcd38088-5cf6-40dd-9e0e-c9f60b53a44d': 'Dream Interpretation',
    'cd359a21-dfd7-4287-9a3a-c93c7d6fbb1b': 'Life Path & Advice',
    'efc2f1e9-b158-48d2-9345-bf43e58bcc1c': 'Life Questions',
    'f269dc59-f8ec-4f12-bbf1-cee4abc9f8e1': 'Fortune Telling',
    'f353dc95-31e9-42b3-801e-99642208011d': 'Horoscopes',
  };

  /// Register list of categories fetched dynamically from API
  static void registerCategories(List<CategoryDto> list) {
    for (final c in list) {
      if (c.id.isNotEmpty && c.name.isNotEmpty && !isGuidOrIdString(c.name)) {
        _knownCategories[c.id.toLowerCase()] = c.name;
      }
    }
  }

  /// Resolve raw category IDs or comma-separated GUIDs to human readable names
  static String? resolveCategoryNames(String? idsOrName) {
    if (idsOrName == null || idsOrName.trim().isEmpty) return null;
    final trimmed = idsOrName.trim();
    if (!isGuidOrIdString(trimmed)) {
      return trimmed;
    }

    final parts = trimmed.split(',').map((s) => s.trim().toLowerCase()).toList();
    final names = <String>[];
    for (final part in parts) {
      final match = _knownCategories[part];
      if (match != null && !names.contains(match)) {
        names.add(match);
      }
    }

    if (names.isNotEmpty) {
      return names.join(', ');
    }
    return null;
  }

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final rawName = json['title'] ?? json['name'] ?? json['categoryName'] ?? 'Category';
    final nameStr = rawName.toString().trim();
    final idStr = json['id']?.toString() ?? json['psychicCategoryId']?.toString() ?? '';
    
    // Register if valid
    if (idStr.isNotEmpty && nameStr.isNotEmpty && !isGuidOrIdString(nameStr)) {
      _knownCategories[idStr.toLowerCase()] = nameStr;
    }

    return CategoryDto(
      id: idStr,
      name: nameStr,
      icon: json['imageUrl'] ?? json['icon'] ?? json['iconUrl'] ?? json['image'],
      description: json['description'],
    );
  }
}
