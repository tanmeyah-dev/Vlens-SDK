
import 'dart:convert';

class ExtractedUserData {
  final bool? isVerificationProcessCompleted;
  final bool? isDigitalIdentityVerified;
  final String? deviceInfo;
  final User? user;
  final IdFrontData? idFrontData;
  final IdBackData? idBackData;

  ExtractedUserData({
    this.isVerificationProcessCompleted,
    this.isDigitalIdentityVerified,
    this.deviceInfo,
    this.user,
    this.idFrontData,
    this.idBackData,
  });

  factory ExtractedUserData.fromJson(Map<String, dynamic> json) {
    return ExtractedUserData(
      isVerificationProcessCompleted:
          json['isVerificationProcessCompleted'] as bool?,
      isDigitalIdentityVerified: json['isDigitalIdentityVerified'] as bool?,
      deviceInfo: _parseDeviceInfo(json['deviceInfo']),
      user: json['user'] != null
          ? User.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      idFrontData: json['idFrontData'] != null
          ? IdFrontData.fromJson(
              Map<String, dynamic>.from(json['idFrontData'] as Map),
            )
          : null,
      idBackData: json['idBackData'] != null
          ? IdBackData.fromJson(
              Map<String, dynamic>.from(json['idBackData'] as Map),
            )
          : null,
    );
  }

