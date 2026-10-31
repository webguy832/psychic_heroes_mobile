class PackageDto {
  final int id;
  final double amount;
  final double promoAmount;

  PackageDto({
    required this.id,
    required this.amount,
    required this.promoAmount,
  });

  factory PackageDto.fromJson(Map<String, dynamic> json) {
    return PackageDto(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      promoAmount: (json['promoAmount'] ?? json['bonus'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'promoAmount': promoAmount,
      };
}

class CountryDto {
  final int id;
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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      countryText: json['countryText'] ?? json['name'] ?? '',
      countryCode: json['countryCode'] ?? json['code'],
      isActive: json['isActive'] ?? true,
    );
  }
}
