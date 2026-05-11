class RequestCurrentResponse {
  final RequestCurrentData? data;
  final int? code;
  final String? message;
  final bool success;

  const RequestCurrentResponse({
    required this.data,
    required this.code,
    required this.message,
    required this.success,
  });

  factory RequestCurrentResponse.fromJson(Map<String, dynamic> json) {
    return RequestCurrentResponse(
      data: json['data'] is Map<String, dynamic>
          ? RequestCurrentData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      code: json['code'] is int ? json['code'] as int : null,
      message: json['message']?.toString(),
      success: json['success'] == true,
    );
  }
}

class RequestCurrentData {
  final dynamic id;
  final List<RequestCurrentDocument> documents;

  const RequestCurrentData({
    required this.id,
    required this.documents,
  });

  factory RequestCurrentData.fromJson(Map<String, dynamic> json) {
    final rawDocuments = json['documents'];
    return RequestCurrentData(
      id: json['id'],
      documents: rawDocuments is List
          ? rawDocuments
              .whereType<Map<String, dynamic>>()
              .map(RequestCurrentDocument.fromJson)
              .toList()
          : <RequestCurrentDocument>[],
    );
  }
}

class RequestCurrentDocument {
  final int order;
  final String title;
  final String? content;
  final String? signature;
  final bool isHtml;

  const RequestCurrentDocument({
    required this.order,
    required this.title,
    required this.content,
    required this.signature,
    required this.isHtml,
  });

  factory RequestCurrentDocument.fromJson(Map<String, dynamic> json) {
    return RequestCurrentDocument(
      order: json['order'] is int ? json['order'] as int : 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
      signature: json['signature']?.toString(),
      isHtml: json['isHtml'] == true,
    );
  }
}
