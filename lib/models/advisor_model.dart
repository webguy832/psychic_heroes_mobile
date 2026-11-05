class AdvisorDto {
  final String id;
  final String? loginId;
  final String? advisorId;
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

  // Full advisor profile fields (matching web_angular_2025)
  final String? advisorTitle;
  final String? aboutMyServices;
  final String? experienceAndQualifications;
  final String? specialities;
  final String? language;
  final String? commStyles;
  final double? callRatePerMinute;
  final double? videoRatePerMinute;
  final double? textReadingFee;
  final double? speedupTextReadingFee;
  final bool isOnline;
  final bool isBusy;
  final bool isOnVacation;
  final bool isAcceptCoupon;
  final int? freeMins;

  AdvisorDto({
    required this.id,
    this.loginId,
    this.advisorId,
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
    this.advisorTitle,
    this.aboutMyServices,
    this.experienceAndQualifications,
    this.specialities,
    this.language,
    this.commStyles,
    this.callRatePerMinute,
    this.videoRatePerMinute,
    this.textReadingFee,
    this.speedupTextReadingFee,
    this.isOnline = false,
    this.isBusy = false,
    this.isOnVacation = false,
    this.isAcceptCoupon = false,
    this.freeMins,
  });

  /// Check whether advisor supports communication style (Matching Angular hasCommStyle)
  /// 1 = Chat, 2 = Video, 3 = Audio/Call, 4 = Text Reading
  bool hasCommStyle(int style) {
    if (commStyles == null || commStyles!.trim().isEmpty) {
      if (style == 1) return hasChat;
      if (style == 2) return hasVideo;
      if (style == 3) return hasCall;
      if (style == 4) return (textReadingFee != null && textReadingFee! > 0);
      return false;
    }
    final parts = commStyles!.split(',').map((s) => s.trim()).toList();
    return parts.contains(style.toString());
  }

  /// List of specialities parsed from comma-separated string
  List<String> get specialitiesList {
    if (specialities == null || specialities!.trim().isEmpty) return [];
    return specialities!
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Stripped clean version of About My Services
  String get cleanAbout {
    final text = aboutMyServices ?? bio ?? '';
    return _stripHtml(text);
  }

  /// Stripped clean version of Experience & Qualifications
  String get cleanExperience {
    final text = experienceAndQualifications ?? '';
    return _stripHtml(text);
  }

  static String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    String text = htmlString
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return text.trim();
  }

  AdvisorDto copyWith({
    String? id,
    String? loginId,
    String? advisorId,
    String? name,
    String? profilePhoto,
    String? status,
    double? rating,
    int? reviewsCount,
    double? fee,
    double? offeredFee,
    double? pricePerMinute,
    String? categoryName,
    String? tagline,
    String? bio,
    String? badgeLabel,
    bool? featured,
    bool? isFirstTime,
    bool? doFreeMins,
    String? videoUrl,
    bool? hasVideo,
    bool? hasCall,
    bool? hasChat,
    String? advisorTitle,
    String? aboutMyServices,
    String? experienceAndQualifications,
    String? specialities,
    String? language,
    String? commStyles,
    double? callRatePerMinute,
    double? videoRatePerMinute,
    double? textReadingFee,
    double? speedupTextReadingFee,
    bool? isOnline,
    bool? isBusy,
    bool? isOnVacation,
    bool? isAcceptCoupon,
    int? freeMins,
  }) {
    return AdvisorDto(
      id: id ?? this.id,
      loginId: loginId ?? this.loginId,
      advisorId: advisorId ?? this.advisorId,
      name: name ?? this.name,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      fee: fee ?? this.fee,
      offeredFee: offeredFee ?? this.offeredFee,
      pricePerMinute: pricePerMinute ?? this.pricePerMinute,
      categoryName: categoryName ?? this.categoryName,
      tagline: tagline ?? this.tagline,
      bio: bio ?? this.bio,
      badgeLabel: badgeLabel ?? this.badgeLabel,
      featured: featured ?? this.featured,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      doFreeMins: doFreeMins ?? this.doFreeMins,
      videoUrl: videoUrl ?? this.videoUrl,
      hasVideo: hasVideo ?? this.hasVideo,
      hasCall: hasCall ?? this.hasCall,
      hasChat: hasChat ?? this.hasChat,
      advisorTitle: advisorTitle ?? this.advisorTitle,
      aboutMyServices: aboutMyServices ?? this.aboutMyServices,
      experienceAndQualifications: experienceAndQualifications ?? this.experienceAndQualifications,
      specialities: specialities ?? this.specialities,
      language: language ?? this.language,
      commStyles: commStyles ?? this.commStyles,
      callRatePerMinute: callRatePerMinute ?? this.callRatePerMinute,
      videoRatePerMinute: videoRatePerMinute ?? this.videoRatePerMinute,
      textReadingFee: textReadingFee ?? this.textReadingFee,
      speedupTextReadingFee: speedupTextReadingFee ?? this.speedupTextReadingFee,
      isOnline: isOnline ?? this.isOnline,
      isBusy: isBusy ?? this.isBusy,
      isOnVacation: isOnVacation ?? this.isOnVacation,
      isAcceptCoupon: isAcceptCoupon ?? this.isAcceptCoupon,
      freeMins: freeMins ?? this.freeMins,
    );
  }

  factory AdvisorDto.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviewsCount'] ?? json['totalReviews'] ?? json['initReviewCount'] ?? 0;
    final int reviews = (rawReviews is num) ? rawReviews.toInt() : int.tryParse(rawReviews.toString()) ?? 0;
    
    final rawRating = json['rating'] ?? json['averageRating'] ?? 0;
    final double ratingVal = (rawRating is num) ? rawRating.toDouble() : double.tryParse(rawRating.toString()) ?? 0.0;

    final idStr = json['id']?.toString() ?? json['advisorId']?.toString() ?? '';
    final loginIdStr = json['loginId']?.toString();
    final advisorIdStr = json['advisorId']?.toString() ?? idStr;

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

    final commStylesStr = json['commStyles']?.toString() ?? '';
    final video = json['videoUrl']?.toString();
    final hasVideo = (video != null && video.isNotEmpty) || commStylesStr.contains('3') || commStylesStr.contains('2');
    final hasCall = commStylesStr.contains('2') || commStylesStr.contains('3') || json['phone1'] != null;
    final hasChat = commStylesStr.contains('1') || json['acceptTextReading'] == true;

    final catName = json['categoryName'] ?? json['category'] ?? json['primaryCategory'];
    final title = json['advisorTitle'] ?? json['specialities'] ?? json['specialization'] ?? json['briefDescription'] ?? catName;

    final bool online = json['isOnline'] == true || json['status']?.toString() == '1';
    final bool busy = json['isBusy'] == true;
    final bool onVacation = json['isOnVacation'] == true;

    final double? callRate = (json['callRatePerMinute'] is num) ? (json['callRatePerMinute'] as num).toDouble() : null;
    final double? videoRate = (json['videoRatePerMinute'] is num) ? (json['videoRatePerMinute'] as num).toDouble() : null;
    final double? textFee = (json['textReadingFee'] is num) ? (json['textReadingFee'] as num).toDouble() : null;
    final double? speedupFee = (json['speedupTextReadingFee'] is num) ? (json['speedupTextReadingFee'] as num).toDouble() : null;

    final int? freeM = (json['freeMins'] is num) ? (json['freeMins'] as num).toInt() : int.tryParse(json['freeMins']?.toString() ?? '');

    return AdvisorDto(
      id: idStr,
      loginId: loginIdStr,
      advisorId: advisorIdStr,
      name: json['displayName'] ?? json['name'] ?? json['fullName'] ?? 'Advisor',
      profilePhoto: json['photo'] ?? json['profileImageURL'] ?? json['profilePhoto'] ?? json['photoUrl'] ?? json['image'],
      status: online ? 'Online' : (busy ? 'Busy' : 'Offline'),
      rating: ratingVal,
      reviewsCount: reviews,
      fee: feeVal,
      offeredFee: offeredFeeVal,
      pricePerMinute: effectivePrice,
      categoryName: catName?.toString(),
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
      advisorTitle: json['advisorTitle']?.toString(),
      aboutMyServices: json['aboutMyServices']?.toString(),
      experienceAndQualifications: json['experienceAndQualifications']?.toString(),
      specialities: json['specialities']?.toString(),
      language: json['language']?.toString(),
      commStyles: commStylesStr,
      callRatePerMinute: callRate,
      videoRatePerMinute: videoRate,
      textReadingFee: textFee,
      speedupTextReadingFee: speedupFee,
      isOnline: online,
      isBusy: busy,
      isOnVacation: onVacation,
      isAcceptCoupon: json['isAcceptCoupon'] == true,
      freeMins: freeM,
    );
  }
}

