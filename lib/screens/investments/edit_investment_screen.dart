import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/investment_service.dart';
import '../../models/investment.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla para editar una inversión existente
class EditInvestmentScreen extends StatefulWidget {
  final Investment investment;

  const EditInvestmentScreen({super.key, required this.investment});

  @override
  State<EditInvestmentScreen> createState() => _EditInvestmentScreenState();
}

class _EditInvestmentScreenState extends State<EditInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _platformController;
  late final TextEditingController _amountInvestedController;
  late final TextEditingController _currentValueController;
  late final TextEditingController _notesController;
  
  late String? _selectedType;
  late DateTime _selectedDate;
  late String _selectedIcon;
  bool _isLoading = false;

  final Map<String, String> _typeIcons = {
    'Acciones': '📊',
    'ETFs': '📈',
    'Fondos de Inversión': '💼',
    'Criptomonedas': '₿',
    'Bonos': '📃',
    'Bienes Raíces': '🏢',
    'Otros': '💰',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.investment.name);
    _platformController = TextEditingController(text: widget.investment.platform ?? '');
    _amountInvestedController = TextEditingController(
      text: widget.investment.amountInvested.toString(),
    );
    _currentValueController = TextEditingController(
      text: widget.investment.currentValue.toString(),
    );
    _notesController = TextEditingController(text: widget.investment.notes ?? '');
    _selectedType = widget.investment.type;
    _selectedDate = widget.investment.dateInvested;
    _selectedIcon = widget.investment.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _platformController.dispose();
    _amountInvestedController.dispose();
    _currentValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un tipo de inversión')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final investmentService = context.read<InvestmentService>();

    final updatedInvestment = Investment(
      id: widget.investment.id,
      type: _selectedType!,
      name: _nameController.text,
      platform: _platformController.text.isEmpty ? null : _platformController.text,
      amountInvested: double.parse(_amountInvestedController.text),
      currentValue: double.parse(_currentValueController.text),
      dateInvested: _selectedDate,
      lastUpdate: DateTime.now(),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      icon: _selectedIcon,
    );

    final success = await investmentService.updateInvestment(updatedInvestment);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inversión actualizada correctamente'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar la inversión'),
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
        title: const Text('Editar Inversión'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          children: [
            // Tipo de inversión
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Inversión',
                prefixIcon: Icon(Icons.category),
              ),
              items: AppConstants.investmentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(_typeIcons[type] ?? '💰'),
                      const SizedBox(width: 8),
                      Text(type),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _selectedIcon = _typeIcons[value] ?? '💰';
                });
              },
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre o Símbolo',
                prefixIcon: Icon(Icons.abc),
                hintText: 'Ej: AAPL, BTC, S&P 500',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Plataforma
            TextFormField(
              controller: _platformController,
              decoration: const InputDecoration(
                labelText: 'Plataforma / Broker (opcional)',
                prefixIcon: Icon(Icons.business),
                hintText: 'Ej: eToro, Binance, DeGiro',
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Monto invertido
            TextFormField(
              controller: _amountInvestedController,
              decoration: const InputDecoration(
                labelText: 'Monto Invertido',
                prefixText: '€ ',
                suffixIcon: Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el monto invertido';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Valor actual
            TextFormField(
              controller: _currentValueController,
              decoration: const InputDecoration(
                labelText: 'Valor Actual',
                prefixText: '€ ',
                suffixIcon: Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el valor actual';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Ingresa un valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Fecha de inversión
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha de Inversión'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Notas
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              maxLength: AppConstants.maxNoteLenght,
            ),
            const SizedBox(height: AppTheme.paddingXL),

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveInvestment,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Actualizar Inversión'),
            ),
          ],
        ),
      ),
    );
  }
}
