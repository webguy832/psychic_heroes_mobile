class TextReadingModel {
  final int id;
  final String userId;
  final String advisorId;
  final String? advisorProfileId;
  final String customerName;
  final DateTime? dob;
  final String gender;
  final String generalDescription;
  final String? specQuestion;
  final String? photoUrl;
  final bool readingType;
  final double price;
  final bool isDraft;
  final bool isCompleted;
  final DateTime? createdOn;
  final DateTime? submittedOn;
  final DateTime? completedOn;
  final String? finalReadingText;
  final String? status;
  final String? advisorName;
  final String? advisorImage;
  final String? screenName;

  TextReadingModel({
    required this.id,
    required this.userId,
    required this.advisorId,
    this.advisorProfileId,
    required this.customerName,
    this.dob,
    required this.gender,
    required this.generalDescription,
    this.specQuestion,
    this.photoUrl,
    this.readingType = false,
    required this.price,
    this.isDraft = true,
    this.isCompleted = false,
    this.createdOn,
    this.submittedOn,
    this.completedOn,
    this.finalReadingText,
    this.status,
    this.advisorName,
    this.advisorImage,
    this.screenName,
  });

  factory TextReadingModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic dateVal) {
      if (dateVal == null) return null;
      if (dateVal is DateTime) return dateVal;
      if (dateVal is String && dateVal.isNotEmpty) {
        try {
          return DateTime.parse(dateVal);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    final idVal = json['id'] ?? json['Id'] ?? json['requestId'] ?? json['RequestId'] ?? json['readingId'] ?? 0;
    final id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? 0;

    final priceVal = json['price'] ?? json['Price'] ?? json['fee'] ?? json['Fee'] ?? 0.0;
    final price = priceVal is num ? priceVal.toDouble() : double.tryParse(priceVal.toString()) ?? 0.0;

    return TextReadingModel(
      id: id,
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      advisorId: (json['advisorId'] ?? json['AdvisorId'] ?? '').toString(),
      advisorProfileId: json['advisorProfileId']?.toString() ?? json['AdvisorProfileId']?.toString(),
      customerName: (json['customerName'] ?? json['CustomerName'] ?? json['clientName'] ?? json['ClientName'] ?? '').toString(),
      dob: parseDate(json['dob'] ?? json['Dob']),
      gender: (json['gender'] ?? json['Gender'] ?? 'prefer_not_say').toString(),
      generalDescription: (json['generalDescription'] ?? json['GeneralDescription'] ?? json['description'] ?? json['Description'] ?? '').toString(),
      specQuestion: (json['specQuestion'] ?? json['SpecQuestion'] ?? json['question'] ?? json['Question'])?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['PhotoUrl']?.toString(),
      readingType: json['readingType'] == true || json['ReadingType'] == true,
      price: price,
      isDraft: json['isDraft'] == true || json['IsDraft'] == true,
      isCompleted: json['isCompleted'] == true || json['IsCompleted'] == true,
      createdOn: parseDate(json['createdOn'] ?? json['CreatedOn'] ?? json['createdON']),
      submittedOn: parseDate(json['submittedOn'] ?? json['SubmittedOn']),
      completedOn: parseDate(json['completedOn'] ?? json['CompletedOn']),
      finalReadingText: json['finalReadingText']?.toString() ?? json['FinalReadingText']?.toString() ?? json['finalTextReading']?.toString(),
      status: json['status']?.toString() ?? json['Status']?.toString(),
      advisorName: json['advisorName']?.toString() ?? json['AdvisorName']?.toString(),
      advisorImage: json['advisorImage']?.toString() ?? json['AdvisorImage']?.toString(),
      screenName: json['screenName']?.toString() ?? json['ScreenName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'advisorId': advisorId,
      'advisorProfileId': advisorProfileId,
      'customerName': customerName,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'generalDescription': generalDescription,
      'specQuestion': specQuestion,
      'photoUrl': photoUrl,
      'readingType': readingType,
      'price': price,
      'isDraft': isDraft,
      'isCompleted': isCompleted,
      'createdOn': createdOn?.toIso8601String(),
      'submittedOn': submittedOn?.toIso8601String(),
      'completedOn': completedOn?.toIso8601String(),
      'finalReadingText': finalReadingText,
      'status': status,
    };
  }
}

class ServiceMessageModel {
  final int? messageId;
  final String messageText;
  final String? userId;
  final String? userName;
  final int entityId;
  final int entityTypeId;
  final DateTime createDate;
  final String? clientId;
  final String? advisorLoginId;
  final bool? isAdvisor;

  ServiceMessageModel({
    this.messageId,
    required this.messageText,
    this.userId,
    this.userName,
    required this.entityId,
    this.entityTypeId = 2,
    required this.createDate,
    this.clientId,
    this.advisorLoginId,
    this.isAdvisor,
  });

  factory ServiceMessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateVal) {
      if (dateVal == null) return DateTime.now();
      if (dateVal is DateTime) return dateVal;
      if (dateVal is String && dateVal.isNotEmpty) {
        try {
          return DateTime.parse(dateVal);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    final msgIdVal = json['messageId'] ?? json['MessageId'];
    final msgId = msgIdVal is int ? msgIdVal : int.tryParse(msgIdVal?.toString() ?? '');

    final entIdVal = json['entityId'] ?? json['EntityId'] ?? 0;
    final entId = entIdVal is int ? entIdVal : int.tryParse(entIdVal.toString()) ?? 0;

    final entTypeVal = json['entityTypeId'] ?? json['EntityTypeId'] ?? 2;
    final entType = entTypeVal is int ? entTypeVal : int.tryParse(entTypeVal.toString()) ?? 2;

    bool? isAdv;
    if (json.containsKey('isAdvisor') && json['isAdvisor'] != null) {
      isAdv = json['isAdvisor'] == true;
    } else if (json.containsKey('IsAdvisor') && json['IsAdvisor'] != null) {
      isAdv = json['IsAdvisor'] == true;
    }

    return ServiceMessageModel(
      messageId: msgId,
      messageText: (json['messageText'] ?? json['MessageText'] ?? '').toString(),
      userId: json['userId']?.toString() ?? json['UserId']?.toString(),
      userName: json['userName']?.toString() ?? json['UserName']?.toString(),
      entityId: entId,
      entityTypeId: entType,
      createDate: parseDate(json['createDate'] ?? json['CreateDate']),
      clientId: json['clientId']?.toString() ?? json['ClientId']?.toString(),
      advisorLoginId: json['advisorLoginId']?.toString() ?? json['AdvisorLoginId']?.toString(),
      isAdvisor: isAdv,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (messageId != null) 'MessageId': messageId,
      'MessageText': messageText,
      if (userId != null) 'UserId': userId,
      if (userName != null) 'UserName': userName,
      'EntityId': entityId,
      'EntityTypeId': entityTypeId,
      'CreateDate': createDate.toIso8601String(),
      if (clientId != null) 'ClientId': clientId,
      if (advisorLoginId != null) 'AdvisorLoginId': advisorLoginId,
      if (isAdvisor != null) 'IsAdvisor': isAdvisor,
    };
  }
}
