import 'request_types_response.dart';

class HomeModel {
  bool isLoading;
  String? errorMessage;
  List<RequestTypeItem> requestTypes;

  HomeModel({
    this.isLoading = false,
    this.errorMessage,
    List<RequestTypeItem>? requestTypes,
  }) : requestTypes = requestTypes ?? [];
}
