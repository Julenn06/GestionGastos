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
  bool _isReordering = false;
  List<QuickAction> _reorderedActions = [];

  @override
  void initState() {
    super.initState();
    _reorderedActions = List.from(widget.actions);
  }

  @override
  void didUpdateWidget(QuickActionsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isReordering) {
      _reorderedActions = List.from(widget.actions);
    }
  }

  void _startReordering() {
    setState(() {
      _isReordering = true;
    });
  }

  void _finishReordering() {
    setState(() {
      _isReordering = false;
    });
    if (widget.onReorder != null) {
      widget.onReorder!(_reorderedActions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayActions = _isReordering ? _reorderedActions : widget.actions;

    if (_isReordering) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 8),
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Arrastra para reordenar',
                    style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _finishReordering,
                  child: const Text('Listo', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
              itemCount: _reorderedActions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _reorderedActions.removeAt(oldIndex);
                  _reorderedActions.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final action = _reorderedActions[index];
                return Container(
                  key: ValueKey(action.id),
                  width: 120,
                  margin: const EdgeInsets.only(right: AppTheme.paddingM),
                  child: QuickActionButton(
                    action: action,
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
        itemCount: displayActions.length + 1,
        itemBuilder: (context, index) {
          if (index == displayActions.length) {
            return Container(
              width: 120,
              margin: const EdgeInsets.only(right: AppTheme.paddingM),
              child: _AddQuickActionButton(onTap: widget.onAddNew),
            );
          }

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: AppTheme.paddingM),
            child: GestureDetector(
              onLongPress: _startReordering,
              child: QuickActionButton(
                action: displayActions[index],
                onTap: () => widget.onActionTap(displayActions[index]),
              ),
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
