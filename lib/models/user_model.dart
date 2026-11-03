class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? screenName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profilePhoto;
  final double walletBalance;
  final int freeMinutes;
  final int karmaPoints;
  final int streakCount;
  final String tierLevel;
  final String? dateOfBirth;
  final String? gender;
  final String? zodiacSign;
  final String? country;
  final String? role;
  final String? addressStreet;
  final String? addressCity;
  final String? addressState;
  final String? addressZip;
  final String? addressCountry;
  final String? addressPhone;
  final String? userDescription;
  final String? affiliateLink;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.screenName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profilePhoto,
    this.walletBalance = 0.0,
    this.freeMinutes = 0,
    this.karmaPoints = 0,
    this.streakCount = 1,
    this.tierLevel = "Mystic Member",
    this.dateOfBirth,
    this.gender,
    this.zodiacSign,
    this.country,
    this.role,
    this.addressStreet,
    this.addressCity,
    this.addressState,
    this.addressZip,
    this.addressCountry,
    this.addressPhone,
    this.userDescription,
    this.affiliateLink,
  });

  String get displayName {
    if (screenName != null && screenName!.trim().isNotEmpty) return screenName!.trim();
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!.trim();
    if (firstName != null && firstName!.trim().isNotEmpty) {
      return '$firstName ${lastName ?? ''}'.trim();
    }
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@')[0];
    }
    return "Member";
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final fn = data['fullName'] ?? data['userName'] ?? data['name'];
    final sn = data['screenName'] ?? data['ScreenName'] ?? data['displayName'];
    final fName = data['firstName'] ?? data['FirstName'];
    final lName = data['lastName'] ?? data['LastName'];

    // Address extraction (handles flat or nested address from Angular)
    final addr = data['address'] is Map ? data['address'] as Map<String, dynamic> : {};
    final street = data['addressStreet'] ?? data['address_Street'] ?? data['AddressStreet'] ?? addr['street'];
    final city = data['addressCity'] ?? data['address_City'] ?? data['AddressCity'] ?? addr['city'];
    final state = data['addressState'] ?? data['address_State'] ?? data['AddressState'] ?? addr['state'];
    final zip = data['addressZip'] ?? data['address_Zip'] ?? data['AddressZip'] ?? addr['zip'];
    final country = data['addressCountry'] ?? data['address_Country'] ?? data['AddressCountry'] ?? data['country'] ?? addr['country'];
    final phone = data['phoneNumber'] ?? data['phone'] ?? data['contact'] ?? data['address_Phone'] ?? data['AddressPhone'];

    return UserModel(
      id: data['id']?.toString() ?? data['userId']?.toString() ?? data['Id']?.toString() ?? '8843249c-cf72-427b-bef7-6549199f2643',
      email: data['email'] ?? data['Email'] ?? '',
      fullName: fn ?? (fName != null ? '$fName ${lName ?? ''}'.trim() : sn),
      screenName: sn ?? fn,
      firstName: fName,
      lastName: lName,
      phoneNumber: phone,
      profilePhoto: data['profilePhoto'] ?? data['photoUrl'] ?? data['imageUrl'] ?? data['image'] ?? data['Photo'],
      walletBalance: (data['walletBalance'] ?? data['balance'] ?? data['WalletBalance'] ?? 0).toDouble(),
      freeMinutes: (data['freeMinutes'] ?? data['minsBalance'] ?? data['MinsBalance'] ?? 0) is num 
          ? (data['freeMinutes'] ?? data['minsBalance'] ?? data['MinsBalance'] ?? 0).toInt() 
          : 0,
      karmaPoints: (data['karmaPoints'] ?? data['karma'] ?? data['totalPoints'] ?? data['pointsBalance'] ?? data['KarmaPoints'] ?? 0) is num
          ? (data['karmaPoints'] ?? data['karma'] ?? data['totalPoints'] ?? data['pointsBalance'] ?? data['KarmaPoints'] ?? 0).toInt()
          : 0,
      streakCount: (data['currentStreak'] ?? data['streakCount'] ?? data['streak'] ?? 1) is num
          ? (data['currentStreak'] ?? data['streakCount'] ?? data['streak'] ?? 1).toInt()
          : 1,
      tierLevel: data['tierLevel']?.toString() ?? "Mystic Member",
      dateOfBirth: data['dateOfBirth'] ?? data['dob'] ?? data['DateOfBirth'],
      gender: data['gender'] ?? data['Gender'],
      zodiacSign: data['zodiacSign'] ?? data['zodiac'] ?? data['ZodiacSign'],
      country: country?.toString(),
      role: data['role'] ?? data['userRole'] ?? data['Role'],
      addressStreet: street?.toString(),
      addressCity: city?.toString(),
      addressState: state?.toString(),
      addressZip: zip?.toString(),
      addressCountry: country?.toString(),
      addressPhone: phone?.toString(),
      userDescription: data['userDescription'] ?? data['UserDescription'] ?? data['bio'],
      affiliateLink: data['affiliateLink'] ?? data['ReferralLink'] ?? data['referLink'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': id,
        'email': email,
        'fullName': fullName ?? displayName,
        'screenName': screenName ?? displayName,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'profilePhoto': profilePhoto,
        'walletBalance': walletBalance,
        'freeMinutes': freeMinutes,
        'karmaPoints': karmaPoints,
        'currentStreak': streakCount,
        'tierLevel': tierLevel,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'zodiacSign': zodiacSign,
        'country': country,
        'role': role,
        'addressStreet': addressStreet,
        'addressCity': addressCity,
        'addressState': addressState,
        'addressZip': addressZip,
        'addressCountry': addressCountry,
        'addressPhone': addressPhone,
        'userDescription': userDescription,
        'affiliateLink': affiliateLink,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? screenName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profilePhoto,
    double? walletBalance,
    int? freeMinutes,
    int? karmaPoints,
    int? streakCount,
    String? tierLevel,
    String? dateOfBirth,
    String? gender,
    String? zodiacSign,
    String? country,
    String? role,
    String? addressStreet,
    String? addressCity,
    String? addressState,
    String? addressZip,
    String? addressCountry,
    String? addressPhone,
    String? userDescription,
    String? affiliateLink,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      screenName: screenName ?? this.screenName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      walletBalance: walletBalance ?? this.walletBalance,
      freeMinutes: freeMinutes ?? this.freeMinutes,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      streakCount: streakCount ?? this.streakCount,
      tierLevel: tierLevel ?? this.tierLevel,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      country: country ?? this.country,
      role: role ?? this.role,
      addressStreet: addressStreet ?? this.addressStreet,
      addressCity: addressCity ?? this.addressCity,
      addressState: addressState ?? this.addressState,
      addressZip: addressZip ?? this.addressZip,
      addressCountry: addressCountry ?? this.addressCountry,
      addressPhone: addressPhone ?? this.addressPhone,
      userDescription: userDescription ?? this.userDescription,
      affiliateLink: affiliateLink ?? this.affiliateLink,
    );
  }
}

