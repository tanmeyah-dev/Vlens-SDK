/// Model for the nested data object in identity check API response.
class CheckExistenceData {
  final bool phoneNumberExists;
  final bool emailExists;

  CheckExistenceData({
    required this.phoneNumberExists,
    required this.emailExists,
  });

  factory CheckExistenceData.fromJson(Map<String, dynamic> json) {
    final rawPhoneNumberExists = json["phoneNumberExists"];
    final rawEmailExists = json["emailExists"];

    return CheckExistenceData(
      phoneNumberExists: rawPhoneNumberExists is bool
          ? rawPhoneNumberExists
          : rawPhoneNumberExists?.toString().toLowerCase() == 'true',
      emailExists: rawEmailExists is bool
          ? rawEmailExists
          : rawEmailExists?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "phoneNumberExists": phoneNumberExists,
      "emailExists": emailExists,
    };
  }
}

/// Model for identity check API response.
class MobileNumberResponse {
  final CheckExistenceData? data;
  final int? code;
  final String? message;
  final bool success;

  MobileNumberResponse({
    this.data,
    this.code,
    this.message,
    required this.success,
  });

  factory MobileNumberResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json["success"];
    final parsedSuccess = rawSuccess is bool
        ? rawSuccess
        : rawSuccess?.toString().toLowerCase() == 'true';

    final rawCode = json["code"];
    final parsedCode = rawCode is int ? rawCode : int.tryParse('$rawCode');

    return MobileNumberResponse(
      data: json["data"] != null
          ? CheckExistenceData.fromJson(json["data"] as Map<String, dynamic>)
          : null,
      code: parsedCode,
      message: json["message"]?.toString(),
      success: parsedSuccess,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "data": data?.toJson(),
      "code": code,
      "message": message,
      "success": success,
    };
  }
}
