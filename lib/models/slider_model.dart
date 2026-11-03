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
    String img = json['imageUrl'] ?? json['bannerImage'] ?? '';
    if (img.isEmpty && json['bannerPath'] != null && json['bannerPath'].toString().isNotEmpty) {
      final banner = json['bannerPath'].toString();
      img = banner.startsWith('http')
          ? banner
          : 'https://psychicheroes.online/Content/Psychic/images/banners/$banner';
    }
    return SliderDto(
      id: json['id'] ?? json['bannerId'] ?? 0,
      title: json['title'] ?? json['bannerTitle'] ?? 'Special Offer',
      subtitle: json['subtitle'] ?? json['description'],
      imageUrl: img,
      targetUrl: json['targetUrl'] ?? json['link'],
    );
  }
}
