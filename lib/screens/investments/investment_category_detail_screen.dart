import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/investment_service.dart';
import '../../models/investment.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/success_snackbar.dart';

/// Pantalla de detalle de inversiones por tipo
class InvestmentCategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final DateTime? startDate;
  final DateTime? endDate;

  const InvestmentCategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    this.startDate,
    this.endDate,
  });

  @override
  State<InvestmentCategoryDetailScreen> createState() => _InvestmentCategoryDetailScreenState();
}

class _InvestmentCategoryDetailScreenState extends State<InvestmentCategoryDetailScreen> {
  List<Investment> _investments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    
    final investmentService = context.read<InvestmentService>();
    final start = widget.startDate ?? DateTime(2000, 1, 1);
    final end = widget.endDate ?? DateTime.now();
    
    final allInvestments = investmentService.investments;
    final filtered = allInvestments.where((investment) {
      return investment.type == widget.categoryName &&
             investment.dateInvested.isAfter(start.subtract(const Duration(days: 1))) &&
             investment.dateInvested.isBefore(end.add(const Duration(days: 1)));
    }).toList();
    
    // Ordenar por fecha descendente
    filtered.sort((a, b) => b.dateInvested.compareTo(a.dateInvested));
    
    setState(() {
      _investments = filtered;
      _isLoading = false;
    });
  }

  Future<void> _deleteInvestment(Investment investment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Inversión'),
        content: Text('¿Estás seguro de que quieres eliminar la inversión en ${investment.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final investmentService = context.read<InvestmentService>();
      final success = await investmentService.deleteInvestment(investment.id);
      
      if (success && mounted) {
        SuccessSnackBar.show(
          context,
          title: 'Inversión eliminada',
          subtitle: '${investment.name} - ${investment.amountInvested.toStringAsFixed(2)}€',
        );
        await _loadInvestments();
      }
    }
  }

  void _showStatistics() {
    final totalInvested = _investments.fold<double>(0, (sum, inv) => sum + inv.amountInvested);
    final totalCurrent = _investments.fold<double>(0, (sum, inv) => sum + inv.currentValue);
    final count = _investments.length;
    final profitLoss = totalCurrent - totalInvested;
    final profitLossPercentage = totalInvested > 0 ? (profitLoss / totalInvested * 100) : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.categoryName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Invertido', '${totalInvested.toStringAsFixed(2)}€'),
            const SizedBox(height: 8),
            _buildStatRow('Valor Actual', '${totalCurrent.toStringAsFixed(2)}€'),
            const SizedBox(height: 8),
            _buildStatRow('Ganancia/Pérdida', 
              '${profitLoss >= 0 ? '+' : ''}${profitLoss.toStringAsFixed(2)}€ (${profitLossPercentage.toStringAsFixed(1)}%)',
              color: profitLoss >= 0 ? AppTheme.successColor : AppTheme.errorColor,
            ),
            const SizedBox(height: 8),
            _buildStatRow('Cantidad', '$count inversiones'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final totalInvested = _investments.fold<double>(0, (sum, inv) => sum + inv.amountInvested);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showStatistics,
            tooltip: 'Ver estadísticas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.paddingL),
            decoration: BoxDecoration(
              color: widget.categoryColor.withValues(alpha: 0.2),
              border: Border(
                bottom: BorderSide(
                  color: widget.categoryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${totalInvested.toStringAsFixed(2)}€',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: widget.categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_investments.length} inversiones',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          // Lista de inversiones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _investments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 64,
                              color: AppTheme.textDisabled,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay inversiones en esta categoría',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textDisabled,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.paddingM),
                        itemCount: _investments.length,
                        itemBuilder: (context, index) {
                          final investment = _investments[index];
                          final profitLoss = investment.profitLoss;
                          final profitLossPercent = investment.profitLossPercentage;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppTheme.paddingS),
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.paddingM),
                              child: Row(
                                children: [
                                  // Icono
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: widget.categoryColor.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        investment.icon,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Información principal
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          investment.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(investment.dateInvested),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        if (investment.platform != null && investment.platform!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            investment.platform!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              flex: 1,
                                              child: Text(
                                                'Actual: ${investment.currentValue.toStringAsFixed(2)}€',
                                                style: const TextStyle(fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              flex: 1,
                                              child: Text(
                                                '${profitLoss >= 0 ? '+' : ''}${profitLoss.toStringAsFixed(2)}€ (${profitLossPercent.toStringAsFixed(1)}%)',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: profitLoss >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Monto y botón eliminar
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${investment.amountInvested.toStringAsFixed(2)}€',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Invertido',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                                        onPressed: () => _deleteInvestment(investment),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
