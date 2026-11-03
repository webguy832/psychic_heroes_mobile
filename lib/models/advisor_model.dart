class AdvisorDto {
  final String id;
  final String name;
  final String? profilePhoto;
  final String status; // Online, Busy, Offline
  final double rating;
  final int reviewsCount;
  final double pricePerMinute;
  final String? categoryName;
  final String? bio;

  AdvisorDto({
    required this.id,
    required this.name,
    this.profilePhoto,
    required this.status,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerMinute,
    this.categoryName,
    this.bio,
  });

  factory AdvisorDto.fromJson(Map<String, dynamic> json) {
    return AdvisorDto(
      id: json['id']?.toString() ?? json['advisorId']?.toString() ?? '',
      name: json['displayName'] ?? json['name'] ?? json['fullName'] ?? 'Advisor',
      profilePhoto: json['photo'] ?? json['profileImageURL'] ?? json['profilePhoto'] ?? json['photoUrl'] ?? json['image'],
      status: json['isOnline'] == true
          ? 'Online'
          : (json['isBusy'] == true ? 'Busy' : (json['status']?.toString() == '1' ? 'Online' : 'Offline')),
      rating: (json['rating'] ?? json['averageRating'] ?? 5.0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? json['totalReviews'] ?? 0,
      pricePerMinute: (json['callRatePerMinute'] ?? json['fee'] ?? json['pricePerMinute'] ?? json['feePerMin'] ?? 1.99).toDouble(),
      categoryName: json['categoryName'] ?? json['category'] ?? json['primaryCategory'],
      bio: json['aboutMyServices'] ?? json['briefDescription'] ?? json['bio'] ?? json['aboutMe'],
    );
  }
}
