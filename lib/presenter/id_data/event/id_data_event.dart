import 'package:core/bases/event/base/base_event.dart';

/// Loads cached VLENS data, caches extracted payload if missing, and fetches request types.
class IdDataInitializeEvent extends BaseEvent {}

/// Calls CMA check-user then request-eligibility; on success navigation is
/// signaled via [IdDataNavigateToUserInfoState].
class IdDataContinueEvent extends BaseEvent {}
