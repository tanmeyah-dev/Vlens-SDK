import '../../../utils/api_response_envelope.dart';

/// Response for `POST .../digital/identity/phone/verify-otp`.
///
/// Success envelope:
/// `{ "code": 0, "message": "...", "success": true, "data": { ... } }`
///
/// Failure envelope (wrong OTP — HTTP 417, stay on screen):
/// `{ "code": 417, "message": "OTP code is wrong...", "success": false }`
class StepVerifyPhoneResponse {
  final int? code;
  final String? message;
  final bool? success;
  final String? phoneNumberOtpRequestId;
  final String? transactionId;
  final int? phoneOtpExpireInSeconds;
  final bool? isPhoneNumberConfirmed;
  final String? errorCode;
  final String? errorMessage;
  final String? errorDescriptions;
  final Map<String, dynamic>? data;

  const StepVerifyPhoneResponse({
    this.code,
    this.message,
    this.success,
    this.phoneNumberOtpRequestId,
    this.transactionId,
    this.phoneOtpExpireInSeconds,
    this.isPhoneNumberConfirmed,
    this.errorCode,
    this.errorMessage,
    this.errorDescriptions,
    this.data,
  });

  /// Whether OTP verification succeeded and navigation may continue.
  bool get isVerified {
    if (success != null) return success == true;
    if (errorCode != null && errorCode!.trim().isNotEmpty) return false;
    return isPhoneNumberConfirmed == true;
  }

  /// Backward-compatible alias used by existing call sites.
  bool get successComputed => isVerified;

  /// User-facing error text from the API envelope.
  String get userMessage {
    final fromMessage = message?.trim();
    if (fromMessage != null && fromMessage.isNotEmpty) return fromMessage;

    final fromError = errorMessage?.trim();
    if (fromError != null && fromError.isNotEmpty) return fromError;

    final fromDescriptions = errorDescriptions?.trim();
    if (fromDescriptions != null && fromDescriptions.isNotEmpty) {
      return fromDescriptions;
    }

    return 'فشل في التحقق من رقم الموبايل. يرجى التحقق من الكود المدخل';
  }

  factory StepVerifyPhoneResponse.fromJson(Map<String, dynamic> json) {
    String? readString(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value != null) {
          final parsed = value.toString().trim();
          if (parsed.isNotEmpty && parsed.toLowerCase() != 'null') {
            return parsed;
          }
        }
      }
      return null;
    }

    String? phoneNumberOtpRequestId = readString(json, const [
      'phoneNumberOtpRequestId',
      'phone_number_otp_request_id',
      'otpRequestId',
      'requestId',
    ]);
    String? transactionId = readString(json, const [
      'transactionId',
      'transaction_id',
      'transactionID',
      'trxId',
    ]);
    bool? isPhoneNumberConfirmed;
    int? phoneOtpExpireInSeconds;

    if (json['isPhoneNumberConfirmed'] != null) {
      final value = json['isPhoneNumberConfirmed'];
      if (value is bool) {
        isPhoneNumberConfirmed = value;
      } else if (value is String) {
        isPhoneNumberConfirmed = value.toLowerCase() == 'true' || value == '1';
      } else if (value is int) {
        isPhoneNumberConfirmed = value == 1;
      }
    }

    final nestedCandidates = <Map<String, dynamic>>[];
    if (json['data'] is Map<String, dynamic>) {
      nestedCandidates.add(json['data'] as Map<String, dynamic>);
    }
    if (json['result'] is Map<String, dynamic>) {
      nestedCandidates.add(json['result'] as Map<String, dynamic>);
    }
    if (json['payload'] is Map<String, dynamic>) {
      nestedCandidates.add(json['payload'] as Map<String, dynamic>);
    }

    for (final dataMap in nestedCandidates) {
      phoneNumberOtpRequestId ??= readString(dataMap, const [
        'phoneNumberOtpRequestId',
        'phone_number_otp_request_id',
        'otpRequestId',
        'requestId',
      ]);
      transactionId ??= readString(dataMap, const [
        'transactionId',
        'transaction_id',
        'transactionID',
        'trxId',
      ]);

      if (isPhoneNumberConfirmed == null &&
          dataMap['isPhoneNumberConfirmed'] != null) {
        final value = dataMap['isPhoneNumberConfirmed'];
        if (value is bool) {
          isPhoneNumberConfirmed = value;
        } else if (value is String) {
          isPhoneNumberConfirmed =
              value.toLowerCase() == 'true' || value == '1';
        } else if (value is int) {
          isPhoneNumberConfirmed = value == 1;
        }
      }

      if (phoneOtpExpireInSeconds == null &&
          dataMap['phoneOtpExpireInSeconds'] != null) {
        final value = dataMap['phoneOtpExpireInSeconds'];
        if (value is int) {
          phoneOtpExpireInSeconds = value;
        } else {
          phoneOtpExpireInSeconds = int.tryParse(value.toString());
        }
      }
    }

    return StepVerifyPhoneResponse(
      code: ApiResponseEnvelope.parseCode(json),
      message: ApiResponseEnvelope.parseMessage(json),
      success: ApiResponseEnvelope.parseExplicitSuccess(json),
      phoneNumberOtpRequestId: phoneNumberOtpRequestId,
      transactionId: transactionId,
      phoneOtpExpireInSeconds: phoneOtpExpireInSeconds,
      isPhoneNumberConfirmed: isPhoneNumberConfirmed,
      errorCode: json['error_code']?.toString(),
      errorMessage: json['error_message']?.toString(),
      errorDescriptions: json['error_descriptions']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'success': success,
      'phoneNumberOtpRequestId': phoneNumberOtpRequestId,
      'transactionId': transactionId,
      'phoneOtpExpireInSeconds': phoneOtpExpireInSeconds,
      'isPhoneNumberConfirmed': isPhoneNumberConfirmed,
      'error_code': errorCode,
      'error_message': errorMessage,
      'error_descriptions': errorDescriptions,
      'data': data,
    };
  }
}
