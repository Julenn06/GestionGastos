import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../services/category_service.dart';
import '../../models/expense.dart';
import '../../core/theme/app_theme.dart';
import 'edit_expense_screen.dart';

/// Pantalla de historial de gastos
/// 
/// Muestra todos los gastos registrados con opciones de editar y eliminar.
/// Permite filtrar por categoría y ordenar por fecha o monto.
class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  String? _selectedCategory;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  List<Expense> _getFilteredExpenses(List<Expense> expenses) {
    if (_selectedCategory == null) return expenses;
    return expenses.where((e) => e.category == _selectedCategory).toList();
  }

  Future<void> _deleteExpense(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: const Text('¿Estás seguro de eliminar este gasto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final expenseService = context.read<ExpenseService>();
      final success = await expenseService.deleteExpense(id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto eliminado'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Gastos'),
        actions: [
          Consumer<CategoryService>(
            builder: (context, categoryService, _) {
              final categories = categoryService.categories
                  .where((cat) => cat.type == 'expense')
                  .toList();

              return PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value == 'all' ? null : value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'all',
                    child: Text('Todas las categorías'),
                  ),
                  const PopupMenuDivider(),
                  ...categories.map((category) {
                    return PopupMenuItem(
                      value: category.name,
                      child: Row(
                        children: [
                          Text(category.icon),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<ExpenseService>(
        builder: (context, expenseService, _) {
          final filteredExpenses = _getFilteredExpenses(expenseService.expenses);

          if (filteredExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  Text(
                    _selectedCategory == null
                        ? 'No hay gastos registrados'
                        : 'No hay gastos en esta categoría',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            itemCount: filteredExpenses.length,
            itemBuilder: (context, index) {
              final expense = filteredExpenses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      expense.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    expense.category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (expense.subcategory.isNotEmpty)
                        Text(expense.subcategory),
                      Text(
                        _dateFormat.format(expense.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (expense.note != null && expense.note!.isNotEmpty)
                        Text(
                          expense.note!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[500],
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
                        '${expense.amount.toStringAsFixed(2)}€',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                                SizedBox(width: 8),
                                Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditExpenseScreen(expense: expense),
                              ),
                            );
                          } else if (value == 'delete') {
                            await _deleteExpense(expense.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
