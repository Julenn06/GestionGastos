import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/investment_service.dart';
import '../../services/gamification_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla para agregar una nueva inversión
class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _platformController = TextEditingController();
  final _amountInvestedController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  String _selectedIcon = '📈';
  bool _isLoading = false;
  double? _currentPrice;
  bool _isFetchingPrice = false;
  String? _priceError;

  final Map<String, String> _typeIcons = {
    'Acciones': '📊',
    'ETFs': '📈',
    'Fondos de Inversión': '💼',
    'Criptomonedas': '₿',
    'Bonos': '📃',
    'Bienes Raíces': '🏢',
    'Otros': '💰',
  };

  // Sugerencias de activos populares por tipo
  final Map<String, List<String>> _assetSuggestions = {
    'Criptomonedas': ['BTC', 'ETH', 'BNB', 'SOL', 'ADA', 'XRP', 'DOGE', 'DOT', 'MATIC', 'AVAX', 'LINK', 'UNI', 'LTC'],
    'Acciones': ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'NVDA', 'META', 'NFLX', 'AMD', 'INTC', 'DIS', 'BA'],
    'ETFs': ['SPY', 'QQQ', 'IWM', 'VTI', 'VOO', 'DIA', 'EEM', 'GLD', 'TLT', 'HYG'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _platformController.dispose();
    _amountInvestedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Obtiene las sugerencias para el tipo actual
  List<String> _getCurrentSuggestions() {
    if (_selectedType == null) return [];
    return _assetSuggestions[_selectedType] ?? [];
  }

  /// Selecciona una sugerencia
  void _selectSuggestion(String suggestion) {
    setState(() {
      _nameController.text = suggestion;
      _currentPrice = null;
      _priceError = null;
    });
    // Obtener precio automáticamente
    _fetchCurrentPrice();
  }
  
  /// Obtiene el precio actual del activo desde la API
  Future<void> _fetchCurrentPrice() async {
    if (_selectedType == null || _nameController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _isFetchingPrice = true;
      _priceError = null;
    });
    
    final investmentService = context.read<InvestmentService>();
    final price = await investmentService.getAssetCurrentPrice(
      _selectedType!,
      _nameController.text.trim(),
    );
    
    setState(() {
      _isFetchingPrice = false;
      if (price != null) {
        _currentPrice = price;
        _priceError = null;
      } else {
        _currentPrice = null;
        _priceError = 'No disponible';
      }
    });
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
    final gamificationService = context.read<GamificationService>();
    
    // Obtener precio actual si no lo tenemos
    if (_currentPrice == null) {
      await _fetchCurrentPrice();
    }
    
    // Calcular valor actual basado en el monto invertido
    final amountInvested = double.parse(_amountInvestedController.text);
    final currentValue = _currentPrice != null ? amountInvested : amountInvested;

    final success = await investmentService.addInvestment(
      type: _selectedType!,
      name: _nameController.text,
      platform: _platformController.text.isEmpty ? null : _platformController.text,
      amountInvested: amountInvested,
      currentValue: currentValue,
      dateInvested: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      icon: _selectedIcon,
    );

    if (success) {
      await gamificationService.checkInvestmentAchievements(
        investmentService.investmentCount,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inversión registrada correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar la inversión'),
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
        title: const Text('Nueva Inversión'),
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
              decoration: InputDecoration(
                labelText: 'Nombre o Símbolo',
                prefixIcon: const Icon(Icons.abc),
                hintText: 'Ej: AAPL, BTC, S&P 500',
                suffixIcon: _isFetchingPrice
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _fetchCurrentPrice,
                        tooltip: 'Obtener precio actual',
                      ),
              ),
              onChanged: (value) {
                // Limpiar precio cuando cambia el símbolo
                setState(() {
                  _currentPrice = null;
                  _priceError = null;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),
            // Sugerencias de activos
            if (_getCurrentSuggestions().isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getCurrentSuggestions().map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _selectSuggestion(suggestion),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  );
                }).toList(),
              ),
            ],
            if (_currentPrice != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Precio actual: €${_currentPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_priceError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Precio no disponible - se usará el monto invertido como valor inicial',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                helperText: 'Cantidad que vas a invertir',
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
                  : const Text('Guardar Inversión'),
            ),
          ],
        ),
      ),
    );
  }
}
