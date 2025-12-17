import 'package:flutter/material.dart';

/// Sistema de gestión de notificaciones apilables
/// 
/// Permite mostrar múltiples notificaciones simultáneamente que se apilan
/// verticalmente y se animan suavemente al aparecer, desaparecer y reposicionarse.
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final List<NotificationEntry> _notifications = [];
  OverlayState? _overlayState;

  /// Muestra una notificación de éxito
  void showSuccess(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData icon = Icons.check_circle_outline,
  }) {
    _showNotification(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      gradient: const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  /// Muestra una notificación de error
  void showError(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData icon = Icons.error_outline,
  }) {
    _showNotification(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      gradient: const LinearGradient(
        colors: [Color(0xFFF44336), Color(0xFFE53935)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  void _showNotification(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    _overlayState ??= Overlay.of(context);
    
    final entry = NotificationEntry(
      title: title,
      subtitle: subtitle,
      icon: icon,
      gradient: gradient,
      onRemove: _removeNotification,
    );

    _notifications.add(entry);
    _overlayState!.insert(entry.overlayEntry);
    _updatePositions();
  }

  void _removeNotification(NotificationEntry entry) {
    final index = _notifications.indexOf(entry);
    if (index != -1) {
      _notifications.removeAt(index);
      entry.overlayEntry.remove();
      _updatePositions();
    }
  }

  void _updatePositions() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i].updatePosition(i);
    }
  }
}

/// Entrada individual de notificación
class NotificationEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Function(NotificationEntry) onRemove;
  late final OverlayEntry overlayEntry;
  final ValueNotifier<int> positionNotifier = ValueNotifier(0);

  NotificationEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onRemove,
  }) {
    overlayEntry = OverlayEntry(
      builder: (context) => NotificationWidget(entry: this),
    );
  }

  void updatePosition(int position) {
    positionNotifier.value = position;
  }

  void remove() {
    onRemove(this);
  }
}

/// Widget de notificación individual con animaciones
class NotificationWidget extends StatefulWidget {
  final NotificationEntry entry;

  const NotificationWidget({super.key, required this.entry});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador para la animación de entrada/salida horizontal
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Controlador para la animación de opacidad
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Iniciar animaciones de entrada
    _slideController.forward();
    _fadeController.forward();

    // Auto-remover después de 2 segundos
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    await _fadeController.reverse();
    await _slideController.reverse();
    widget.entry.remove();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.entry.positionNotifier,
      builder: (context, position, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          top: 50.0 + (position * 90.0), // Espaciado entre notificaciones
          right: 16,
          left: 16,
          child: child!,
        );
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: widget.entry.gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.entry.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.entry.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.entry.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
