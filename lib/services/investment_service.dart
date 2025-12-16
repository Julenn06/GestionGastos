import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import '../models/investment.dart' as model;
import 'package:drift/drift.dart' as drift;

/// Servicio de gestión de inversiones
/// 
/// Proporciona la lógica de negocio para todas las operaciones relacionadas
/// con inversiones, incluyendo CRUD, cálculos de rendimiento y estadísticas.
class InvestmentService extends ChangeNotifier {
  final AppDatabase _database;
  final _uuid = const Uuid();

  List<model.Investment> _investments = [];
  bool _isLoading = false;
  String? _error;

  InvestmentService(this._database) {
    loadInvestments();
  }

  // ============ Getters ============
  
  List<model.Investment> get investments => _investments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get investmentCount => _investments.length;

  // ============ Métodos de Carga ============

  /// Carga todas las inversiones desde la base de datos
  Future<void> loadInvestments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final dbInvestments = await _database.getAllInvestments();
      _investments = dbInvestments.map((e) => _mapToModel(e)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar inversiones: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga inversiones filtradas por tipo
  Future<List<model.Investment>> getInvestmentsByType(String type) async {
    try {
      final dbInvestments = await _database.getInvestmentsByType(type);
      return dbInvestments.map((e) => _mapToModel(e)).toList();
    } catch (e) {
      _error = 'Error al filtrar inversiones: $e';
      notifyListeners();
      return [];
    }
  }

  // ============ Métodos CRUD ============

  /// Crea una nueva inversión
  Future<bool> addInvestment({
    required String type,
    required String name,
    String? platform,
    required double amountInvested,
    required double currentValue,
    required DateTime dateInvested,
    String? notes,
    required String icon,
  }) async {
    try {
      final id = _uuid.v4();
      final companion = InvestmentsCompanion(
        id: drift.Value(id),
        type: drift.Value(type),
        name: drift.Value(name),
        platform: drift.Value(platform),
        amountInvested: drift.Value(amountInvested),
        currentValue: drift.Value(currentValue),
        dateInvested: drift.Value(dateInvested),
        lastUpdate: drift.Value(DateTime.now()),
        notes: drift.Value(notes),
        icon: drift.Value(icon),
      );

      await _database.insertInvestment(companion);
      await loadInvestments();
      return true;
    } catch (e) {
      _error = 'Error al crear inversión: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza una inversión existente
  Future<bool> updateInvestment(model.Investment investment) async {
    try {
      final dbInvestment = _mapToDb(investment);
      await _database.updateInvestment(dbInvestment);
      await loadInvestments();
      return true;
    } catch (e) {
      _error = 'Error al actualizar inversión: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza solo el valor actual de una inversión
  Future<bool> updateInvestmentValue(String id, double newValue) async {
    try {
      final investment = _investments.firstWhere((inv) => inv.id == id);
      final updated = investment.copyWith(
        currentValue: newValue,
        lastUpdate: DateTime.now(),
      );
      return await updateInvestment(updated);
    } catch (e) {
      _error = 'Error al actualizar valor: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina una inversión
  Future<bool> deleteInvestment(String id) async {
    try {
      await _database.deleteInvestment(id);
      await loadInvestments();
      return true;
    } catch (e) {
      _error = 'Error al eliminar inversión: $e';
      notifyListeners();
      return false;
    }
  }

  // ============ Métodos de Cálculo y Estadísticas ============

  /// Calcula el total invertido
  Future<double> getTotalInvested() async {
    try {
      return await _database.getTotalInvested();
    } catch (e) {
      _error = 'Error al calcular total invertido: $e';
      notifyListeners();
      return 0.0;
    }
  }

  /// Calcula el valor actual total de todas las inversiones
  Future<double> getTotalCurrentValue() async {
    try {
      return await _database.getTotalCurrentValue();
    } catch (e) {
      _error = 'Error al calcular valor actual: $e';
      notifyListeners();
      return 0.0;
    }
  }

  /// Calcula la ganancia o pérdida total
  Future<double> getTotalProfitLoss() async {
    final invested = await getTotalInvested();
    final current = await getTotalCurrentValue();
    return current - invested;
  }

  /// Calcula el porcentaje de ganancia o pérdida total
  Future<double> getTotalProfitLossPercentage() async {
    final invested = await getTotalInvested();
    if (invested == 0) return 0;
    
    final current = await getTotalCurrentValue();
    return ((current - invested) / invested) * 100;
  }

  /// Obtiene inversiones agrupadas por tipo con sus totales
  Future<Map<String, double>> getInvestmentsByTypeWithTotals() async {
    final Map<String, double> typeTotals = {};

    for (final investment in _investments) {
      typeTotals[investment.type] = 
          (typeTotals[investment.type] ?? 0) + investment.currentValue;
    }

    return typeTotals;
  }

  /// Obtiene el rendimiento por tipo de inversión
  Future<Map<String, double>> getPerformanceByType() async {
    final Map<String, double> typePerformance = {};
    final Map<String, double> typeInvested = {};

    for (final investment in _investments) {
      typePerformance[investment.type] = 
          (typePerformance[investment.type] ?? 0) + investment.currentValue;
      typeInvested[investment.type] = 
          (typeInvested[investment.type] ?? 0) + investment.amountInvested;
    }

    final Map<String, double> performance = {};
    for (final type in typePerformance.keys) {
      final invested = typeInvested[type] ?? 0;
      if (invested > 0) {
        final current = typePerformance[type] ?? 0;
        performance[type] = ((current - invested) / invested) * 100;
      }
    }

    return performance;
  }

  /// Obtiene las mejores inversiones (top performers)
  List<model.Investment> getTopPerformers({int limit = 5}) {
    final sorted = List<model.Investment>.from(_investments);
    sorted.sort((a, b) => b.profitLossPercentage.compareTo(a.profitLossPercentage));
    return sorted.take(limit).toList();
  }

  /// Obtiene las peores inversiones
  List<model.Investment> getWorstPerformers({int limit = 5}) {
    final sorted = List<model.Investment>.from(_investments);
    sorted.sort((a, b) => a.profitLossPercentage.compareTo(b.profitLossPercentage));
    return sorted.take(limit).toList();
  }

  // ============ Métodos de Mapeo ============

  /// Convierte un objeto de base de datos a modelo
  model.Investment _mapToModel(Investment dbInvestment) {
    return model.Investment(
      id: dbInvestment.id,
      type: dbInvestment.type,
      name: dbInvestment.name,
      platform: dbInvestment.platform,
      amountInvested: dbInvestment.amountInvested,
      currentValue: dbInvestment.currentValue,
      dateInvested: dbInvestment.dateInvested,
      lastUpdate: dbInvestment.lastUpdate,
      notes: dbInvestment.notes,
      icon: dbInvestment.icon,
    );
  }

  /// Convierte un modelo a objeto de base de datos
  Investment _mapToDb(model.Investment investment) {
    return Investment(
      id: investment.id,
      type: investment.type,
      name: investment.name,
      platform: investment.platform,
      amountInvested: investment.amountInvested,
      currentValue: investment.currentValue,
      dateInvested: investment.dateInvested,
      lastUpdate: investment.lastUpdate,
      notes: investment.notes,
      icon: investment.icon,
    );
  }
}