/// Advisor Review representation from api/Web/GetAdvisorReviews
class AdvisorReviewDto {
  final String? id;
  final String? description;
  final double rating;
  final DateTime? createDate;
  final String reviewerName;
  final String? reviewerPhoto;

  AdvisorReviewDto({
    this.id,
    this.description,
    required this.rating,
    this.createDate,
    required this.reviewerName,
    this.reviewerPhoto,
  });

  factory AdvisorReviewDto.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'] ?? 5;
    final ratingVal = (rawRating is num) ? rawRating.toDouble() : double.tryParse(rawRating.toString()) ?? 5.0;

    String? reviewer = json['reviewBy']?.toString();
    String? photo;
    if (json['reviewByUser'] is Map) {
      reviewer = json['reviewByUser']['displayName']?.toString() ?? reviewer;
      photo = json['reviewByUser']['profileImageURL']?.toString();
    }
    if (reviewer == null || reviewer.trim().isEmpty) {
      reviewer = json['clientName']?.toString();
    }
    if (reviewer == null || reviewer.trim().isEmpty) {
      reviewer = 'Anonymous';
    }

    DateTime? parsedDate;
    if (json['createDate'] != null) {
      parsedDate = DateTime.tryParse(json['createDate'].toString());
    }

    return AdvisorReviewDto(
      id: json['id']?.toString(),
      description: json['description']?.toString(),
      rating: ratingVal,
      createDate: parsedDate,
      reviewerName: reviewer,
      reviewerPhoto: photo,
    );
  }
}

