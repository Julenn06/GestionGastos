import 'package:intl/intl.dart';

/// Utilidades para formatear valores monetarios
class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '€',
    decimalDigits: 2,
    locale: 'es_ES',
  );

  /// Formatea un valor double a formato de moneda
  static String format(double value) {
    return _currencyFormat.format(value);
  }

  /// Formatea un valor double a formato compacto (1.5K, 2.3M)
  static String formatCompact(double value) {
    final formatter = NumberFormat.compactCurrency(
      symbol: '€',
      decimalDigits: 1,
      locale: 'es_ES',
    );
    return formatter.format(value);
  }
}

/// Utilidades para formatear fechas
class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_ES');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'es_ES');

  /// Formatea una fecha a DD/MM/YYYY
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formatea una fecha y hora a DD/MM/YYYY HH:mm
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Formatea solo el mes y año (ej: Diciembre 2024)
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Retorna una descripción relativa de la fecha (Hoy, Ayer, etc.)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoy';
    } else if (dateOnly == yesterday) {
      return 'Ayer';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE', 'es_ES').format(date);
    } else {
      return formatDate(date);
    }
  }
}

/// Utilidades para validación de datos
class Validators {
  /// Valida que un valor numérico sea positivo
  static bool isPositiveNumber(double value) {
    return value > 0;
  }

  /// Valida que un string no esté vacío
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Valida formato de PIN (4 dígitos)
  static bool isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }

  /// Valida que un monto esté dentro del rango permitido
  static bool isValidAmount(double amount, {double? max}) {
    if (amount <= 0) return false;
    if (max != null && amount > max) return false;
    return true;
  }
}
