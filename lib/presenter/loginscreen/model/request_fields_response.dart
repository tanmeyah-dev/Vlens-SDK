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

/// Single row inside [RequestFieldsData.requestsFieldsWithGroupTitles].
class RequestFieldsGroupedSection {
  final String? title;
  final List<RequestFieldItem> requestsFields;

  RequestFieldsGroupedSection({
    required this.title,
    required this.requestsFields,
  });

  factory RequestFieldsGroupedSection.fromJson(Map<String, dynamic> json) {
    final raw = json['requestsFields'];
    return RequestFieldsGroupedSection(
      title: json['title']?.toString(),
      requestsFields: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(RequestFieldItem.fromJson)
              .toList()
          : <RequestFieldItem>[],
    );
  }
}

/// Optional item for selects / radio groups when API sends structured choices.
class RequestFieldAvailableValueItem {
  final int? id;
  final String name;
  final List<dynamic> relatedQuestions;

  RequestFieldAvailableValueItem({
    required this.id,
    required this.name,
    required this.relatedQuestions,
  });

  factory RequestFieldAvailableValueItem.fromJson(Map<String, dynamic> json) {
    final rq = json['relatedQuestions'];
    return RequestFieldAvailableValueItem(
      id: json['id'] is int ? json['id'] as int : null,
      name: json['name']?.toString() ?? '',
      relatedQuestions: rq is List ? rq : const [],
    );
  }
}

class RequestFieldsData {
  final int? id;
  final String? name;
  final List<RequestFieldItem> requestsFields;
  final List<RequestFieldsGroupedSection> requestsFieldsWithGroupTitles;

  final dynamic groupTitles;
  final dynamic groupArTitles;

  final String? content;
  final String? signature;
  final String? smsTemplate;
  final String? confirmationMessage;
  final String? coverPage;
  final String? generalTC;
  final String? technicalTC;
  final String? contractEmailBody;
  final String? financialTC;
  final dynamic signers;

  final bool isLocalized;
  final bool hasCustomPayment;
  final bool hasPromissoryNote;
  final dynamic promissoryNote;

  final int? type;
  final int? parentId;
  final String? parentName;
  final int? minimumRequiredSignatories;

  RequestFieldsData({
    required this.id,
    required this.name,
    required this.requestsFields,
    required this.requestsFieldsWithGroupTitles,
    this.groupTitles,
    this.groupArTitles,
    this.content,
    this.signature,
    this.smsTemplate,
    this.confirmationMessage,
    this.coverPage,
    this.generalTC,
    this.technicalTC,
    this.contractEmailBody,
    this.financialTC,
    this.signers,
    this.isLocalized = false,
    this.hasCustomPayment = false,
    this.hasPromissoryNote = false,
    this.promissoryNote,
    this.type,
    this.parentId,
    this.parentName,
    this.minimumRequiredSignatories,
  });

  factory RequestFieldsData.fromJson(Map<String, dynamic> json) {
    final rawFields = json['requestsFields'];
    final rawGrouped = json['requestsFieldsWithGroupTitles'];

    return RequestFieldsData(
      id: json['id'] is int ? json['id'] as int : null,
      name: json['name']?.toString(),
      requestsFields: rawFields is List
          ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(RequestFieldItem.fromJson)
              .toList()
          : <RequestFieldItem>[],
      requestsFieldsWithGroupTitles: rawGrouped is List
          ? rawGrouped
              .whereType<Map<String, dynamic>>()
              .map(RequestFieldsGroupedSection.fromJson)
              .toList()
          : <RequestFieldsGroupedSection>[],
      groupTitles: json['groupTitles'],
      groupArTitles: json['groupArTitles'],
      content: json['content']?.toString(),
      signature: json['signature']?.toString(),
      smsTemplate: json['smsTemplate']?.toString(),
      confirmationMessage: json['confirmationMessage']?.toString(),
      coverPage: json['coverPage']?.toString(),
      generalTC: json['generalTC']?.toString(),
      technicalTC: json['technicalTC']?.toString(),
      contractEmailBody: json['contractEmailBody']?.toString(),
      financialTC: json['financialTC']?.toString(),
      signers: json['signers'],
      isLocalized: json['isLocalized'] == true,
      hasCustomPayment: json['hasCustomPayment'] == true,
      hasPromissoryNote: json['hasPromissoryNote'] == true,
      promissoryNote: json['promissoryNote'],
      type: json['type'] is int ? json['type'] as int : null,
      parentId: json['parentId'] is int ? json['parentId'] as int : null,
      parentName: json['parentName']?.toString(),
      minimumRequiredSignatories: json['minimumRequiredSignatories'] is int
          ? json['minimumRequiredSignatories'] as int
          : null,
    );
  }
}

