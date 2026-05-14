class EContractValidateOtpResponse {
  final EContractValidateOtpData? data;
  final int? code;
  final String? message;
  final bool success;

  const EContractValidateOtpResponse({
    this.data,
    this.code,
    this.message,
    required this.success,
  });

  static bool _readBool(dynamic value, {bool ifNull = false}) {
    if (value == null) return ifNull;
    if (value is bool) return value;
    final normalized = value.toString().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return ifNull;
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory EContractValidateOtpResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return EContractValidateOtpResponse(
      data: rawData is Map
          ? EContractValidateOtpData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
      code: _readInt(json['code']),
      message: json['message']?.toString(),
      success: _readBool(json['success'], ifNull: false),
    );
  }
}

class EContractValidateOtpData {
  final String? paymentLink;
  final bool isActive;
  final bool isValidOtpCode;
  final String? requestId;
  final String? contractStorageId;
  final bool needsReValidate;
  final String? errorMessage;
  final String? nextStep;

  const EContractValidateOtpData({
    this.paymentLink,
    required this.isActive,
    required this.isValidOtpCode,
    this.requestId,
    this.contractStorageId,
    required this.needsReValidate,
    this.errorMessage,
    this.nextStep,
  });

  static bool _readBool(dynamic value, {bool ifNull = false}) {
    if (value == null) return ifNull;
    if (value is bool) return value;
    final normalized = value.toString().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return ifNull;
  }

  factory EContractValidateOtpData.fromJson(Map<String, dynamic> json) {
    return EContractValidateOtpData(
      paymentLink: json['paymentLink']?.toString(),
      isActive: _readBool(json['isActive'], ifNull: false),
      isValidOtpCode: _readBool(json['isValidOtpCode'], ifNull: false),
      requestId: json['requestId']?.toString(),
      contractStorageId: json['contractStorageId']?.toString(),
      needsReValidate: _readBool(json['needsReValidate'], ifNull: false),
      errorMessage: json['errorMessage']?.toString(),
      nextStep: json['nextStep']?.toString(),
    );
  }
}
