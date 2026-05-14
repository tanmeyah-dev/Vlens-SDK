import 'package:tan_sdk/data/models/extracted_user_data.dart';

import '../utils/id_data_parser.dart';

/// UI state for the ID / extracted VLENS data review screen.
class IdDataModel {
  IdDataModel({required this.extractedData})
      : effectiveExtractedData = parseExtractedUserData(extractedData);

  final dynamic extractedData;
  ExtractedUserData? effectiveExtractedData;
  bool isCheckingEligibility = false;
  String? errorMessage;
}
