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
    this.tierLevel = "Member",
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
      id: data['id']?.toString() ?? data['userId']?.toString() ?? data['Id']?.toString() ?? '',
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
      tierLevel: data['tierLevel']?.toString() ?? data['TierLevel']?.toString() ?? "Member",
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

class UserWalletSummary {
  final double balance;
  final double minBalance;
  final double ratePerMin;
  final String updatedAt;

  UserWalletSummary({
    required this.balance,
    required this.minBalance,
    required this.ratePerMin,
    required this.updatedAt,
  });

  factory UserWalletSummary.fromJson(Map<String, dynamic> json) {
    final rawBal = json['availableBalance'] ?? json['balance'] ?? json['Balance'] ?? json['totalEarnings'] ?? 0;
    final rawMin = json['minBalance'] ?? json['MinBalance'] ?? json['minsBalance'] ?? json['MinsBalance'] ?? 0;
    final rawRate = json['ratePerMin'] ?? json['RatePerMin'] ?? 0;

    return UserWalletSummary(
      balance: (rawBal is num) ? rawBal.toDouble() : double.tryParse(rawBal.toString()) ?? 0.0,
      minBalance: (rawMin is num) ? rawMin.toDouble() : double.tryParse(rawMin.toString()) ?? 0.0,
      ratePerMin: (rawRate is num) ? rawRate.toDouble() : double.tryParse(rawRate.toString()) ?? 0.0,
      updatedAt: json['updatedAt']?.toString() ?? json['UpdatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'minBalance': minBalance,
        'ratePerMin': ratePerMin,
        'updatedAt': updatedAt,
      };
}

class TransactionHistoryDto {
  final String id;
  final String transactionId;
  final String transType;
  final String description;
  final double credit;
  final double debit;
  final double balance;
  final double minsBalance;
  final String createdAt;
  final String? invoiceId;
  final String? externalTransactionId;

  // Backward compatibility getters
  String get title => description.isNotEmpty ? description : 'Transaction';
  String get transactionType => transType;
  String get type => credit > 0 ? 'credit' : 'debit';
  double get amount => credit > 0 ? credit : debit;
  String get date => createdAt;
  String get status => 'Completed';

  TransactionHistoryDto({
    required this.id,
    required this.transactionId,
    required this.transType,
    required this.description,
    required this.credit,
    required this.debit,
    required this.balance,
    required this.minsBalance,
    required this.createdAt,
    this.invoiceId,
    this.externalTransactionId,
  });

  factory TransactionHistoryDto.fromJson(Map<String, dynamic> json) {
    final rawCredit = json['credit'] ?? json['Credit'] ?? 0;
    final rawDebit = json['debit'] ?? json['Debit'] ?? 0;
    final rawBalance = json['balance'] ?? json['Balance'] ?? 0;
    final rawMins = json['minsBalance'] ?? json['MinsBalance'] ?? 0;

    String desc = json['description']?.toString() ??
        json['Description']?.toString() ??
        json['title']?.toString() ??
        '';
    if (desc.isEmpty && json['screenName'] != null) {
      desc = "Reading session with ${json['screenName']}";
    }
    if (desc.isEmpty) {
      desc = "Transaction";
    }

    final rawDate = json['createdAt']?.toString() ??
        json['CreatedAt']?.toString() ??
        json['requestDate']?.toString() ??
        json['RequestDate']?.toString() ??
        json['date']?.toString() ??
        '';

    return TransactionHistoryDto(
      id: json['transactionId']?.toString() ?? json['transId']?.toString() ?? json['TransId']?.toString() ?? json['id']?.toString() ?? 'TXN-1',
      transactionId: json['transactionId']?.toString() ?? json['transId']?.toString() ?? json['TransId']?.toString() ?? '',
      transType: json['transType']?.toString() ?? json['TransType']?.toString() ?? '',
      description: desc,
      credit: (rawCredit is num) ? rawCredit.toDouble() : double.tryParse(rawCredit.toString()) ?? 0.0,
      debit: (rawDebit is num) ? rawDebit.toDouble() : double.tryParse(rawDebit.toString()) ?? 0.0,
      balance: (rawBalance is num) ? rawBalance.toDouble() : double.tryParse(rawBalance.toString()) ?? 0.0,
      minsBalance: (rawMins is num) ? rawMins.toDouble() : double.tryParse(rawMins.toString()) ?? 0.0,
      createdAt: rawDate,
      invoiceId: json['invoiceId']?.toString() ?? json['InvoiceId']?.toString(),
      externalTransactionId: json['externalTransactionId']?.toString() ?? json['transactionId2']?.toString() ?? json['TransactionId2']?.toString(),
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
    final typeId = json['requestType'] ?? json['RequestType'] ?? json['transType'] ?? 1;
    String typeLabel = 'Live Chat';
    String typeKey = 'chat';
    if (typeId == 2) {
      typeLabel = 'Video Call';
      typeKey = 'video';
    } else if (typeId == 3) {
      typeLabel = 'Voice Call';
      typeKey = 'voice';
    } else if (typeId == 4) {
      typeLabel = 'Text Reading';
      typeKey = 'text';
    }

    final dur = json['duration'] ?? json['Duration'];
    final durationStr = dur is num && dur > 0
        ? (dur >= 60 ? '${(dur / 60).ceil()} mins' : '$dur mins')
        : (json['duration']?.toString() ?? '10 mins');

    final participant = json['advisorDisplayName'] ??
        json['AdvisorDisplayName'] ??
        json['advisorName'] ??
        json['AdvisorName'] ??
        json['clientDisplayName'] ??
        json['ClientDisplayName'] ??
        json['clientName'] ??
        json['ClientName'] ??
        json['screenName'] ??
        json['ScreenName'] ??
        'User';

    final rawCost = json['chargedAmount'] ??
        json['ChargedAmount'] ??
        json['advisorFee'] ??
        json['AdvisorFee'] ??
        json['credit'] ??
        json['Credit'] ??
        json['cost'] ??
        0;
    final costVal = (rawCost is num) ? rawCost.toDouble() : double.tryParse(rawCost.toString()) ?? 0.0;

    final dateVal = json['requestOn']?.toString().split('T').first ??
        json['RequestOn']?.toString().split('T').first ??
        json['requestDate']?.toString().split('T').first ??
        json['RequestDate']?.toString().split('T').first ??
        json['createdAt']?.toString().split('T').first ??
        json['CreatedAt']?.toString().split('T').first ??
        json['date']?.toString() ??
        'Recent';

    final summaryVal = json['summaryPreview'] ??
        json['SummaryPreview'] ??
        json['summary'] ??
        json['description'] ??
        json['Description'] ??
        'Completed psychic reading session';

    return ReadingHistoryItem(
      id: json['requestId']?.toString() ?? json['RequestId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '$typeLabel Session',
      advisorName: participant,
      type: json['type'] ?? typeLabel,
      typeKey: json['typeKey'] ?? typeKey,
      duration: durationStr,
      date: dateVal,
      cost: costVal,
      rating: ((json['rating'] ?? json['Rating'] ?? 5) as num).toInt(),
      summary: summaryVal,
      profilePhoto: json['profilePhoto'] ?? json['ProfilePhoto'],
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
