import 'package:flutter/material.dart';
import '../../models/quick_investment.dart';
import '../../core/theme/app_theme.dart';

/// Widget para un botón de acción rápida de inversión
/// 
/// Muestra un botón elegante y táctil para una acción rápida predefinida
/// que permite actualizar inversiones recurrentes con un solo toque.
class QuickInvestmentButton extends StatelessWidget {
  final QuickInvestment investment;
  final VoidCallback onTap;

  const QuickInvestmentButton({
    super.key,
    required this.investment,
    required this.onTap,
  });

  Color get color {
    if (investment.color != null) {
      try {
        return Color(int.parse(investment.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return AppTheme.secondaryColor;
      }
    }
    return AppTheme.secondaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.paddingS),
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
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      investment.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Nombre
                Text(
                  investment.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),

                // Monto
                Text(
                  '+${investment.amount.toStringAsFixed(0)}€',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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

/// Widget para mostrar una lista horizontal de acciones rápidas de inversión
class QuickInvestmentsRow extends StatefulWidget {
  final List<QuickInvestment> investments;
  final Function(QuickInvestment) onInvestmentTap;
  final VoidCallback? onAddNew;
  final Function(List<QuickInvestment>)? onReorder;

  const QuickInvestmentsRow({
    super.key,
    required this.investments,
    required this.onInvestmentTap,
    this.onAddNew,
    this.onReorder,
  });

  @override
  State<QuickInvestmentsRow> createState() => _QuickInvestmentsRowState();
}

class _QuickInvestmentsRowState extends State<QuickInvestmentsRow> {
  List<QuickInvestment> _currentInvestments = [];

  @override
  void initState() {
    super.initState();
    _currentInvestments = List.from(widget.investments);
  }

  @override
  void didUpdateWidget(QuickInvestmentsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currentInvestments = List.from(widget.investments);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      // Limitar newIndex para que no sobrepase la penúltima posición
      // (la última es el botón "+")
      final maxIndex = _currentInvestments.length - 1;
      if (newIndex > maxIndex) {
        newIndex = maxIndex;
      }
      
      if (newIndex > oldIndex) newIndex--;
      final item = _currentInvestments.removeAt(oldIndex);
      _currentInvestments.insert(newIndex, item);
    });
    
    // Guardar automáticamente después de soltar
    Future.delayed(const Duration(milliseconds: 100), () {
      if (widget.onReorder != null && mounted) {
        widget.onReorder!(_currentInvestments);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final investmentCount = _currentInvestments.length;
    
    return SizedBox(
      height: 120,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
        itemCount: investmentCount + 1, // +1 para el botón +
        onReorder: (oldIndex, newIndex) {
          // No permitir reordenar el botón + (última posición)
          if (oldIndex == investmentCount || newIndex == investmentCount) {
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
          if (index == investmentCount) {
            return Padding(
              key: const ValueKey('add_button'),
              padding: const EdgeInsets.only(right: AppTheme.paddingS),
              child: IgnorePointer(
                child: _AddQuickInvestmentButton(onTap: widget.onAddNew),
              ),
            );
          }

          // Elementos reordenables
          final investment = _currentInvestments[index];
          return Padding(
            key: ValueKey(investment.id),
            padding: const EdgeInsets.only(right: AppTheme.paddingS),
            child: QuickInvestmentButton(
              investment: investment,
              onTap: () => widget.onInvestmentTap(investment),
            ),
          );
        },
      ),
    );
  }
}

/// Botón especial para agregar nueva inversión rápida
class _AddQuickInvestmentButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddQuickInvestmentButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.secondaryColor.withValues(alpha: 0.3),
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
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 32,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nueva',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Inversión',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
