class RequestTypesResponse {
  final List<RequestTypeItem> data;
  final int totalCount;
  final int returnedCount;
  final int? code;
  final String? message;
  final bool success;

  const RequestTypesResponse({
    required this.data,
    required this.totalCount,
    required this.returnedCount,
    this.code,
    this.message,
    required this.success,
  });

  factory RequestTypesResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final parsedData = <RequestTypeItem>[];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          parsedData.add(RequestTypeItem.fromJson(item));
        } else if (item is Map) {
          parsedData.add(
            RequestTypeItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return RequestTypesResponse(
      data: parsedData,
      totalCount: _parseInt(json['totalCount']) ?? parsedData.length,
      returnedCount: _parseInt(json['returnedCount']) ?? parsedData.length,
      code: _parseInt(json['code']),
      message: json['message']?.toString(),
      success: _parseBool(json['success']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}

class RequestTypeItem {
  final int? id;
  final String? name;
  final int? type;
  final String? typeName;
  final dynamic requestTypes;

  const RequestTypeItem({
    this.id,
    this.name,
    this.type,
    this.typeName,
    this.requestTypes,
  });

  factory RequestTypeItem.fromJson(Map<String, dynamic> json) {
    return RequestTypeItem(
      id: RequestTypesResponse._parseInt(json['id']),
      name: json['name']?.toString(),
      type: RequestTypesResponse._parseInt(json['type']),
      typeName: json['typeName']?.toString(),
      requestTypes: json['requestTypes'],
    );
  }
}
