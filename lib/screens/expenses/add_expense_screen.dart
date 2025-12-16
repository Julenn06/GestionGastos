import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../services/gamification_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla para agregar un nuevo gasto
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedSubcategory;
  DateTime _selectedDate = DateTime.now();
  String _selectedIcon = '💰';
  bool _isLoading = false;

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
    final gamificationService = context.read<GamificationService>();

    final success = await expenseService.addExpense(
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      subcategory: _selectedSubcategory ?? '',
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      icon: _selectedIcon,
    );

    if (success) {
      await gamificationService.updateStreak();
      await gamificationService.checkExpenseAchievements(
        expenseService.expenseCount,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto registrado correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar el gasto'),
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
        title: const Text('Nuevo Gasto'),
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category),
              ),
              items: AppConstants.expenseCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Text(AppConstants.categoryIcons[category] ?? '📦'),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _selectedSubcategory = null;
                  _selectedIcon = AppConstants.categoryIcons[value] ?? '📦';
                });
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
                  : const Text('Guardar Gasto'),
            ),
          ],
        ),
      ),
    );
  }
}
