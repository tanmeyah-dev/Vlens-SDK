class RequestFieldsResponse {
  final RequestFieldsData? data;
  final int? code;
  final String? message;
  final bool success;

  RequestFieldsResponse({
    required this.data,
    required this.code,
    required this.message,
    required this.success,
  });

  factory RequestFieldsResponse.fromJson(Map<String, dynamic> json) {
    return RequestFieldsResponse(
      data: json['data'] is Map<String, dynamic>
          ? RequestFieldsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      code: json['code'] is int ? json['code'] as int : null,
      message: json['message']?.toString(),
      success: json['success'] == true,
    );
  }
}

class RequestFieldsData {
  final int? id;
  final String? name;
  final List<RequestFieldItem> requestsFields;

  RequestFieldsData({
    required this.id,
    required this.name,
    required this.requestsFields,
  });

  factory RequestFieldsData.fromJson(Map<String, dynamic> json) {
    final rawFields = json['requestsFields'];
    return RequestFieldsData(
      id: json['id'] is int ? json['id'] as int : null,
      name: json['name']?.toString(),
      requestsFields: rawFields is List
          ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(RequestFieldItem.fromJson)
              .toList()
          : <RequestFieldItem>[],
    );
  }
}

class RequestFieldItem {
  final int order;
  final String key;
  final String displayText;
  final String type;
  final bool visibleToUser;
  final String? value;
  final List<String> availableValues;

  RequestFieldItem({
    required this.order,
    required this.key,
    required this.displayText,
    required this.type,
    required this.visibleToUser,
    required this.value,
    required this.availableValues,
  });

  factory RequestFieldItem.fromJson(Map<String, dynamic> json) {
    final values = (json['availableValues'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        <String>[];
    return RequestFieldItem(
      order: json['order'] is int ? json['order'] as int : 0,
      key: json['key']?.toString() ?? '',
      displayText: json['displayText']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      visibleToUser: json['visibleToUser'] == true,
      value: json['value']?.toString(),
      availableValues: values,
    );
  }
}
