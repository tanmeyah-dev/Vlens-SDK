/// API: POST .../digital/identity/create-user
class CreateUserUser {
  final int? id;
  final String? name;
  final String? surname;
  final String? fullName;
  final String? userName;
  final String? emailAddress;
  final String? phoneNumber;
  final String? idNumber;
  final String? address;

  const CreateUserUser({
    this.id,
    this.name,
    this.surname,
    this.fullName,
    this.userName,
    this.emailAddress,
    this.phoneNumber,
    this.idNumber,
    this.address,
  });

  static int? _parseId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory CreateUserUser.fromJson(Map<String, dynamic> json) {
    return CreateUserUser(
      id: _parseId(json['id']),
      name: json['name']?.toString(),
      surname: json['surname']?.toString(),
      fullName: json['fullName']?.toString(),
      userName: json['userName']?.toString(),
      emailAddress: json['emailAddress']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      idNumber: json['idNumber']?.toString(),
      address: json['address']?.toString(),
    );
  }
}

class CreateUserData {
  final bool? isPhoneNumberConfirmed;
  final bool? isEmailConfirmed;
  final String? accessToken;
  final String? refreshToken;
  final CreateUserUser? user;

  const CreateUserData({
    this.isPhoneNumberConfirmed,
    this.isEmailConfirmed,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return null;
  }

  factory CreateUserData.fromJson(Map<String, dynamic> json) {
    return CreateUserData(
      isPhoneNumberConfirmed: _parseBool(json['isPhoneNumberConfirmed']),
      isEmailConfirmed: _parseBool(json['isEmailConfirmed']),
      accessToken: json['accessToken']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      user: json['user'] is Map<String, dynamic>
          ? CreateUserUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Treat as success when API omits `success` but returns tokens (common vlens shape).
  bool get hasAuthTokens =>
      (accessToken ?? '').trim().isNotEmpty ||
      (refreshToken ?? '').trim().isNotEmpty;
}

class CreateUserResponse {
  final int? code;
  final String? message;
  final bool success;
  final CreateUserData? data;

  const CreateUserResponse({
    this.code,
    this.message,
    required this.success,
    this.data,
  });

  static int? _parseCode(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory CreateUserResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json['success'];
    final success = rawSuccess is bool
        ? rawSuccess
        : rawSuccess == null
            // Vlens shape: success omitted; treat as ok when data has tokens and no error_code.
            ? (json['error_code'] == null &&
                json['data'] is Map &&
                ((json['data'] as Map)['accessToken']?.toString().trim().isNotEmpty ==
                        true ||
                    (json['data'] as Map)['refreshToken']
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true))
            : rawSuccess.toString().toLowerCase() == 'true';

    return CreateUserResponse(
      code: _parseCode(json['code'] ?? json['error_code']),
      message: json['message']?.toString() ??
          json['error_message']?.toString() ??
          json['errorMessage']?.toString(),
      success: success,
      data: json['data'] is Map<String, dynamic>
          ? CreateUserData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Use after HTTP 200: some payloads omit `success` but include tokens under `data`.
  bool isBusinessSuccess({required int httpStatus}) {
    if (httpStatus != 200) return false;
    if (success) return true;
    return data?.hasAuthTokens ?? false;
  }
}
