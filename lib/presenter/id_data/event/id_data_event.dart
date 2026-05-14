import 'package:core/bases/event/base/base_event.dart';

/// Loads cached VLENS data, caches extracted payload if missing, and fetches request types.
class IdDataInitializeEvent extends BaseEvent {}

/// Calls request-eligibility API; on success navigation is signaled via [IdDataNavigateToUserInfoState].
class IdDataContinueEvent extends BaseEvent {}