class RequestFieldItem {
  final int order;
  final String key;
  final String displayText;
  final String? displayArText;
  final String type;
  final bool visibleToUser;
  final String? value;

  final List<String>? multiValues;
  final dynamic tabularData;

  final List<String> availableValues;
  final List<String>? availableArValues;
  final String? defaultValue;
  final String? defaultArValue;

  final bool firstRowHeader;
  final bool convertNumbersToArabic;

  final List<RequestFieldAvailableValueItem> availableValuesItems;

  final String? parentQuestionKey;
  final String? parentQuestionValue;
  final String? parentQuestionArValue;

  final List<dynamic> relatedQuestions;

  final String? groupTitle;
  final String? groupArTitle;

  RequestFieldItem({
    required this.order,
    required this.key,
    required this.displayText,
    this.displayArText,
    required this.type,
    required this.visibleToUser,
    required this.value,
    this.multiValues,
    this.tabularData,
    required this.availableValues,
    this.availableArValues,
    this.defaultValue,
    this.defaultArValue,
    this.firstRowHeader = false,
    this.convertNumbersToArabic = false,
    required this.availableValuesItems,
    this.parentQuestionKey,
    this.parentQuestionValue,
    this.parentQuestionArValue,
    required this.relatedQuestions,
    this.groupTitle,
    this.groupArTitle,
  });

  factory RequestFieldItem.fromJson(Map<String, dynamic> json) {
    final values = (json['availableValues'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        <String>[];

    final arValuesRaw = json['availableArValues'];
    final List<String>? availableArValues = arValuesRaw is List
        ? arValuesRaw
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
        : null;

    final multiRaw = json['multiValues'];
    final List<String>? multiValues = multiRaw is List
        ? multiRaw.map((e) => e?.toString() ?? '').toList()
        : null;

    final itemsRaw = json['availableValuesItems'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(RequestFieldAvailableValueItem.fromJson)
            .toList()
        : <RequestFieldAvailableValueItem>[];

    final rqRaw = json['relatedQuestions'];
    final relatedQuestions = rqRaw is List ? rqRaw : <dynamic>[];

    return RequestFieldItem(
      order: json['order'] is int ? json['order'] as int : 0,
      key: json['key']?.toString() ?? '',
      displayText: json['displayText']?.toString() ?? '',
      displayArText: json['displayArText']?.toString(),
      type: json['type']?.toString() ?? '',
      visibleToUser: json['visibleToUser'] == true,
      value: json['value']?.toString(),
      multiValues: multiValues,
      tabularData: json['tabularData'],
      availableValues: values,
      availableArValues: availableArValues,
      defaultValue: json['defaultValue']?.toString(),
      defaultArValue: json['defaultArValue']?.toString(),
      firstRowHeader: json['firstRowHeader'] == true,
      convertNumbersToArabic: json['convertNumbersToArabic'] == true,
      availableValuesItems: items,
      parentQuestionKey: json['parentQuestionKey']?.toString(),
      parentQuestionValue: json['parentQuestionValue']?.toString(),
      parentQuestionArValue: json['parentQuestionArValue']?.toString(),
      relatedQuestions: relatedQuestions,
      groupTitle: json['groupTitle']?.toString(),
      groupArTitle: json['groupArTitle']?.toString(),
    );
  }
}
