import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../models/expense.dart';
import '../../core/theme/app_theme.dart';
import 'edit_expense_screen.dart';

/// Pantalla de detalle de categoría
/// 
/// Muestra todos los gastos de una categoría específica con
/// información detallada, resumen y opciones de edición/eliminación.
class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final DateTime? startDate;
  final DateTime? endDate;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    this.startDate,
    this.endDate,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    
    final expenseService = context.read<ExpenseService>();
    
    // Obtener gastos de la categoría
    List<Expense> expenses = await expenseService.getExpensesByCategory(widget.categoryName);
    
    // Filtrar por fecha si se especificó
    if (widget.startDate != null && widget.endDate != null) {
      expenses = expenses.where((expense) {
        return expense.date.isAfter(widget.startDate!.subtract(const Duration(days: 1))) &&
               expense.date.isBefore(widget.endDate!.add(const Duration(days: 1)));
      }).toList();
    }
    
    // Ordenar por fecha descendente (más reciente primero)
    expenses.sort((a, b) => b.date.compareTo(a.date));
    
    // Calcular total
    final total = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    
    setState(() {
      _expenses = expenses;
      _totalAmount = total;
      _isLoading = false;
    });
  }

  Future<void> _deleteExpense(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: const Text('¿Estás seguro de que quieres eliminar este gasto?'),
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
      final expenseService = context.read<ExpenseService>();
      final success = await expenseService.deleteExpense(id);
      
      if (success && mounted) {
        await _loadExpenses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto eliminado')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return 'Hoy, ${DateFormat('HH:mm').format(date)}';
    } else if (expenseDate == yesterday) {
      return 'Ayer, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          if (_expenses.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Estadísticas'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow('Total de gastos:', _expenses.length.toString()),
                        const SizedBox(height: 8),
                        _buildStatRow('Monto total:', '${_totalAmount.toStringAsFixed(2)}€'),
                        const SizedBox(height: 8),
                        _buildStatRow(
                          'Promedio por gasto:',
                          '${(_totalAmount / _expenses.length).toStringAsFixed(2)}€',
                        ),
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
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con resumen
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.paddingL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.categoryColor.withValues(alpha: 0.3),
                        widget.categoryColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_totalAmount.toStringAsFixed(2)}€',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.categoryColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_expenses.length} gasto${_expenses.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),

                // Lista de gastos
                Expanded(
                  child: _expenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: AppTheme.paddingM),
                              Text(
                                'No hay gastos en esta categoría',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadExpenses,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.paddingM),
                            itemCount: _expenses.length,
                            itemBuilder: (context, index) {
                              final expense = _expenses[index];
                              return _buildExpenseItem(expense);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingS),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditExpenseScreen(expense: expense),
            ),
          );
          await _loadExpenses();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Center(
                  child: Text(
                    expense.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.subcategory.isNotEmpty
                          ? expense.subcategory
                          : expense.category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(expense.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    if (expense.note != null && expense.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        expense.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Monto y acciones
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${expense.amount.toStringAsFixed(2)}€',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.categoryColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppTheme.errorColor,
                    onPressed: () => _deleteExpense(expense.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
