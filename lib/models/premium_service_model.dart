import 'dart:convert';

/// Represents a Category for Platinum/Premium Services
class PremiumCategoryModel {
  final int id;
  final String title;
  final String? photoUrl;
  final String? advisorLoginId;
  final bool isActive;

  PremiumCategoryModel({
    required this.id,
    required this.title,
    this.photoUrl,
    this.advisorLoginId,
    this.isActive = true,
  });

  factory PremiumCategoryModel.fromJson(Map<String, dynamic> json) {
    return PremiumCategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      advisorLoginId: json['advisorLoginId']?.toString(),
      isActive: json['isActive'] == true || json['isActive'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'photoUrl': photoUrl,
    'advisorLoginId': advisorLoginId,
    'isActive': isActive,
  };
}

/// Represents a Platinum / Premium Service offered by an advisor
class PremiumServiceModel {
  final int id;
  final String advisorLoginId;
  final String title;
  final String? serviceDescription;
  final String? howItWorks;
  final String? optimalFor;
  final String? greetingMessage;
  final String? checkList;
  final double price;
  final int duration;
  final String? youTubeUrl;
  final String? photo1;
  final String? photo2;
  final bool isActive;
  final String? advisorDisplayName;
  final String? advisorPhoto;

  PremiumServiceModel({
    required this.id,
    required this.advisorLoginId,
    required this.title,
    this.serviceDescription,
    this.howItWorks,
    this.optimalFor,
    this.greetingMessage,
    this.checkList,
    this.price = 0.0,
    this.duration = 1,
    this.youTubeUrl,
    this.photo1,
    this.photo2,
    this.isActive = true,
    this.advisorDisplayName,
    this.advisorPhoto,
  });

  factory PremiumServiceModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    int parsedDuration = 1;
    if (json['duration'] != null) {
      parsedDuration = int.tryParse(json['duration'].toString()) ?? 1;
    }

    return PremiumServiceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      advisorLoginId: json['advisorLoginId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      serviceDescription: json['serviceDescription']?.toString(),
      howItWorks: json['howItWorks']?.toString(),
      optimalFor: json['optimalFor']?.toString(),
      greetingMessage: json['greetingMessage']?.toString(),
      checkList: json['checkList']?.toString(),
      price: parsedPrice,
      duration: parsedDuration,
      youTubeUrl: json['youTubeUrl']?.toString(),
      photo1: json['photo1']?.toString(),
      photo2: json['photo2']?.toString(),
      isActive: json['isActive'] == null ? true : (json['isActive'] == true || json['isActive'] == 1),
      advisorDisplayName: json['advisorDisplayName']?.toString() ?? json['advisorName']?.toString(),
      advisorPhoto: json['advisorPhoto']?.toString(),
    );
  }
}

/// Represents eligibility & cost details loaded before placing order
class StartPremiumEligibilityModel {
  final int serviceId;
  final bool noBalance;
  final double totalPrice;
  final double userBalance;
  final double remainingBalance;
  final bool isFirstTime;
  final bool isRequestPending;
  final PremiumServiceModel? premiumService;
  final Map<String, dynamic>? advisorProfile;

  StartPremiumEligibilityModel({
    required this.serviceId,
    this.noBalance = false,
    this.totalPrice = 0.0,
    this.userBalance = 0.0,
    this.remainingBalance = 0.0,
    this.isFirstTime = false,
    this.isRequestPending = false,
    this.premiumService,
    this.advisorProfile,
  });

  factory StartPremiumEligibilityModel.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) => v == null ? 0.0 : (double.tryParse(v.toString()) ?? 0.0);

    PremiumServiceModel? pService;
    if (json['premiumService'] is Map<String, dynamic>) {
      pService = PremiumServiceModel.fromJson(json['premiumService'] as Map<String, dynamic>);
    } else if (json['service'] is Map<String, dynamic>) {
      pService = PremiumServiceModel.fromJson(json['service'] as Map<String, dynamic>);
    }

    return StartPremiumEligibilityModel(
      serviceId: json['serviceId'] is int
          ? json['serviceId']
          : int.tryParse(json['serviceId']?.toString() ?? '0') ?? 0,
      noBalance: json['noBalance'] == true || json['noBalance'] == 1,
      totalPrice: parseD(json['totalPrice']),
      userBalance: parseD(json['userBalance']),
      remainingBalance: parseD(json['remainingBalance'] ?? json['remaingBlance'] ?? json['remaingBalance']),
      isFirstTime: json['isFirstTime'] == true,
      isRequestPending: json['isRequestPending'] == true,
      premiumService: pService,
      advisorProfile: json['advisorProfile'] is Map<String, dynamic>
          ? json['advisorProfile'] as Map<String, dynamic>
          : (json['advisor'] is Map<String, dynamic> ? json['advisor'] as Map<String, dynamic> : null),
    );
  }
}

