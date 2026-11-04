class AdvisorDto {
  final String id;
  final String name;
  final String? profilePhoto;
  final String status; // Online, Busy, Offline
  final double rating;
  final int reviewsCount;
  final double fee;
  final double offeredFee;
  final double pricePerMinute;
  final String? categoryName;
  final String? tagline;
  final String? bio;
  final String? badgeLabel;
  final bool featured;
  final bool isFirstTime;
  final bool doFreeMins;
  final String? videoUrl;
  final bool hasVideo;
  final bool hasCall;
  final bool hasChat;

  AdvisorDto({
    required this.id,
    required this.name,
    this.profilePhoto,
    required this.status,
    required this.rating,
    required this.reviewsCount,
    required this.fee,
    required this.offeredFee,
    required this.pricePerMinute,
    this.categoryName,
    this.tagline,
    this.bio,
    this.badgeLabel,
    this.featured = false,
    this.isFirstTime = false,
    this.doFreeMins = false,
    this.videoUrl,
    this.hasVideo = false,
    this.hasCall = false,
    this.hasChat = false,
  });

  factory AdvisorDto.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviewsCount'] ?? json['totalReviews'] ?? json['initReviewCount'] ?? 0;
    final int reviews = (rawReviews is num) ? rawReviews.toInt() : int.tryParse(rawReviews.toString()) ?? 0;
    
    final rawRating = json['rating'] ?? json['averageRating'] ?? 0;
    final double ratingVal = (rawRating is num) ? rawRating.toDouble() : double.tryParse(rawRating.toString()) ?? 0.0;

    final idStr = json['id']?.toString() ?? json['advisorId']?.toString() ?? '';

    final rawFee = json['callRatePerMinute'] ?? json['fee'] ?? json['pricePerMinute'] ?? 0;
    final double feeVal = (rawFee is num) ? rawFee.toDouble() : double.tryParse(rawFee.toString()) ?? 0.0;

    final rawOfferedFee = json['offeredFee'] ?? 0;
    final double offeredFeeVal = (rawOfferedFee is num) ? rawOfferedFee.toDouble() : double.tryParse(rawOfferedFee.toString()) ?? 0.0;

    final double effectivePrice = (offeredFeeVal > 0) ? offeredFeeVal : feeVal;

    final bool isFeatured = json['featured'] == true || (json['ranking'] != null && json['ranking'] > 0);
    final bool isFirstTime = json['isFirstTime'] == 1 || json['isFirstTime'] == true;

    String? badge;
    if (isFeatured) {
      badge = 'Featured';
    } else if (isFirstTime) {
      badge = 'New';
    } else if (reviews >= 10 && ratingVal >= 4.5) {
      badge = 'Top Rated';
    }

    final commStyles = json['commStyles']?.toString() ?? '';
    final video = json['videoUrl']?.toString();
    final hasVideo = (video != null && video.isNotEmpty) || commStyles.contains('3') || commStyles.contains('2');
    final hasCall = commStyles.contains('2') || commStyles.contains('3') || json['phone1'] != null;
    final hasChat = commStyles.contains('1') || json['acceptTextReading'] == true;

    final catName = json['categoryName'] ?? json['category'] ?? json['primaryCategory'];
    final title = json['advisorTitle'] ?? json['specialities'] ?? json['specialization'] ?? json['briefDescription'] ?? catName;

    return AdvisorDto(
      id: idStr,
      name: json['displayName'] ?? json['name'] ?? json['fullName'] ?? 'Advisor',
      profilePhoto: json['photo'] ?? json['profileImageURL'] ?? json['profilePhoto'] ?? json['photoUrl'] ?? json['image'],
      status: json['isOnline'] == true
          ? 'Online'
          : (json['isBusy'] == true ? 'Busy' : (json['status']?.toString() == '1' ? 'Online' : 'Offline')),
      rating: ratingVal,
      reviewsCount: reviews,
      fee: feeVal,
      offeredFee: offeredFeeVal,
      pricePerMinute: effectivePrice,
      categoryName: catName,
      tagline: title != null ? title.toString().replaceAll('\n', ' ').trim() : null,
      bio: json['aboutMyServices'] ?? json['briefDescription'] ?? json['bio'] ?? json['aboutMe'],
      badgeLabel: badge,
      featured: isFeatured,
      isFirstTime: isFirstTime,
      doFreeMins: json['doFreeMins'] == true || json['freeMins'] != null,
      videoUrl: video,
      hasVideo: hasVideo,
      hasCall: hasCall,
      hasChat: hasChat,
    );
  }
}


