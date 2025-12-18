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

    return RepaintBoundary(
      child: Material(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    action.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Nombre
              Text(
                action.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),

              // Monto
              Text(
                '${action.amount.toStringAsFixed(2)}€',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// Widget para mostrar una lista horizontal de acciones rápidas
class QuickActionsRow extends StatefulWidget {
  final List<QuickAction> actions;
  final Function(QuickAction) onActionTap;
  final VoidCallback? onAddNew;
  final Function(List<QuickAction>)? onReorder;

  const QuickActionsRow({
    super.key,
    required this.actions,
    required this.onActionTap,
    this.onAddNew,
    this.onReorder,
  });

  @override
  State<QuickActionsRow> createState() => _QuickActionsRowState();
}

class _QuickActionsRowState extends State<QuickActionsRow> {
  List<QuickAction> _currentActions = [];

  @override
  void initState() {
    super.initState();
    _currentActions = List.from(widget.actions);
  }

  @override
  void didUpdateWidget(QuickActionsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currentActions = List.from(widget.actions);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      // Limitar newIndex para que no sobrepase la penúltima posición
      // (la última es el botón "+")
      final maxIndex = _currentActions.length - 1;
      if (newIndex > maxIndex) {
        newIndex = maxIndex;
      }
      
      if (newIndex > oldIndex) newIndex--;
      final item = _currentActions.removeAt(oldIndex);
      _currentActions.insert(newIndex, item);
    });
    
    // Guardar automáticamente después de soltar
    Future.delayed(const Duration(milliseconds: 100), () {
      if (widget.onReorder != null && mounted) {
        widget.onReorder!(_currentActions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final actionCount = _currentActions.length;
    
    return SizedBox(
      height: 140,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
        itemCount: actionCount + 1, // +1 para el botón +
        onReorder: (oldIndex, newIndex) {
          // No permitir reordenar el botón + (última posición)
          if (oldIndex == actionCount || newIndex == actionCount) {
            return; // Ignorar si se intenta mover el botón +
          }
          _onReorder(oldIndex, newIndex);
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          // Último elemento: botón de agregar (no reordenable)
          if (index == actionCount) {
            return Container(
              key: const ValueKey('add_button'),
              width: 120,
              margin: const EdgeInsets.only(right: AppTheme.paddingM),
              child: IgnorePointer(
                child: _AddQuickActionButton(onTap: widget.onAddNew),
              ),
            );
          }

          // Elementos reordenables
          final action = _currentActions[index];
          return Container(
            key: ValueKey(action.id),
            width: 120,
            margin: const EdgeInsets.only(right: AppTheme.paddingM),
            child: QuickActionButton(
              action: action,
              onTap: () => widget.onActionTap(action),
            ),
          );
        },
      ),
    );
  }
}

/// Botón especial para agregar nueva acción rápida
class _AddQuickActionButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddQuickActionButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nueva',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Acción',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
