/// One answered dynamic field, passed to the summary / create-request flow.
class SummaryAnswerItem {
  final String key;
  final String label;

  /// Sent in `requestFieldsValues` for request/create.
  final String value;

  /// Shown on the summary screen; defaults to [value].
  final String displayValue;

  SummaryAnswerItem({
    required this.key,
    required this.label,
    required this.value,
    String? displayValue,
  }) : displayValue = displayValue ?? value;
}
