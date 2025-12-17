import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/quick_investment_service.dart';
import '../../widgets/common/success_snackbar.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla para agregar una nueva inversión rápida
class AddQuickInvestmentScreen extends StatefulWidget {
  const AddQuickInvestmentScreen({super.key});

  @override
  State<AddQuickInvestmentScreen> createState() => _AddQuickInvestmentScreenState();
}

class _AddQuickInvestmentScreenState extends State<AddQuickInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  
  String? _selectedCategory;
  String _selectedIcon = '📈';
  bool _isLoading = false;
  bool _isCustomCategory = false;

  // Categorías de inversiones predefinidas
  final Map<String, String> _investmentCategories = {
    'Acciones': '📈',
    'Cripto': '₿',
    'Fondos': '💼',
    'Bonos': '📊',
    'Inmuebles': '🏢',
    'Metales': '🪙',
    'ETFs': '📉',
    'Otros': '💰',
    '+ Personalizado': '✨',
  };

  // Iconos disponibles para elegir
  final List<String> _availableIcons = [
    '📈', '📉', '₿', '💼', '📊', '🏢', '🪙', '💰',
    '💵', '💶', '💷', '💴', '🔐', '⚡', '🚀', '💎',
    '🌟', '⭐', '🎯', '🏆', '💪', '🔥', '✨', '🌙',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveQuickInvestment() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      SuccessSnackBar.showError(
        context,
        title: 'Categoría requerida',
        subtitle: 'Por favor selecciona una categoría',
      );
      return;
    }

    if (_isCustomCategory && _customCategoryController.text.isEmpty) {
      SuccessSnackBar.showError(
        context,
        title: 'Nombre requerido',
        subtitle: 'Por favor escribe un nombre para la categoría personalizada',
      );
      return;
    }

    setState(() => _isLoading = true);

    final quickInvestmentService = context.read<QuickInvestmentService>();
    final categoryName = _isCustomCategory 
        ? _customCategoryController.text 
        : _selectedCategory!;

    final success = await quickInvestmentService.addQuickInvestment(
      name: _nameController.text,
      type: categoryName,
      amount: double.parse(_amountController.text),
      investmentName: _nameController.text,
      icon: _selectedIcon,
    );

    if (success) {
      if (mounted) {
        Navigator.pop(context);
        SuccessSnackBar.show(
          context,
          title: 'Inversión rápida creada',
          subtitle: '${_nameController.text} - ${_amountController.text}€',
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        SuccessSnackBar.showError(
          context,
          title: 'Error al crear',
          subtitle: 'No se pudo guardar la inversión rápida',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Inversión Rápida'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          children: [
            // Información
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.secondaryColor),
                  const SizedBox(width: AppTheme.paddingS),
                  Expanded(
                    child: Text(
                      'Crea atajos para tus inversiones recurrentes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondaryColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.label),
                hintText: 'Ej: Bitcoin mensual',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Monto
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

            // Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category),
                suffixIcon: _selectedCategory != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(_selectedIcon, style: const TextStyle(fontSize: 24)),
                      )
                    : null,
              ),
              items: _investmentCategories.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Text(entry.value, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(entry.key),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _isCustomCategory = value == '+ Personalizado';
                  if (value != null && value != '+ Personalizado') {
                    _selectedIcon = _investmentCategories[value]!;
                  }
                });
              },
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Campo de texto para categoría personalizada
            if (_isCustomCategory) ...[
              TextFormField(
                controller: _customCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de categoría personalizada',
                  prefixIcon: Icon(Icons.edit),
                  hintText: 'Ej: NFTs',
                ),
                validator: (value) {
                  if (_isCustomCategory && (value == null || value.isEmpty)) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.paddingL),
            ],

            // Selector de icono
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Icono seleccionado',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: AppTheme.secondaryColor,
                      width: 2,
                    ),
                  ),
                  child: Text(_selectedIcon, style: const TextStyle(fontSize: 32)),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.secondaryColor.withValues(alpha: 0.2)
                          : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.secondaryColor
                            : AppTheme.secondaryColor.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.paddingXL),

            // Botón de guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveQuickInvestment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                backgroundColor: AppTheme.secondaryColor,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Crear Inversión Rápida',
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