/// Session Eligibility DTO from api/user/checkSessionEligibilty (matching web_angular_2025)
class SessionEligibilityDto {
  final bool isOnline;
  final bool isBusy;
  final bool isOnVacation;
  final bool hasBalance;
  final int validSessionMinutes;
  final int freeMinutes;
  final double userBalance;
  final double advisorOriginalFees;
  final double advisorFees;

  SessionEligibilityDto({
    required this.isOnline,
    required this.isBusy,
    required this.isOnVacation,
    required this.hasBalance,
    required this.validSessionMinutes,
    required this.freeMinutes,
    required this.userBalance,
    required this.advisorOriginalFees,
    required this.advisorFees,
  });

  factory SessionEligibilityDto.fromJson(Map<String, dynamic> json) {
    return SessionEligibilityDto(
      isOnline: json['isOnline'] == true,
      isBusy: json['isBusy'] == true,
      isOnVacation: json['isOnVacation'] == true,
      hasBalance: json['hasBalance'] == true,
      validSessionMinutes: (json['validSessionMinutes'] is num)
          ? (json['validSessionMinutes'] as num).toInt()
          : int.tryParse(json['validSessionMinutes']?.toString() ?? '0') ?? 0,
      freeMinutes: (json['freeMinutes'] is num)
          ? (json['freeMinutes'] as num).toInt()
          : int.tryParse(json['freeMinutes']?.toString() ?? '0') ?? 0,
      userBalance: (json['userBalance'] is num)
          ? (json['userBalance'] as num).toDouble()
          : double.tryParse(json['userBalance']?.toString() ?? '0') ?? 0.0,
      advisorOriginalFees: (json['advisorOriginalFees'] is num)
          ? (json['advisorOriginalFees'] as num).toDouble()
          : double.tryParse(json['advisorOriginalFees']?.toString() ?? '0') ?? 0.0,
      advisorFees: (json['advisorFees'] is num)
          ? (json['advisorFees'] as num).toDouble()
          : double.tryParse(json['advisorFees']?.toString() ?? '0') ?? 0.0,
    );
  }
}
