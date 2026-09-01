import 'api_business_exception.dart';

/// User-facing message from any SDK API/network error.
String apiExceptionMessage(
  Object error, {
  String fallback = 'حدث خطأ غير متوقع',
}) {
  if (error is ApiBusinessException) return error.message;

  var message = error.toString().replaceAll('Exception: ', '').trim();
  if (message.isEmpty) return fallback;

  if (message.contains('SocketException') ||
      message.contains('connection refused') ||
      message.contains('Failed host lookup')) {
    return 'لا يمكن الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت أو أن الخادم يعمل';
  }
  if (message.contains('timeout') || message.contains('TimeoutException')) {
    return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
  }
  if (message.contains('Certificate') || message.contains('SSL')) {
    return 'خطأ في شهادة الاتصال الآمن';
  }

  return message;
}
