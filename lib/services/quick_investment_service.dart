import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import '../models/quick_investment.dart' as model;
import 'package:drift/drift.dart' as drift;

/// Servicio de gestión de acciones rápidas de inversiones
/// 
/// Proporciona la lógica de negocio para gestionar las acciones rápidas
/// que permiten al usuario actualizar inversiones recurrentes con un solo toque.
class QuickInvestmentService extends ChangeNotifier {
  final AppDatabase _database;
  final _uuid = const Uuid();

  List<model.QuickInvestment> _quickInvestments = [];
  bool _isLoading = false;
  String? _error;

  QuickInvestmentService(this._database) {
    loadQuickInvestments();
  }

  // ============ Getters ============
  
  List<model.QuickInvestment> get quickInvestments => _quickInvestments;
  List<model.QuickInvestment> get activeQuickInvestments => 
      _quickInvestments.where((qi) => qi.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============ Métodos de Carga ============

  /// Carga todas las acciones rápidas de inversión activas
  Future<void> loadQuickInvestments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final dbInvestments = await _database.getActiveQuickInvestments();
      _quickInvestments = dbInvestments.map((e) => _mapToModel(e)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar acciones rápidas de inversión: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ Métodos CRUD ============

  /// Crea una nueva acción rápida de inversión
  Future<bool> addQuickInvestment({
    required String name,
    required String type,
    required double amount,
    String? linkedInvestmentId,
    required String investmentName,
    String? platform,
    required String icon,
    String? color,
    int? order,
  }) async {
    try {
      final id = _uuid.v4();
      final companion = QuickInvestmentsCompanion(
        id: drift.Value(id),
        name: drift.Value(name),
        type: drift.Value(type),
        amount: drift.Value(amount),
        linkedInvestmentId: drift.Value(linkedInvestmentId),
        investmentName: drift.Value(investmentName),
        platform: drift.Value(platform),
        icon: drift.Value(icon),
        color: drift.Value(color),
        order: drift.Value(order ?? _quickInvestments.length),
        isActive: const drift.Value(true),
      );

      await _database.insertQuickInvestment(companion);
      await loadQuickInvestments();
      return true;
    } catch (e) {
      _error = 'Error al crear acción rápida de inversión: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza una acción rápida de inversión existente
  Future<bool> updateQuickInvestment(model.QuickInvestment investment) async {
    try {
      final dbInvestment = _mapToDb(investment);
      await _database.updateQuickInvestment(dbInvestment);
      await loadQuickInvestments();
      return true;
    } catch (e) {
      _error = 'Error al actualizar acción rápida de inversión: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina una acción rápida de inversión
  Future<bool> deleteQuickInvestment(String id) async {
    try {
      await _database.deleteQuickInvestment(id);
      await loadQuickInvestments();
      return true;
    } catch (e) {
      _error = 'Error al eliminar acción rápida de inversión: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el orden de las inversiones rápidas
  Future<bool> updateOrder(List<model.QuickInvestment> reorderedInvestments) async {
    try {
      // Batch update para mejor rendimiento
      await _database.batch((batch) {
        for (int i = 0; i < reorderedInvestments.length; i++) {
          batch.update(
            _database.quickInvestments,
            QuickInvestmentsCompanion(
              order: drift.Value(i),
            ),
            where: (_) => _database.quickInvestments.id.equals(reorderedInvestments[i].id),
          );
        }
      });
      await loadQuickInvestments();
      return true;
    } catch (e) {
      _error = 'Error al actualizar orden: $e';
      notifyListeners();
      return false;
    }
  }

  /// Inicializa acciones rápidas de inversión predeterminadas
  Future<void> initializeDefaultQuickInvestments() async {
    final existing = await _database.getAllQuickInvestments();
    if (existing.isNotEmpty) return;

    final defaults = [
      QuickInvestmentsCompanion.insert(
        id: 'qi_btc_daily',
        name: 'Bitcoin DCA',
        type: 'Criptomonedas',
        amount: 10.0,
        linkedInvestmentId: const drift.Value(null),
        investmentName: 'BTC',
        platform: const drift.Value('Binance'),
        icon: '₿',
        color: const drift.Value('#F7931A'),
        order: const drift.Value(0),
      ),
      QuickInvestmentsCompanion.insert(
        id: 'qi_sp500_monthly',
        name: 'S&P 500 Mensual',
        type: 'ETFs',
        amount: 100.0,
        linkedInvestmentId: const drift.Value(null),
        investmentName: 'S&P 500',
        platform: const drift.Value('Trading212'),
        icon: '📈',
        color: const drift.Value('#2196F3'),
        order: const drift.Value(1),
      ),
    ];

    for (final default_ in defaults) {
      await _database.insertQuickInvestment(default_);
    }

    await loadQuickInvestments();
  }

  // ============ Mapeo de Modelos ============

  model.QuickInvestment _mapToModel(QuickInvestment dbInvestment) {
    return model.QuickInvestment(
      id: dbInvestment.id,
      name: dbInvestment.name,
      type: dbInvestment.type,
      amount: dbInvestment.amount,
      linkedInvestmentId: dbInvestment.linkedInvestmentId,
      investmentName: dbInvestment.investmentName,
      platform: dbInvestment.platform,
      icon: dbInvestment.icon,
      color: dbInvestment.color,
      order: dbInvestment.order,
      isActive: dbInvestment.isActive,
    );
  }

  QuickInvestment _mapToDb(model.QuickInvestment investment) {
    return QuickInvestment(
      id: investment.id,
      name: investment.name,
      type: investment.type,
      amount: investment.amount,
      linkedInvestmentId: investment.linkedInvestmentId,
      investmentName: investment.investmentName,
      platform: investment.platform,
      icon: investment.icon,
      color: investment.color,
      order: investment.order,
      isActive: investment.isActive,
    );
  }
}