class TransactionHistoryDto {
  final String id;
  final String transactionId;
  final String title;
  final String description;
  final String transactionType;
  final String type;
  final double amount;
  final double credit;
  final double debit;
  final double balance;
  final double minsBalance;
  final String status;
  final String createdAt;
  final String date;

  TransactionHistoryDto({
    required this.id,
    required this.transactionId,
    required this.title,
    required this.description,
    required this.transactionType,
    required this.type,
    required this.amount,
    required this.credit,
    required this.debit,
    required this.balance,
    required this.minsBalance,
    required this.status,
    required this.createdAt,
    required this.date,
  });

  factory TransactionHistoryDto.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryDto(
      id: json['id']?.toString() ?? json['transactionId']?.toString() ?? 'TXN-1',
      transactionId: json['transactionId']?.toString() ?? json['transId']?.toString() ?? '',
      title: json['title'] ?? json['description'] ?? 'Transaction',
      description: json['description'] ?? json['title'] ?? '',
      transactionType: json['transactionType'] ?? (json['type'] == 'credit' ? 'Credit' : 'Debit'),
      type: json['type'] ?? 'debit',
      amount: (json['amount'] ?? json['debit'] ?? json['credit'] ?? 0).toDouble(),
      credit: (json['credit'] ?? 0).toDouble(),
      debit: (json['debit'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      minsBalance: (json['minsBalance'] ?? 0).toDouble(),
      status: json['status'] ?? 'Completed',
      createdAt: json['createdAt'] ?? '',
      date: json['date'] ?? json['createdAt'] ?? '',
    );
  }
}

class ReadingHistoryItem {
  final String id;
  final String title;
  final String advisorName;
  final String type;
  final String typeKey;
  final String duration;
  final String date;
  final double cost;
  final int rating;
  final String summary;
  final String? profilePhoto;

  ReadingHistoryItem({
    required this.id,
    required this.title,
    required this.advisorName,
    required this.type,
    required this.typeKey,
    required this.duration,
    required this.date,
    required this.cost,
    this.rating = 5,
    required this.summary,
    this.profilePhoto,
  });

  factory ReadingHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryItem(
      id: json['id']?.toString() ?? 'REQ-1',
      title: json['title'] ?? 'Reading Session',
      advisorName: json['advisorName'] ?? 'Psychic Advisor',
      type: json['type'] ?? 'Live Chat',
      typeKey: json['typeKey'] ?? 'chat',
      duration: json['duration'] ?? '10 mins',
      date: json['date'] ?? 'Recent',
      cost: (json['cost'] ?? 0).toDouble(),
      rating: json['rating'] ?? 5,
      summary: json['summary'] ?? '',
      profilePhoto: json['profilePhoto'],
    );
  }
}

class BillingAddressDto {
  final int? billingId;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? email;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  final String? countryCode;
  final String postalCode;
  final String? phone;
  final bool isDefault;

  BillingAddressDto({
    this.billingId,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.email,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    this.countryCode,
    required this.postalCode,
    this.phone,
    this.isDefault = true,
  });

  factory BillingAddressDto.fromJson(Map<String, dynamic> json) {
    return BillingAddressDto(
      billingId: json['billingId'] ?? json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      dateOfBirth: json['dateOfBirth'],
      email: json['email'],
      addressLine1: json['address1'] ?? json['addressLine1'] ?? '',
      addressLine2: json['address2'] ?? json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country']?.toString() ?? '',
      countryCode: json['countryCode']?.toString(),
      postalCode: json['postalCode'] ?? json['zipCode'] ?? '',
      phone: json['phone'],
      isDefault: json['isDefault'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'billingId': billingId ?? 0,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'email': email,
        'address1': addressLine1,
        'address2': addressLine2,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'phone': phone,
        'isDefault': isDefault,
        'country': country,
        'countryCode': countryCode ?? country,
      };
}
