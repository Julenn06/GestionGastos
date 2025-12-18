import 'package:flutter/material.dart';
import '../../services/security_service.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

/// Pantalla de autenticación
/// 
/// Solicita autenticación biométrica o PIN antes de acceder a la aplicación
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SecurityService _securityService = SecurityService();
  final TextEditingController _pinController = TextEditingController();
  bool _isAuthenticating = false;
  bool _useBiometric = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuthMethod();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthMethod() async {
    // Verificar si tiene biometría habilitada
    final biometricEnabled = await _securityService.isBiometricEnabled();
    
    if (biometricEnabled) {
      setState(() => _useBiometric = true);
      _authenticateWithBiometric();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() => _isAuthenticating = true);
    
    final authenticated = await _securityService.authenticateWithBiometrics();
    
    if (authenticated && mounted) {
      _navigateToHome();
    } else if (mounted) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Autenticación biométrica fallida. Usa el PIN.';
        _useBiometric = false;
      });
    }
  }

  Future<void> _authenticateWithPin() async {
    if (_pinController.text.length != 4) {
      setState(() => _errorMessage = 'El PIN debe tener 4 dígitos');
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    final isValid = await _securityService.verifyPin(_pinController.text);
    
    if (isValid && mounted) {
      _navigateToHome();
    } else if (mounted) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'PIN incorrecto';
        _pinController.clear();
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icono
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingXL),

                // Título
                Text(
                  'Finanzas Personales',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: AppTheme.paddingS),
                Text(
                  _useBiometric
                      ? 'Usa tu huella para acceder'
                      : 'Ingresa tu PIN para acceder',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.paddingXL),

                // Campo PIN (solo si no está usando biometría)
                if (!_useBiometric) ...[
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        letterSpacing: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '----',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          borderSide: const BorderSide(color: AppTheme.primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _authenticateWithPin(),
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingL),

                  // Botón de confirmar
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isAuthenticating ? null : _authenticateWithPin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                      ),
                      child: _isAuthenticating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Acceder',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],

                // Mensaje de error
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.paddingM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                        const SizedBox(width: AppTheme.paddingS),
                        Flexible(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Botón de biometría (si está disponible pero no activa)
                if (!_useBiometric && _errorMessage.contains('biométrica')) ...[
                  const SizedBox(height: AppTheme.paddingL),
                  TextButton.icon(
                    onPressed: _authenticateWithBiometric,
                    icon: const Icon(Icons.fingerprint, color: AppTheme.primaryColor),
                    label: const Text(
                      'Usar huella dactilar',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
