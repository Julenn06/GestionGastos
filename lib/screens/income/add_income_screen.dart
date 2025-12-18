import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/income_service.dart';
import '../../widgets/common/success_snackbar.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla para agregar un nuevo ingreso
class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Categorías de ingresos predefinidas
  final Map<String, Map<String, dynamic>> _incomeCategories = {
    'Nómina': {'icon': '💰', 'subcategory': 'Salario'},
    'Freelance': {'icon': '💼', 'subcategory': 'Trabajo'},
    'Bizum': {'icon': '📱', 'subcategory': 'Transferencia'},
    'Devolución': {'icon': '↩️', 'subcategory': 'Reembolso'},
    'Venta': {'icon': '🏷️', 'subcategory': 'Venta'},
    'Regalo': {'icon': '🎁', 'subcategory': 'Regalo'},
    'Inversión': {'icon': '📈', 'subcategory': 'Dividendos'},
    'Otros': {'icon': '💵', 'subcategory': 'Otros'},
  };

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

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      SuccessSnackBar.showError(
        context,
        title: 'Categoría requerida',
        subtitle: 'Por favor selecciona una categoría para continuar',
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() => _isLoading = true);

    final incomeService = context.read<IncomeService>();
    final categoryData = _incomeCategories[_selectedCategory]!;

    final success = await incomeService.addIncome(
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      subcategory: categoryData['subcategory'] as String,
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      icon: categoryData['icon'] as String,
    );

    if (success) {
      if (mounted) {
        Navigator.pop(context);
        SuccessSnackBar.show(
          context,
          title: 'Ingreso registrado',
          subtitle: '${double.parse(_amountController.text).toStringAsFixed(2)}€ - $_selectedCategory',
          icon: Icons.add_circle_outline,
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        SuccessSnackBar.showError(
          context,
          title: 'Error al registrar',
          subtitle: 'No se pudo guardar el ingreso. Inténtalo de nuevo',
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Ingreso'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          children: [
            // Encabezado informativo
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.successColor),
                  const SizedBox(width: AppTheme.paddingS),
                  Expanded(
                    child: Text(
                      'Registra dinero que recibes: nómina, bizums, devoluciones, etc.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.successColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Campo de monto
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '€ ',
                suffixIcon: Icon(Icons.euro, color: AppTheme.successColor),
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
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category, color: AppTheme.successColor),
              ),
              items: _incomeCategories.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Text(entry.value['icon'] as String, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(entry.key),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Selector de fecha
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppTheme.successColor),
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
                hintText: 'Ej: Nómina de diciembre',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: AppTheme.paddingXL),

            // Botón de guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveIncome,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                backgroundColor: AppTheme.successColor,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Registrar Ingreso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
