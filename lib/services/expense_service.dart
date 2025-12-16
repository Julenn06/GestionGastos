import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import '../models/expense.dart' as model;
import 'package:drift/drift.dart' as drift;

/// Servicio de gestión de gastos
/// 
/// Proporciona la lógica de negocio para todas las operaciones relacionadas
/// con gastos, incluyendo CRUD, cálculos y estadísticas.
class ExpenseService extends ChangeNotifier {
  final AppDatabase _database;
  final _uuid = const Uuid();

  List<model.Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  ExpenseService(this._database) {
    loadExpenses();
  }

  // ============ Getters ============
  
  List<model.Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get expenseCount => _expenses.length;

  // ============ Métodos de Carga ============

  /// Carga todos los gastos desde la base de datos
  Future<void> loadExpenses() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final dbExpenses = await _database.getAllExpenses();
      _expenses = dbExpenses.map((e) => _mapToModel(e)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar gastos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga gastos filtrados por rango de fechas
  Future<List<model.Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final dbExpenses = await _database.getExpensesByDateRange(start, end);
      return dbExpenses.map((e) => _mapToModel(e)).toList();
    } catch (e) {
      _error = 'Error al filtrar gastos: $e';
      notifyListeners();
      return [];
    }
  }

  /// Carga gastos filtrados por categoría
  Future<List<model.Expense>> getExpensesByCategory(String category) async {
    try {
      final dbExpenses = await _database.getExpensesByCategory(category);
      return dbExpenses.map((e) => _mapToModel(e)).toList();
    } catch (e) {
      _error = 'Error al filtrar por categoría: $e';
      notifyListeners();
      return [];
    }
  }

  // ============ Métodos CRUD ============

  /// Crea un nuevo gasto
  Future<bool> addExpense({
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
      final companion = ExpensesCompanion(
        id: drift.Value(id),
        amount: drift.Value(amount),
        category: drift.Value(category),
        subcategory: drift.Value(subcategory),
        date: drift.Value(date),
        note: drift.Value(note),
        icon: drift.Value(icon),
        isQuickAction: drift.Value(isQuickAction),
      );

      await _database.insertExpense(companion);
      await loadExpenses();
      return true;
    } catch (e) {
      _error = 'Error al crear gasto: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un gasto existente
  Future<bool> updateExpense(model.Expense expense) async {
    try {
      final dbExpense = _mapToDb(expense);
      await _database.updateExpense(dbExpense);
      await loadExpenses();
      return true;
    } catch (e) {
      _error = 'Error al actualizar gasto: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina un gasto
  Future<bool> deleteExpense(String id) async {
    try {
      await _database.deleteExpense(id);
      await loadExpenses();
      return true;
    } catch (e) {
      _error = 'Error al eliminar gasto: $e';
      notifyListeners();
      return false;
    }
  }

  // ============ Métodos de Cálculo y Estadísticas ============

  /// Calcula el total de gastos en un periodo
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    try {
      return await _database.getTotalExpenses(start, end);
    } catch (e) {
      _error = 'Error al calcular total: $e';
      notifyListeners();
      return 0.0;
    }
  }

  /// Obtiene el total de gastos del mes actual
  Future<double> getMonthlyTotal() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return await getTotalExpenses(start, end);
  }

  /// Obtiene el total de gastos de la semana actual
  Future<double> getWeeklyTotal() async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return await getTotalExpenses(startOfWeek, endOfWeek);
  }

  /// Obtiene el total de gastos del día actual
  Future<double> getTodayTotal() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return await getTotalExpenses(start, end);
  }

  /// Obtiene gastos agrupados por categoría para el mes actual
  Future<Map<String, double>> getMonthlyExpensesByCategory() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    final expenses = await getExpensesByDateRange(start, end);
    final Map<String, double> categoryTotals = {};

    for (final expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  /// Obtiene gastos agrupados por subcategoría
  Future<Map<String, double>> getExpensesBySubcategory(String category) async {
    final expenses = await getExpensesByCategory(category);
    final Map<String, double> subcategoryTotals = {};

    for (final expense in expenses) {
      subcategoryTotals[expense.subcategory] = 
          (subcategoryTotals[expense.subcategory] ?? 0) + expense.amount;
    }

    return subcategoryTotals;
  }

  /// Obtiene el promedio diario de gastos del mes actual
  Future<double> getMonthlyDailyAverage() async {
    final now = DateTime.now();
    final total = await getMonthlyTotal();
    return total / now.day;
  }

  // ============ Métodos de Mapeo ============

  /// Convierte un objeto de base de datos a modelo
  model.Expense _mapToModel(Expense dbExpense) {
    return model.Expense(
      id: dbExpense.id,
      amount: dbExpense.amount,
      category: dbExpense.category,
      subcategory: dbExpense.subcategory,
      date: dbExpense.date,
      note: dbExpense.note,
      icon: dbExpense.icon,
      isQuickAction: dbExpense.isQuickAction,
    );
  }

  /// Convierte un modelo a objeto de base de datos
  Expense _mapToDb(model.Expense expense) {
    return Expense(
      id: expense.id,
      amount: expense.amount,
      category: expense.category,
      subcategory: expense.subcategory,
      date: expense.date,
      note: expense.note,
      icon: expense.icon,
      isQuickAction: expense.isQuickAction,
    );
  }
}
