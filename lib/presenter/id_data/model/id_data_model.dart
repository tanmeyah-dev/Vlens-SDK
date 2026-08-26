import 'package:tan_sdk/data/models/extracted_user_data.dart';

import '../utils/id_data_parser.dart';

/// UI state for the ID / extracted VLENS data review screen.
class IdDataModel {
  IdDataModel({
    this.extractedData,
    this.loadFromApi = false,
  }) : effectiveExtractedData = parseExtractedUserData(extractedData);

  /// Fresh VLens scan payload (POST path). Null when opened after login.
  final dynamic extractedData;

  /// When true (verified login), GET `/vlens-data?phoneNumber=...` only.
  /// When false (after VLens scan), POST extracted data only.
  final bool loadFromApi;

  ExtractedUserData? effectiveExtractedData;
  bool isLoadingVlensData = false;
  bool isCheckingEligibility = false;
  String? errorMessage;
}
