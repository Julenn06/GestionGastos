import 'package:flutter/material.dart';
import '../../services/security_service.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla de configuración de seguridad
/// 
/// Permite al usuario configurar PIN y habilitar/deshabilitar autenticación biométrica.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final SecurityService _securityService = SecurityService();
  bool _biometricEnabled = false;
  bool _hasBiometrics = false;
  bool _hasPin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final canCheck = await _securityService.canCheckBiometrics();
    final biometricEnabled = await _securityService.isBiometricEnabled();
    final hasPin = await _securityService.hasPin();
    
    setState(() {
      _hasBiometrics = canCheck;
      _biometricEnabled = biometricEnabled;
      _hasPin = hasPin;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Probar autenticación antes de habilitar
      final authenticated = await _securityService.authenticateWithBiometrics();
      if (authenticated) {
        await _securityService.setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autenticación biométrica habilitada'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autenticación biométrica fallida'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      await _securityService.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autenticación biométrica deshabilitada'),
          ),
        );
      }
    }
  }

  Future<void> _setupPin() async {
    if (!mounted) return;
    
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => const _PinDialog(title: 'Crear PIN'),
    );

    if (pin != null && pin.length == 4 && mounted) {
      final confirmPin = await showDialog<String>(
        context: context,
        builder: (context) => const _PinDialog(title: 'Confirmar PIN'),
      );

      if (pin == confirmPin && mounted) {
        final success = await _securityService.setPin(pin);
        if (success && mounted) {
          setState(() => _hasPin = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN configurado correctamente'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Los PINs no coinciden'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _changePin() async {
    final currentPin = await showDialog<String>(
      context: context,
      builder: (context) => const _PinDialog(title: 'PIN Actual'),
    );

    if (currentPin != null) {
      final isValid = await _securityService.verifyPin(currentPin);
      if (isValid) {
        await _setupPin();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN incorrecto'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar PIN'),
        content: const Text('¿Estás seguro de eliminar el PIN de seguridad?'),
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

    if (confirmed == true) {
      await _securityService.removePin();
      setState(() => _hasPin = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN eliminado'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguridad'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        children: [
          // PIN Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pin, color: AppTheme.primaryColor),
                  title: const Text('PIN de Seguridad'),
                  subtitle: Text(_hasPin ? 'Configurado' : 'No configurado'),
                  trailing: Icon(
                    _hasPin ? Icons.check_circle : Icons.cancel,
                    color: _hasPin ? AppTheme.successColor : Colors.grey,
                  ),
                ),
                const Divider(height: 1),
                if (_hasPin)
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Cambiar PIN'),
                    onTap: _changePin,
                  ),
                ListTile(
                  leading: Icon(_hasPin ? Icons.delete : Icons.add),
                  title: Text(_hasPin ? 'Eliminar PIN' : 'Configurar PIN'),
                  onTap: _hasPin ? _removePin : _setupPin,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingL),

          // Biometric Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fingerprint, color: AppTheme.secondaryColor),
                  title: const Text('Autenticación Biométrica'),
                  subtitle: Text(
                    _hasBiometrics
                        ? 'Disponible en este dispositivo'
                        : 'No disponible',
                  ),
                ),
                if (_hasBiometrics) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.security),
                    title: const Text('Habilitar Biometría'),
                    subtitle: const Text('Huella dactilar o Face ID'),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppTheme.paddingL),

          // Info Section
          Card(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: AppTheme.paddingS),
                      Text(
                        'Información de Seguridad',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  Text(
                    '• El PIN se almacena de forma segura en tu dispositivo\n'
                    '• La autenticación biométrica usa el hardware de seguridad del dispositivo\n'
                    '• Puedes usar PIN y biometría simultáneamente\n'
                    '• Si olvidas tu PIN, deberás reinstalar la app',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  final String title;

  const _PinDialog({required this.title});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String _pin = '';

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) Navigator.pop(context, _pin);
        });
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PIN Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _pin.length
                      ? AppTheme.primaryColor
                      : Colors.grey[300],
                ),
              );
            }),
          ),
          const SizedBox(height: AppTheme.paddingL),
          // Numpad
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              ...List.generate(9, (index) {
                final number = (index + 1).toString();
                return _NumButton(number: number, onTap: () => _addDigit(number));
              }),
              const SizedBox.shrink(),
              _NumButton(number: '0', onTap: () => _addDigit('0')),
              _NumButton(
                number: '⌫',
                onTap: _removeDigit,
                isSpecial: true,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _NumButton extends StatelessWidget {
  final String number;
  final VoidCallback onTap;
  final bool isSpecial;

  const _NumButton({
    required this.number,
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSpecial ? Colors.grey[200] : AppTheme.primaryColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSpecial ? Colors.grey[700] : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
