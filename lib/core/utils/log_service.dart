import 'package:flutter/foundation.dart';

/// Servicio de logging para la aplicación
/// 
/// Proporciona métodos para registrar mensajes de depuración, advertencias y errores
/// de forma controlada, evitando prints en producción.
class LogService {
  static const String _tag = 'GestionGastos';

  /// Registra un mensaje de depuración (solo en modo debug)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] DEBUG: $message');
    }
  }

  /// Registra un mensaje de información
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] INFO: $message');
    }
  }

  /// Registra un mensaje de advertencia
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] WARNING: $message');
    }
  }

  /// Registra un mensaje de error
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ERROR: $message');
      if (error != null) {
        debugPrint('Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}
