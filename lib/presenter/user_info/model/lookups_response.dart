/// Single lookup option: `{ "id": "...", "name": "..." }`.
class LookupItem {
  final String id;
  final String name;

  const LookupItem({
    required this.id,
    required this.name,
  });

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

/// Job option: `{ "codeId": "...", "nameAr": "...", "nameEn": "..." }`.
class JobItem {
  final String codeId;
  final String nameAr;
  final String? nameEn;

  const JobItem({
    required this.codeId,
    required this.nameAr,
    this.nameEn,
  });

  factory JobItem.fromJson(Map<String, dynamic> json) {
    return JobItem(
      codeId: json['codeId']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codeId': codeId,
      'nameAr': nameAr,
      'nameEn': nameEn,
    };
  }
}

/// Village under a city: `{ "id": 1, "nameAr": "...", "nameEn": null }`.
class LocationVillage {
  final int id;
  final String nameAr;
  final String? nameEn;

  const LocationVillage({
    required this.id,
    required this.nameAr,
    this.nameEn,
  });

  factory LocationVillage.fromJson(Map<String, dynamic> json) {
    return LocationVillage(
      id: _asInt(json['id']),
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
    };
  }
}

/// City under a governorate, with nested villages.
class LocationCity {
  final int id;
  final String nameAr;
  final String? nameEn;
  final List<LocationVillage> villages;

  const LocationCity({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.villages = const [],
  });

  factory LocationCity.fromJson(Map<String, dynamic> json) {
    return LocationCity(
      id: _asInt(json['id']),
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString(),
      villages: _parseMappedList(json['villages'], LocationVillage.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'villages': villages.map((e) => e.toJson()).toList(),
    };
  }
}

/// Governorate with nested cities.
class LocationGovernorate {
  final int id;
  final String nameAr;
  final String? nameEn;
  final List<LocationCity> cities;

  const LocationGovernorate({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.cities = const [],
  });

  factory LocationGovernorate.fromJson(Map<String, dynamic> json) {
    return LocationGovernorate(
      id: _asInt(json['id']),
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString(),
      cities: _parseMappedList(json['cities'], LocationCity.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'cities': cities.map((e) => e.toJson()).toList(),
    };
  }
}

/// Named lookup lists inside `data.lookups`.
class Lookups {
  final List<LookupItem> cifQualificationId;
  final List<LookupItem> cifReligion;
  final List<LookupItem> cifLicenseType;
  final List<LookupItem> cifGender;
  final List<LookupItem> phone;
  final List<LookupItem> cifSocialStatus;
  final List<LookupItem> cifHealthStatus;
  final List<LookupItem> risk;
  final List<LookupItem> cifNationCode;
  final List<LookupItem> cifGrants;

  const Lookups({
    this.cifQualificationId = const [],
    this.cifReligion = const [],
    this.cifLicenseType = const [],
    this.cifGender = const [],
    this.phone = const [],
    this.cifSocialStatus = const [],
    this.cifHealthStatus = const [],
    this.risk = const [],
    this.cifNationCode = const [],
    this.cifGrants = const [],
  });

  static List<LookupItem> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => LookupItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  factory Lookups.fromJson(Map<String, dynamic> json) {
    return Lookups(
      cifQualificationId: _parseList(json['CIF_QUALIFICATION_ID']),
      cifReligion: _parseList(json['CIF_RELIGION']),
      cifLicenseType: _parseList(json['CIF_LICENSE_TYPE']),
      cifGender: _parseList(json['CIF_GENDER']),
      phone: _parseList(json['PHONE']),
      cifSocialStatus: _parseList(json['CIF_SOCIAL_STATUS']),
      cifHealthStatus: _parseList(json['CIF_HEALTH_STATUS']),
      risk: _parseList(json['RISK']),
      cifNationCode: _parseList(json['CIF_NATION_CODE']),
      cifGrants: _parseList(json['CIF_GRANTS']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CIF_QUALIFICATION_ID':
          cifQualificationId.map((e) => e.toJson()).toList(),
      'CIF_RELIGION': cifReligion.map((e) => e.toJson()).toList(),
      'CIF_LICENSE_TYPE': cifLicenseType.map((e) => e.toJson()).toList(),
      'CIF_GENDER': cifGender.map((e) => e.toJson()).toList(),
      'PHONE': phone.map((e) => e.toJson()).toList(),
      'CIF_SOCIAL_STATUS': cifSocialStatus.map((e) => e.toJson()).toList(),
      'CIF_HEALTH_STATUS': cifHealthStatus.map((e) => e.toJson()).toList(),
      'RISK': risk.map((e) => e.toJson()).toList(),
      'CIF_NATION_CODE': cifNationCode.map((e) => e.toJson()).toList(),
      'CIF_GRANTS': cifGrants.map((e) => e.toJson()).toList(),
    };
  }
}

/// `data` payload: lookups + jobs + locations.
class LookupsData {
  final Lookups lookups;
  final List<JobItem> jobs;
  final List<LocationGovernorate> locations;

  const LookupsData({
    required this.lookups,
    this.jobs = const [],
    this.locations = const [],
  });

  factory LookupsData.fromJson(Map<String, dynamic> json) {
    final raw = json['lookups'];
    return LookupsData(
      lookups: raw is Map
          ? Lookups.fromJson(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            )
          : const Lookups(),
      jobs: _parseMappedList(json['jobs'], JobItem.fromJson),
      locations: _parseMappedList(json['locations'], LocationGovernorate.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lookups': lookups.toJson(),
      'jobs': jobs.map((e) => e.toJson()).toList(),
      'locations': locations.map((e) => e.toJson()).toList(),
    };
  }
}

/// API envelope for lookups: `data` + `code` + `message` + `success`.
class LookupsResponse {
  final LookupsData? data;
  final int? code;
  final String? message;
  final bool success;

  const LookupsResponse({
    this.data,
    this.code,
    this.message,
    required this.success,
  });

  factory LookupsResponse.fromJson(Map<String, dynamic> json) {
    final rawCode = json['code'];
    final code = rawCode is int
        ? rawCode
        : rawCode is num
            ? rawCode.toInt()
            : int.tryParse('$rawCode');

    final rawSuccess = json['success'];
    final success = rawSuccess is bool
        ? rawSuccess
        : rawSuccess?.toString().toLowerCase() == 'true';

    LookupsData? data;
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      data = LookupsData.fromJson(rawData);
    } else if (rawData is Map) {
      data = LookupsData.fromJson(
        rawData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return LookupsResponse(
      data: data,
      code: code,
      message: json['message']?.toString(),
      success: success,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.toJson(),
      'code': code,
      'message': message,
      'success': success,
    };
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

List<T> _parseMappedList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (item) => fromJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        ),
      )
      .toList();
}
