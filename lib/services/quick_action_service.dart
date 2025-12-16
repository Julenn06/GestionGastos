import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import '../models/quick_action.dart' as model;
import 'package:drift/drift.dart' as drift;

/// Servicio de gestión de acciones rápidas
/// 
/// Proporciona la lógica de negocio para gestionar las acciones rápidas
/// que permiten al usuario registrar gastos frecuentes con un solo toque.
class QuickActionService extends ChangeNotifier {
  final AppDatabase _database;
  final _uuid = const Uuid();

  List<model.QuickAction> _quickActions = [];
  bool _isLoading = false;
  String? _error;

  QuickActionService(this._database) {
    loadQuickActions();
  }

  // ============ Getters ============
  
  List<model.QuickAction> get quickActions => _quickActions;
  List<model.QuickAction> get activeQuickActions => 
      _quickActions.where((qa) => qa.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============ Métodos de Carga ============

  /// Carga todas las acciones rápidas activas
  Future<void> loadQuickActions() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final dbActions = await _database.getActiveQuickActions();
      _quickActions = dbActions.map((e) => _mapToModel(e)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar acciones rápidas: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ Métodos CRUD ============

  /// Crea una nueva acción rápida
  Future<bool> addQuickAction({
    required String name,
    required double amount,
    required String category,
    required String subcategory,
    required String icon,
    String? color,
    int? order,
  }) async {
    try {
      final id = _uuid.v4();
      final companion = QuickActionsCompanion(
        id: drift.Value(id),
        name: drift.Value(name),
        amount: drift.Value(amount),
        category: drift.Value(category),
        subcategory: drift.Value(subcategory),
        icon: drift.Value(icon),
        color: drift.Value(color),
        order: drift.Value(order ?? _quickActions.length),
        isActive: const drift.Value(true),
      );

      await _database.insertQuickAction(companion);
      await loadQuickActions();
      return true;
    } catch (e) {
      _error = 'Error al crear acción rápida: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza una acción rápida existente
  Future<bool> updateQuickAction(model.QuickAction action) async {
    try {
      final dbAction = _mapToDb(action);
      await _database.updateQuickAction(dbAction);
      await loadQuickActions();
      return true;
    } catch (e) {
      _error = 'Error al actualizar acción rápida: $e';
      notifyListeners();
      return false;
    }
  }

  /// Desactiva una acción rápida (no la elimina)
  Future<bool> deactivateQuickAction(String id) async {
    try {
      final action = _quickActions.firstWhere((qa) => qa.id == id);
      final updated = action.copyWith(isActive: false);
      return await updateQuickAction(updated);
    } catch (e) {
      _error = 'Error al desactivar acción rápida: $e';
      notifyListeners();
      return false;
    }
  }

  /// Activa una acción rápida
  Future<bool> activateQuickAction(String id) async {
    try {
      final action = _quickActions.firstWhere((qa) => qa.id == id);
      final updated = action.copyWith(isActive: true);
      return await updateQuickAction(updated);
    } catch (e) {
      _error = 'Error al activar acción rápida: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina permanentemente una acción rápida
  Future<bool> deleteQuickAction(String id) async {
    try {
      await _database.deleteQuickAction(id);
      await loadQuickActions();
      return true;
    } catch (e) {
      _error = 'Error al eliminar acción rápida: $e';
      notifyListeners();
      return false;
    }
  }

  /// Crea una nueva acción rápida personalizada
  Future<bool> createQuickAction({
    required String name,
    required double amount,
    required String category,
    required String subcategory,
    required String icon,
    String? color,
  }) async {
    return await addQuickAction(
      name: name,
      amount: amount,
      category: category,
      subcategory: subcategory,
      icon: icon,
      color: color,
    );
  }

  /// Alterna el estado activo/inactivo de una acción rápida
  Future<bool> toggleQuickAction(String id, bool isActive) async {
    if (isActive) {
      return await activateQuickAction(id);
    } else {
      return await deactivateQuickAction(id);
    }
  }

  /// Reordena las acciones rápidas
  Future<bool> reorderQuickActions(int oldIndex, int newIndex) async {
    try {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final item = _quickActions.removeAt(oldIndex);
      _quickActions.insert(newIndex, item);

      // Actualiza el orden en la base de datos
      for (int i = 0; i < _quickActions.length; i++) {
        final updated = _quickActions[i].copyWith(order: i);
        await updateQuickAction(updated);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al reordenar acciones rápidas: $e';
      notifyListeners();
      return false;
    }
  }

  // ============ Acciones Rápidas Predefinidas ============

  /// Inicializa acciones rápidas predefinidas si no existen
  Future<void> initializeDefaultQuickActions() async {
    final existingActions = await _database.getAllQuickActions();
    
    if (existingActions.isEmpty) {
      // Crear acciones rápidas por defecto
      await addQuickAction(
        name: 'Café',
        amount: 2.50,
        category: 'Alimentación',
        subcategory: 'Cafetería',
        icon: '☕',
        color: '#8B4513',
      );

      await addQuickAction(
        name: 'Transporte',
        amount: 1.50,
        category: 'Transporte',
        subcategory: 'Transporte público',
        icon: '🚇',
        color: '#4169E1',
      );

      await addQuickAction(
        name: 'Almuerzo',
        amount: 10.00,
        category: 'Alimentación',
        subcategory: 'Restaurantes',
        icon: '🍽️',
        color: '#FF6347',
      );

      await addQuickAction(
        name: 'Gasolina',
        amount: 50.00,
        category: 'Transporte',
        subcategory: 'Gasolina',
        icon: '⛽',
        color: '#228B22',
      );
    }
  }

  // ============ Métodos de Mapeo ============

  /// Convierte un objeto de base de datos a modelo
  model.QuickAction _mapToModel(QuickAction dbAction) {
    return model.QuickAction(
      id: dbAction.id,
      name: dbAction.name,
      amount: dbAction.amount,
      category: dbAction.category,
      subcategory: dbAction.subcategory,
      icon: dbAction.icon,
      color: dbAction.color,
      order: dbAction.order,
      isActive: dbAction.isActive,
    );
  }

  /// Convierte un modelo a objeto de base de datos
  QuickAction _mapToDb(model.QuickAction action) {
    return QuickAction(
      id: action.id,
      name: action.name,
      amount: action.amount,
      category: action.category,
      subcategory: action.subcategory,
      icon: action.icon,
      color: action.color,
      order: action.order,
      isActive: action.isActive,
    );
  }
}
