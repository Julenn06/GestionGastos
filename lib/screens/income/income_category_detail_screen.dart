import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/income_service.dart';
import '../../models/income.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/success_snackbar.dart';

/// Pantalla de detalle de ingresos por categoría
class IncomeCategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final DateTime? startDate;
  final DateTime? endDate;

  const IncomeCategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    this.startDate,
    this.endDate,
  });

  @override
  State<IncomeCategoryDetailScreen> createState() => _IncomeCategoryDetailScreenState();
}

class _IncomeCategoryDetailScreenState extends State<IncomeCategoryDetailScreen> {
  List<Income> _incomes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    setState(() => _isLoading = true);
    
    final incomeService = context.read<IncomeService>();
    final start = widget.startDate ?? DateTime(2000, 1, 1);
    final end = widget.endDate ?? DateTime.now();
    
    final allIncomes = await incomeService.getIncomesByDateRange(start, end);
    final filtered = allIncomes.where((income) => income.category == widget.categoryName).toList();
    
    // Ordenar por fecha descendente
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    setState(() {
      _incomes = filtered;
      _isLoading = false;
    });
  }

  Future<void> _deleteIncome(Income income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ingreso'),
        content: Text('¿Estás seguro de que quieres eliminar este ingreso de ${income.amount.toStringAsFixed(2)}€?'),
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
      final incomeService = context.read<IncomeService>();
      final success = await incomeService.deleteIncome(income.id);
      
      if (success && mounted) {
        SuccessSnackBar.show(
          context,
          title: 'Ingreso eliminado',
          subtitle: '${income.amount.toStringAsFixed(2)}€ - ${income.category}',
        );
        await _loadIncomes();
      }
    }
  }

  void _showStatistics() {
    final total = _incomes.fold<double>(0, (sum, income) => sum + income.amount);
    final count = _incomes.length;
    final average = count > 0 ? total / count : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.categoryName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total', '${total.toStringAsFixed(2)}€'),
            const SizedBox(height: 8),
            _buildStatRow('Cantidad', '$count ingresos'),
            const SizedBox(height: 8),
            _buildStatRow('Promedio', '${average.toStringAsFixed(2)}€'),
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

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final incomeDate = DateTime(date.year, date.month, date.day);

    if (incomeDate == today) {
      return 'Hoy, ${DateFormat('HH:mm').format(date)}';
    } else if (incomeDate == yesterday) {
      return 'Ayer, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _incomes.fold<double>(0, (sum, income) => sum + income.amount);

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
                  '${total.toStringAsFixed(2)}€',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: widget.categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_incomes.length} ingresos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          // Lista de ingresos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _incomes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: AppTheme.textDisabled,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay ingresos en esta categoría',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textDisabled,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.paddingM),
                        itemCount: _incomes.length,
                        itemBuilder: (context, index) {
                          final income = _incomes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppTheme.paddingS),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: widget.categoryColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    income.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              title: Text(
                                income.subcategory,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_formatDate(income.date)),
                                  if (income.note != null && income.note!.isNotEmpty)
                                    Text(
                                      income.note!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+${income.amount.toStringAsFixed(2)}€',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                    onPressed: () => _deleteIncome(income),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
