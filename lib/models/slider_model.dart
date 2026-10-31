class SliderDto {
  final int id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? targetUrl;

  SliderDto({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.targetUrl,
  });

  factory SliderDto.fromJson(Map<String, dynamic> json) {
    return SliderDto(
      id: json['id'] ?? json['bannerId'] ?? 0,
      title: json['title'] ?? json['bannerTitle'] ?? 'Special Offer',
      subtitle: json['subtitle'] ?? json['description'],
      imageUrl: json['imageUrl'] ?? json['bannerImage'] ?? '',
      targetUrl: json['targetUrl'] ?? json['link'],
    );
  }
}