/// Represents a customer/advisor Premium Order Request item
class PremiumRequestModel {
  final int id;
  final int serviceId;
  final String title;
  final String serviceDescription;
  final String userId;
  final double price;
  final DateTime createdOn;
  final DateTime? completedOn;
  final bool isCompleted;
  final bool isDraft;
  final String status; // Pending, Processing, Completed, Cancelled
  final String customerDisplayName;
  final String customerUserId;
  final String customerPhoto;
  final String advisorDisplayName;
  final String advisorUserId;
  final String advisorPhoto;
  final double advisorRating;

  PremiumRequestModel({
    required this.id,
    this.serviceId = 0,
    required this.title,
    this.serviceDescription = '',
    this.userId = '',
    this.price = 0.0,
    required this.createdOn,
    this.completedOn,
    this.isCompleted = false,
    this.isDraft = false,
    this.status = 'Pending',
    this.customerDisplayName = '',
    this.customerUserId = '',
    this.customerPhoto = '',
    this.advisorDisplayName = '',
    this.advisorUserId = '',
    this.advisorPhoto = '',
    this.advisorRating = 5.0,
  });

  factory PremiumRequestModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    DateTime parsedCreated = DateTime.now();
    if (json['createdOn'] != null) {
      parsedCreated = DateTime.tryParse(json['createdOn'].toString()) ?? DateTime.now();
    }

    DateTime? parsedCompleted;
    if (json['completedOn'] != null) {
      parsedCompleted = DateTime.tryParse(json['completedOn'].toString());
    }

    // Customer info extraction
    String custName = '';
    String custId = '';
    String custPhoto = '';
    if (json['customer'] is Map<String, dynamic>) {
      final cust = json['customer'] as Map<String, dynamic>;
      custName = cust['displayName']?.toString() ?? cust['userName']?.toString() ?? '';
      custId = cust['userId']?.toString() ?? '';
      custPhoto = cust['photo']?.toString() ?? '';
    }

    // Advisor info extraction
    String advName = '';
    String advId = '';
    String advPhoto = '';
    double advRate = 5.0;
    if (json['advisor'] is Map<String, dynamic>) {
      final adv = json['advisor'] as Map<String, dynamic>;
      advName = adv['displayName']?.toString() ?? adv['userName']?.toString() ?? '';
      advId = adv['userId']?.toString() ?? '';
      advPhoto = adv['photo']?.toString() ?? adv['profilePhoto']?.toString() ?? '';
      if (adv['rating'] != null) {
        advRate = double.tryParse(adv['rating'].toString()) ?? 5.0;
      }
    }

    return PremiumRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      serviceId: json['serviceId'] is int
          ? json['serviceId']
          : int.tryParse(json['serviceId']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      serviceDescription: json['serviceDescription']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      price: parsedPrice,
      createdOn: parsedCreated,
      completedOn: parsedCompleted,
      isCompleted: json['isCompleted'] == true,
      isDraft: json['isDraft'] == true,
      status: json['status']?.toString() ?? 'Pending',
      customerDisplayName: custName.isNotEmpty ? custName : (json['customerDisplayName']?.toString() ?? 'Client'),
      customerUserId: custId.isNotEmpty ? custId : (json['customerUserId']?.toString() ?? ''),
      customerPhoto: custPhoto,
      advisorDisplayName: advName.isNotEmpty ? advName : (json['advisorDisplayName']?.toString() ?? 'Advisor'),
      advisorUserId: advId.isNotEmpty ? advId : (json['advisorUserId']?.toString() ?? ''),
      advisorPhoto: advPhoto,
      advisorRating: advRate,
    );
  }
}
