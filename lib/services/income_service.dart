import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import '../models/income.dart' as model;
import 'package:drift/drift.dart' as drift;

/// Servicio de gestión de ingresos
/// 
/// Proporciona la lógica de negocio para todas las operaciones relacionadas
/// con ingresos (dinero que entra).
class IncomeService extends ChangeNotifier {
  final AppDatabase _database;
  final _uuid = const Uuid();

  List<model.Income> _incomes = [];
  bool _isLoading = false;
  String? _error;

  IncomeService(this._database) {
    loadIncomes();
  }

  // ============ Getters ============
  
  List<model.Income> get incomes => _incomes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get incomeCount => _incomes.length;

  // ============ Métodos de Carga ============

  /// Carga todos los ingresos desde la base de datos
  Future<void> loadIncomes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final dbIncomes = await _database.getAllIncomes();
      _incomes = dbIncomes.map((e) => _mapToModel(e)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar ingresos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga ingresos filtrados por rango de fechas
  Future<List<model.Income>> getIncomesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final dbIncomes = await _database.getIncomesByDateRange(start, end);
      return dbIncomes.map((e) => _mapToModel(e)).toList();
    } catch (e) {
      _error = 'Error al filtrar ingresos: $e';
      notifyListeners();
      return [];
    }
  }

  /// Carga ingresos filtrados por categoría
  Future<List<model.Income>> getIncomesByCategory(String category) async {
    try {
      final dbIncomes = await _database.getIncomesByCategory(category);
      return dbIncomes.map((e) => _mapToModel(e)).toList();
    } catch (e) {
      _error = 'Error al filtrar por categoría: $e';
      notifyListeners();
      return [];
    }
  }

  // ============ Métodos CRUD ============

  /// Crea un nuevo ingreso
  Future<bool> addIncome({
    required double amount,
    required String category,
    required String subcategory,
    required DateTime date,
    String? note,
    required String icon,
    bool isQuickAction = false,
  }) async {
    try {
      final id = _uuid.v4();
      final companion = IncomesCompanion(
        id: drift.Value(id),
        amount: drift.Value(amount),
        category: drift.Value(category),
        subcategory: drift.Value(subcategory),
        date: drift.Value(date),
        note: drift.Value(note),
        icon: drift.Value(icon),
        isQuickAction: drift.Value(isQuickAction),
      );

      await _database.insertIncome(companion);
      await loadIncomes();
      return true;
    } catch (e) {
      _error = 'Error al crear ingreso: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un ingreso existente
  Future<bool> updateIncome(model.Income income) async {
    try {
      final dbIncome = _mapToDb(income);
      await _database.updateIncome(dbIncome);
      await loadIncomes();
      return true;
    } catch (e) {
      _error = 'Error al actualizar ingreso: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina un ingreso
  Future<bool> deleteIncome(String id) async {
    try {
      await _database.deleteIncome(id);
      await loadIncomes();
      return true;
    } catch (e) {
      _error = 'Error al eliminar ingreso: $e';
      notifyListeners();
      return false;
    }
  }

  // ============ Métodos de Cálculo y Estadísticas ============

  /// Calcula el total general de todos los ingresos
  Future<double> getAllTimeTotal() async {
    try {
      final allIncomes = await _database.getAllIncomes();
      return allIncomes.fold<double>(
        0.0,
        (sum, income) => sum + income.amount,
      );
    } catch (e) {
      _error = 'Error al calcular total general: $e';
      notifyListeners();
      return 0.0;
    }
  }

  /// Calcula el total de ingresos en un periodo
  Future<double> getTotalIncomes(DateTime start, DateTime end) async {
    try {
      return await _database.getTotalIncomes(start, end);
    } catch (e) {
      _error = 'Error al calcular total: $e';
      notifyListeners();
      return 0.0;
    }
  }

  /// Obtiene el total de ingresos del mes actual
  Future<double> getMonthlyTotal() async {
    try {
      return await _database.getMonthlyIncomes();
    } catch (e) {
      _error = 'Error al calcular total mensual: $e';
      notifyListeners();
      return 0.0;
    }
  }

  // ============ Mapeo de Modelos ============

  model.Income _mapToModel(Income dbIncome) {
    return model.Income(
      id: dbIncome.id,
      amount: dbIncome.amount,
      category: dbIncome.category,
      subcategory: dbIncome.subcategory,
      date: dbIncome.date,
      note: dbIncome.note,
      icon: dbIncome.icon,
      isQuickAction: dbIncome.isQuickAction,
    );
  }

  Income _mapToDb(model.Income income) {
    return Income(
      id: income.id,
      amount: income.amount,
      category: income.category,
      subcategory: income.subcategory,
      date: income.date,
      note: income.note,
      icon: income.icon,
      isQuickAction: income.isQuickAction,
    );
  }
}
