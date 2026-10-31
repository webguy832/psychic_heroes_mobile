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
  final int karmaPoints;
  final String? dateOfBirth;
  final String? gender;
  final String? zodiacSign;
  final String? country;
  final String? role;

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
    this.karmaPoints = 0,
    this.dateOfBirth,
    this.gender,
    this.zodiacSign,
    this.country,
    this.role,
  });

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    if (screenName != null && screenName!.isNotEmpty) return screenName!;
    if (firstName != null && firstName!.isNotEmpty) {
      return '$firstName ${lastName ?? ''}'.trim();
    }
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@')[0];
    }
    return "Valued Member";
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fn = json['fullName'] ?? json['userName'] ?? json['name'];
    final sn = json['screenName'] ?? json['displayName'];
    final fName = json['firstName'];
    final lName = json['lastName'];

    return UserModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '1',
      email: json['email'] ?? '',
      fullName: fn ?? (fName != null ? '$fName ${lName ?? ''}'.trim() : sn),
      screenName: sn ?? fn,
      firstName: fName,
      lastName: lName,
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      profilePhoto: json['profilePhoto'] ?? json['photoUrl'] ?? json['image'],
      walletBalance: (json['walletBalance'] ?? json['balance'] ?? 0).toDouble(),
      karmaPoints: json['karmaPoints'] ?? json['karma'] ?? 0,
      dateOfBirth: json['dateOfBirth'] ?? json['dob'],
      gender: json['gender'],
      zodiacSign: json['zodiacSign'] ?? json['zodiac'],
      country: json['country'],
      role: json['role'] ?? json['userRole'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName ?? displayName,
        'screenName': screenName ?? displayName,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'profilePhoto': profilePhoto,
        'walletBalance': walletBalance,
        'karmaPoints': karmaPoints,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'zodiacSign': zodiacSign,
        'country': country,
        'role': role,
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
    int? karmaPoints,
    String? dateOfBirth,
    String? gender,
    String? zodiacSign,
    String? country,
    String? role,
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
      karmaPoints: karmaPoints ?? this.karmaPoints,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      country: country ?? this.country,
      role: role ?? this.role,
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
