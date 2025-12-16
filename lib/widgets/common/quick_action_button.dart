import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quick_action.dart';

/// Widget para mostrar y ejecutar una acción rápida
/// 
/// Muestra un botón visual atractivo que permite registrar
/// un gasto predefinido con un solo toque.
class QuickActionButton extends StatelessWidget {
  final QuickAction action;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.action,
    required this.onTap,
  });

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return AppTheme.primaryColor;
    }
    
    try {
      // Eliminar el # si existe
      final hexColor = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(action.color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    action.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.paddingS),

              // Nombre
              Text(
                action.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Monto
              Text(
                '${action.amount.toStringAsFixed(2)}€',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar una lista horizontal de acciones rápidas
class QuickActionsRow extends StatelessWidget {
  final List<QuickAction> actions;
  final Function(QuickAction) onActionTap;

  const QuickActionsRow({
    super.key,
    required this.actions,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.touch_app_outlined,
                size: 48,
                color: AppTheme.textDisabled,
              ),
              const SizedBox(height: AppTheme.paddingM),
              Text(
                'No hay acciones rápidas configuradas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textDisabled,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: AppTheme.paddingM),
            child: QuickActionButton(
              action: actions[index],
              onTap: () => onActionTap(actions[index]),
            ),
          );
        },
      ),
    );
  }
}
