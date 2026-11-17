class PackageDto {
  final int id;
  final double amount;
  final double promoAmount;
  final double? karmaCredit;
  final String? displayText;
  final String? packageName;
  final double? savingPercent;
  final int? orderBy;
  final bool isPopular;

  PackageDto({
    required this.id,
    required this.amount,
    required this.promoAmount,
    this.karmaCredit,
    this.displayText,
    this.packageName,
    this.savingPercent,
    this.orderBy,
    this.isPopular = false,
  });

  factory PackageDto.fromJson(Map<String, dynamic> json) {
    final amt = (json['amount'] is num)
        ? (json['amount'] as num).toDouble()
        : (double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0);
    final promo = (json['promoAmount'] is num)
        ? (json['promoAmount'] as num).toDouble()
        : (json['bonus'] is num
            ? (json['bonus'] as num).toDouble()
            : (double.tryParse(json['promoAmount']?.toString() ?? json['bonus']?.toString() ?? '0') ?? 0.0));
    final karma = (json['karmaCredit'] is num) ? (json['karmaCredit'] as num).toDouble() : null;
    final saving = (json['savingPercent'] is num) ? (json['savingPercent'] as num).toDouble() : null;

    final idVal = json['id'] is int ? json['id'] as int : (int.tryParse(json['id']?.toString() ?? '0') ?? 0);
    final pop = json['popular'] == true ||
        json['popular']?.toString().toLowerCase() == 'true' ||
        json['popular']?.toString().toLowerCase() == 'popular';

    return PackageDto(
      id: idVal,
      amount: amt,
      promoAmount: promo,
      karmaCredit: karma,
      displayText: json['displayText']?.toString(),
      packageName: json['packageName']?.toString(),
      savingPercent: saving,
      orderBy: json['orderBy'] is int ? json['orderBy'] : int.tryParse(json['orderBy']?.toString() ?? '0'),
      isPopular: pop,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'promoAmount': promoAmount,
        'karmaCredit': karmaCredit,
        'displayText': displayText,
        'packageName': packageName,
        'savingPercent': savingPercent,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PackageDto && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CountryDto {
  final String id;
  final String countryText;
  final String? countryCode;
  final bool isActive;

  CountryDto({
    required this.id,
    required this.countryText,
    this.countryCode,
    this.isActive = true,
  });

  factory CountryDto.fromJson(Map<String, dynamic> json) {
    return CountryDto(
      id: json['id']?.toString() ?? '',
      countryText: json['countryText']?.toString() ?? json['name']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? json['code']?.toString(),
      isActive: json['isActive'] == null ? true : (json['isActive'] == true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'countryText': countryText,
        'countryCode': countryCode,
        'isActive': isActive,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryDto &&
          runtimeType == other.runtimeType &&
          (id == other.id || countryText.toLowerCase() == other.countryText.toLowerCase());

  @override
  int get hashCode => id.hashCode ^ countryText.toLowerCase().hashCode;
}
