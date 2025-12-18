import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/log_service.dart';

/// Servicio de seguridad
/// 
/// Gestiona la autenticación biométrica (huella dactilar, Face ID)
/// y el PIN de seguridad para proteger el acceso a la aplicación.
class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ============ Biometría ============

  /// Verifica si el dispositivo soporta autenticación biométrica
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      LogService.error('Error al verificar biometría', e, null, 'SecurityService');
      return false;
    }
  }

  /// Obtiene los tipos de biometría disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      LogService.error('Error al obtener biometría disponible', e, null, 'SecurityService');
      return [];
    }
  }

  /// Autentica al usuario usando biometría
  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        LogService.warning('No hay biometría disponible en el dispositivo', 'SecurityService');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Por favor, autentícate para acceder a la aplicación',
      );
    } on PlatformException catch (e) {
      LogService.error('Error en autenticación biométrica: ${e.code} - ${e.message}', e, null, 'SecurityService');
      return false;
    } catch (e) {
      LogService.error('Error desconocido en autenticación biométrica', e, null, 'SecurityService');
      return false;
    }
  }

  /// Verifica si la biometría está habilitada en la configuración
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: AppConstants.biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      LogService.error('Error al verificar configuración de biometría', e, null, 'SecurityService');
      return false;
    }
  }

  /// Habilita o deshabilita la autenticación biométrica
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: AppConstants.biometricEnabledKey,
        value: enabled.toString(),
      );
    } catch (e) {
      LogService.error('Error al configurar biometría', e, null, 'SecurityService');
    }
  }

  // ============ PIN de Seguridad ============

  /// Verifica si existe un PIN configurado
  Future<bool> hasPin() async {
    try {
      final pin = await _secureStorage.read(key: AppConstants.pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      LogService.error('Error al verificar PIN', e, null, 'SecurityService');
      return false;
    }
  }

  /// Guarda un nuevo PIN
  Future<bool> setPin(String pin) async {
    try {
      // Validar longitud del PIN
      if (pin.length != AppConstants.pinLength) {
        return false;
      }

      // Validar que solo contenga números
      if (!RegExp(r'^\d+$').hasMatch(pin)) {
        return false;
      }

      await _secureStorage.write(key: AppConstants.pinKey, value: pin);
      return true;
    } catch (e) {
      LogService.error('Error al guardar PIN', e, null, 'SecurityService');
      return false;
    }
  }

  /// Verifica si el PIN proporcionado es correcto
  Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: AppConstants.pinKey);
      return storedPin == pin;
    } catch (e) {
      LogService.error('Error al verificar PIN', e, null, 'SecurityService');
      return false;
    }
  }

  /// Elimina el PIN configurado
  Future<void> removePin() async {
    try {
      await _secureStorage.delete(key: AppConstants.pinKey);
    } catch (e) {
      LogService.error('Error al eliminar PIN', e, null, 'SecurityService');
    }
  }

  /// Cambia el PIN existente
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      // Verificar que el PIN actual sea correcto
      final isCorrect = await verifyPin(oldPin);
      if (!isCorrect) {
        return false;
      }

      // Establecer el nuevo PIN
      return await setPin(newPin);
    } catch (e) {
      LogService.error('Error al cambiar PIN', e, null, 'SecurityService');
      return false;
    }
  }

  // ============ Autenticación General ============

  /// Autentica al usuario usando el método configurado (biometría o PIN)
  /// 
  /// Prioriza la biometría si está habilitada y disponible,
  /// de lo contrario solicita el PIN.
  Future<bool> authenticate() async {
    try {
      // Verificar si la biometría está habilitada
      final biometricEnabled = await isBiometricEnabled();
      
      if (biometricEnabled) {
        final canUseBiometric = await canCheckBiometrics();
        if (canUseBiometric) {
          return await authenticateWithBiometrics();
        }
      }

      // Si no hay biometría, verificar que exista PIN
      return await hasPin();
    } catch (e) {
      LogService.error('Error en autenticación', e, null, 'SecurityService');
      return false;
    }
  }

  /// Verifica si se requiere autenticación
  Future<bool> requiresAuthentication() async {
    final hasPinConfig = await hasPin();
    final biometricEnabled = await isBiometricEnabled();
    return hasPinConfig || biometricEnabled;
  }

  // ============ Seguridad de Datos ============

  /// Limpia todos los datos de seguridad almacenados
  Future<void> clearAllSecurityData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      LogService.error('Error al limpiar datos de seguridad', e, null, 'SecurityService');
    }
  }

  /// Guarda un dato de forma segura
  Future<void> writeSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      LogService.error('Error al guardar dato seguro', e, null, 'SecurityService');
    }
  }

  /// Lee un dato almacenado de forma segura
  Future<String?> readSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      LogService.error('Error al leer dato seguro', e, null, 'SecurityService');
      return null;
    }
  }

  /// Elimina un dato específico
  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      LogService.error('Error al eliminar dato seguro', e, null, 'SecurityService');
    }
  }
}