  static String? _parseDeviceInfo(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      try {
        return jsonEncode(value);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }

  factory ExtractedUserData.fromExtractedData(
    var data,
  ) {
    return ExtractedUserData(
      isVerificationProcessCompleted: data.isVerificationProcessCompleted,
      isDigitalIdentityVerified: data.isDigitalIdentityVerified,
      deviceInfo: data.deviceInfo,
      user: data.user == null
          ? null
          : User(
              id: data.user!.id,
              name: data.user!.name,
              surname: data.user!.surname,
              fullName: data.user!.fullName,
              userName: data.user!.userName,
              emailAddress: data.user!.emailAddress,
              phoneNumber: data.user!.phoneNumber,
              idNumber: data.user!.idNumber,
              address: data.user!.address,
            ),
      idFrontData: data.idFrontData == null
          ? null
          : IdFrontData(
              nameEnglish: data.idFrontData!.nameEnglish,
              firstNameEnglish: data.idFrontData!.firstNameEnglish,
              lastNamesEnglish: data.idFrontData!.lastNamesEnglish,
              name: data.idFrontData!.name,
              firstName: data.idFrontData!.firstName,
              lastNames: data.idFrontData!.lastNames,
              govern: data.idFrontData!.govern,
              idKey: data.idFrontData!.idKey,
              dateOfBirth: data.idFrontData!.dateOfBirth,
              address: data.idFrontData!.address,
              address1: data.idFrontData!.address1,
              address2: data.idFrontData!.address2,
              addressEnglish: data.idFrontData!.addressEnglish,
              address1English: data.idFrontData!.address1English,
              address2English: data.idFrontData!.address2English,
              governEnglish: data.idFrontData!.governEnglish,
              city: data.idFrontData!.city,
              district: data.idFrontData!.district,
              idNumber: data.idFrontData!.idNumber,
              gender: data.idFrontData!.gender,
              clientTransactionId: data.idFrontData!.clientTransactionId,
              requestId: data.idFrontData!.requestId,
              transactionId: data.idFrontData!.transactionId,
            ),
      idBackData: data.idBackData == null
          ? null
          : IdBackData(
              maritalStatus: data.idBackData!.maritalStatus,
              job: data.idBackData!.job,
              jobTitle: data.idBackData!.jobTitle,
              religion: data.idBackData!.religion,
              husbandName: data.idBackData!.husbandName,
              releaseDate: data.idBackData!.releaseDate,
              idExpiry: data.idBackData!.idExpiry,
              maritalStatusEnglish: data.idBackData!.maritalStatusEnglish,
              religionEnglish: data.idBackData!.religionEnglish,
              genderEnglish: data.idBackData!.genderEnglish,
              husbandNameEnglish: data.idBackData!.husbandNameEnglish,
              jobEnglish: data.idBackData!.jobEnglish,
              jobTitleEnglish: data.idBackData!.jobTitleEnglish,
              idNumber: data.idBackData!.idNumber,
              gender: data.idBackData!.gender,
              clientTransactionId: data.idBackData!.clientTransactionId,
              requestId: data.idBackData!.requestId,
              transactionId: data.idBackData!.transactionId,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isVerificationProcessCompleted': isVerificationProcessCompleted,
      'isDigitalIdentityVerified': isDigitalIdentityVerified,
      'deviceInfo': deviceInfo,
      'user': user?.toJson(),
      'idFrontData': idFrontData?.toJson(),
      'idBackData': idBackData?.toJson(),
    };
  }
}

class User {
  final int? id;
  final String? name;
  final String? surname;
  final String? fullName;
  final String? userName;
  final String? emailAddress;
  final String? phoneNumber;
  final String? idNumber;
  final String? address;

  User({
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

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['userId'];
    int? id;
    if (rawId is int) {
      id = rawId;
    } else if (rawId != null) {
      id = int.tryParse('$rawId');
    }

    return User(
      id: id,
      name: json['name'] as String?,
      surname: json['surname'] as String?,
      fullName: json['fullName'] as String?,
      userName: (json['userName'] ?? json['username']) as String?,
      emailAddress: (json['emailAddress'] ?? json['email']) as String?,
      phoneNumber: json['phoneNumber'] as String?,
      idNumber: json['idNumber'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'fullName': fullName,
      'userName': userName,
      'emailAddress': emailAddress,
      'phoneNumber': phoneNumber,
      'idNumber': idNumber,
      'address': address,
    };
  }
}

class IdFrontData {
  final String? nameEnglish;
  final String? firstNameEnglish;
  final String? lastNamesEnglish;
  final String? name;
  final String? firstName;
  final String? lastNames;
  final String? govern;
  final String? idKey;
  final DateTime? dateOfBirth;
  final String? address;
  final String? address1;
  final String? address2;
  final String? addressEnglish;
  final String? address1English;
  final String? address2English;
  final String? governEnglish;
  final String? city;
  final String? district;
  final String? idNumber;
  final String? gender;
  final String? clientTransactionId;
  final String? requestId;
  final String? transactionId;

  IdFrontData({
    this.nameEnglish,
    this.firstNameEnglish,
    this.lastNamesEnglish,
    this.name,
    this.firstName,
    this.lastNames,
    this.govern,
    this.idKey,
    this.dateOfBirth,
    this.address,
    this.address1,
    this.address2,
    this.addressEnglish,
    this.address1English,
    this.address2English,
    this.governEnglish,
    this.city,
    this.district,
    this.idNumber,
    this.gender,
    this.clientTransactionId,
    this.requestId,
    this.transactionId,
  });

  factory IdFrontData.fromJson(Map<String, dynamic> json) {
    return IdFrontData(
      nameEnglish: json['name_english'] as String?,
      firstNameEnglish: json['first_name_english'] as String?,
      lastNamesEnglish: json['last_names_english'] as String?,
      name: json['name'] as String?,
      firstName: json['first_name'] as String?,
      lastNames: json['last_names'] as String?,
      govern: json['govern'] as String?,
      idKey: json['idKey'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      address: json['address'] as String?,
      address1: json['address_1'] as String?,
      address2: json['address_2'] as String?,
      addressEnglish: json['address_english'] as String?,
      address1English: json['address_1_english'] as String?,
      address2English: json['address_2_english'] as String?,
      governEnglish: json['govern_english'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      idNumber: json['idNumber'] as String?,
      gender: json['gender'] as String?,
      clientTransactionId: json['client_transaction_id'] as String?,
      requestId: json['request_id'] as String?,
      transactionId: json['transaction_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_english': nameEnglish,
      'first_name_english': firstNameEnglish,
      'last_names_english': lastNamesEnglish,
      'name': name,
      'first_name': firstName,
      'last_names': lastNames,
      'govern': govern,
      'idKey': idKey,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'address_1': address1,
      'address_2': address2,
      'address_english': addressEnglish,
      'address_1_english': address1English,
      'address_2_english': address2English,
      'govern_english': governEnglish,
      'city': city,
      'district': district,
      'idNumber': idNumber,
      'gender': gender,
      'client_transaction_id': clientTransactionId,
      'request_id': requestId,
      'transaction_id': transactionId,
    };
  }
}

class IdBackData {
  final String? maritalStatus;
  final String? job;
  final String? jobTitle;
  final String? religion;
  final String? husbandName;
  final DateTime? releaseDate;
  final DateTime? idExpiry;
  final String? maritalStatusEnglish;
  final String? religionEnglish;
  final String? genderEnglish;
  final String? husbandNameEnglish;
  final String? jobEnglish;
  final String? jobTitleEnglish;
  final String? idNumber;
  final String? gender;
  final String? clientTransactionId;
  final String? requestId;
  final String? transactionId;

  IdBackData({
    this.maritalStatus,
    this.job,
    this.jobTitle,
    this.religion,
    this.husbandName,
    this.releaseDate,
    this.idExpiry,
    this.maritalStatusEnglish,
    this.religionEnglish,
    this.genderEnglish,
    this.husbandNameEnglish,
    this.jobEnglish,
    this.jobTitleEnglish,
    this.idNumber,
    this.gender,
    this.clientTransactionId,
    this.requestId,
    this.transactionId,
  });

  factory IdBackData.fromJson(Map<String, dynamic> json) {
    return IdBackData(
      maritalStatus: _readString(json, const ['maritalStatus', 'marital_status']),
      job: _readString(json, const ['job']),
      jobTitle: _readString(json, const ['jobTitle', 'job_title']),
      religion: _readString(json, const ['religion']),
      husbandName: _readString(json, const ['husbandName', 'husband_name']),
      releaseDate: _readDate(json['releaseDate']),
      idExpiry: _readDate(json['idExpiry'] ?? json['id_expiry']),
      maritalStatusEnglish: _readString(json, const [
        'maritalStatusEnglish',
        'marital_status_english',
        'maritalStatus_english',
      ]),
      religionEnglish: _readString(json, const [
        'religionEnglish',
        'religion_english',
      ]),
      genderEnglish: _readString(json, const [
        'genderEnglish',
        'gender_english',
      ]),
      husbandNameEnglish: _readString(json, const [
        'husbandNameEnglish',
        'husbandName_english',
        'husband_name_english',
      ]),
      jobEnglish: _readString(json, const ['jobEnglish', 'job_english']),
      jobTitleEnglish: _readString(json, const [
        'jobTitleEnglish',
        'job_title_english',
      ]),
      idNumber: _readString(json, const ['idNumber', 'id_number']),
      gender: _readString(json, const ['gender']),
      clientTransactionId: _readString(json, const [
        'clientTransactionId',
        'client_transaction_id',
      ]),
      requestId: _readString(json, const ['requestId', 'request_id']),
      transactionId: _readString(json, const [
        'transactionId',
        'transaction_id',
      ]),
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }

  static DateTime? _readDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'maritalStatus': maritalStatus,
      'job': job,
      'jobTitle': jobTitle,
      'religion': religion,
      'husbandName': husbandName,
      'releaseDate': releaseDate?.toIso8601String(),
      'idExpiry': idExpiry?.toIso8601String(),
      'marital_status_english': maritalStatusEnglish,
      'religion_english': religionEnglish,
      'gender_english': genderEnglish,
      'husbandName_english': husbandNameEnglish,
      'job_english': jobEnglish,
      'job_title_english': jobTitleEnglish,
      'idNumber': idNumber,
      'gender': gender,
      'client_transaction_id': clientTransactionId,
      'request_id': requestId,
      'transaction_id': transactionId,
    };
  }
}
