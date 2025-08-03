import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Centralized logger for the app
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // لا نعرض أسماء الدوال
      errorMethodCount: 5, // عدد الأسطر مع StackTrace إذا خطأ
      lineLength: 80, // عرض السطر
      colors: true, // ألوان بالكونسل
      printEmojis: true, // يضيف إيموجي حسب نوع الرسالة
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // يضيف الوقت
    ),
  );

  static void d(String message) {
    if (kDebugMode) _logger.d(message);
  }

  static void i(String message) {
    if (kDebugMode) _logger.i(message);
  }

  static void w(String message) {
    if (kDebugMode) _logger.w(message);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) _logger.e(message, error: error, stackTrace: stackTrace);
  }
}