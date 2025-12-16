import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../services/category_service.dart';
import '../../models/expense.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla para editar un gasto existente
class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  
  late String? _selectedCategory;
  late String? _selectedSubcategory;
  late DateTime _selectedDate;
  late String _selectedIcon;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _noteController = TextEditingController(text: widget.expense.note ?? '');
    _selectedCategory = widget.expense.category;
    _selectedSubcategory = widget.expense.subcategory.isEmpty ? null : widget.expense.subcategory;
    _selectedDate = widget.expense.date;
    _selectedIcon = widget.expense.icon;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final expenseService = context.read<ExpenseService>();

    final updatedExpense = Expense(
      id: widget.expense.id,
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      subcategory: _selectedSubcategory ?? '',
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      icon: _selectedIcon,
      isQuickAction: widget.expense.isQuickAction,
    );

    final success = await expenseService.updateExpense(updatedExpense);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto actualizado correctamente'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el gasto'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Gasto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          children: [
            // Campo de monto
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '€ ',
                suffixIcon: Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Selector de categoría
            Consumer<CategoryService>(
              builder: (context, categoryService, child) {
                final categories = categoryService.categories
                    .where((cat) => cat.type == 'expense')
                    .toList();

                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category.name,
                      child: Row(
                        children: [
                          Text(category.icon),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final selectedCat = categories.firstWhere(
                      (cat) => cat.name == value,
                    );
                    setState(() {
                      _selectedCategory = value;
                      _selectedSubcategory = null;
                      _selectedIcon = selectedCat.icon;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Selector de subcategoría
            if (_selectedCategory != null)
              DropdownButtonFormField<String>(
                initialValue: _selectedSubcategory,
                decoration: const InputDecoration(
                  labelText: 'Subcategoría',
                  prefixIcon: Icon(Icons.subdirectory_arrow_right),
                ),
                items: AppConstants.expenseSubcategories[_selectedCategory]
                    ?.map((subcategory) {
                  return DropdownMenuItem(
                    value: subcategory,
                    child: Text(subcategory),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubcategory = value;
                  });
                },
              ),
            const SizedBox(height: AppTheme.paddingL),

            // Selector de fecha
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Campo de nota
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              maxLength: AppConstants.maxNoteLenght,
            ),
            const SizedBox(height: AppTheme.paddingXL),

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveExpense,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Actualizar Gasto'),
            ),
          ],
        ),
      ),
    );
  }
}
