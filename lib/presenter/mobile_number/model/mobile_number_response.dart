/// Model for the nested data object in CheckExistenceOfEmailOrPhone API response
class CheckExistenceData {
  final bool isEmailExists;
  final bool isPhoneNumberExists;

  CheckExistenceData({
    required this.isEmailExists,
    required this.isPhoneNumberExists,
  });

  factory CheckExistenceData.fromJson(Map<String, dynamic> json) {
    return CheckExistenceData(
      isEmailExists: json["isEmailExists"] ?? false,
      isPhoneNumberExists: json["isPhoneNumberExists"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "isEmailExists": isEmailExists,
      "isPhoneNumberExists": isPhoneNumberExists,
    };
  }
}

/// Model for CheckExistenceOfEmailOrPhone API response
/// Response structure:
/// {
///   "data": {
///     "isEmailExists": false,
///     "isPhoneNumberExists": false
///   },
///   "error_code": null,
///   "error_message": null,
///   "error_descriptions": null
/// }
class MobileNumberResponse {
  final CheckExistenceData? data;
  final String? errorCode;
  final String? errorMessage;
  final String? errorDescriptions;

  MobileNumberResponse({
    this.data,
    this.errorCode,
    this.errorMessage,
    this.errorDescriptions,
  });

  /// Computed property to determine if the request was successful
  /// Success is true when all error fields are null
  bool get success {
    return errorCode == null && errorMessage == null && errorDescriptions == null;
  }

  factory MobileNumberResponse.fromJson(Map<String, dynamic> json) {
    return MobileNumberResponse(
      data: json["data"] != null 
          ? CheckExistenceData.fromJson(json["data"] as Map<String, dynamic>)
          : null,
      errorCode: json["error_code"]?.toString(),
      errorMessage: json["error_message"]?.toString(),
      errorDescriptions: json["error_descriptions"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "data": data?.toJson(),
      "error_code": errorCode,
      "error_message": errorMessage,
      "error_descriptions": errorDescriptions,
    };
  }
}
