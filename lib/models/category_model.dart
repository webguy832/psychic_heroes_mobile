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

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id']?.toString() ?? json['psychicCategoryId']?.toString() ?? '',
      name: json['title'] ?? json['name'] ?? json['categoryName'] ?? 'Category',
      icon: json['imageUrl'] ?? json['icon'] ?? json['iconUrl'] ?? json['image'],
      description: json['description'],
    );
  }
}
