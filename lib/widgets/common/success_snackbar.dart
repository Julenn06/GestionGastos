import 'package:flutter/material.dart';
import 'notification_manager.dart';

/// Widget personalizado para mostrar notificaciones de éxito
/// 
/// Proporciona feedback visual profesional con gradientes, iconos
/// y animaciones suaves para las acciones del usuario.
/// Ahora usa un sistema de notificaciones apilables.
class SuccessSnackBar {
  static final NotificationManager _manager = NotificationManager();

  /// Muestra una notificación de éxito con el diseño personalizado
  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.check_circle_outline,
  }) {
    _manager.showSuccess(
      context,
      title: title,
      subtitle: subtitle ?? '',
      icon: icon,
    );
  }

  /// Muestra una notificación de error
  static void showError(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.error_outline,
  }) {
    _manager.showError(
      context,
      title: title,
      subtitle: subtitle ?? '',
      icon: icon,
    );
  }

  /// Muestra una notificación de información
  static void showInfo(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.info_outline,
  }) {
    _manager.showSuccess(
      context,
      title: title,
      subtitle: subtitle ?? '',
      icon: icon,
    );
  }
}
