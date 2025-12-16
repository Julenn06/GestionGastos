import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

/// Tabla de Gastos en la base de datos
/// 
/// Define la estructura de la tabla que almacena todos los gastos del usuario.
class Expenses extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get subcategory => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get icon => text()();
  BoolColumn get isQuickAction => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de Acciones Rápidas en la base de datos
/// 
/// Define la estructura de la tabla que almacena las acciones rápidas
/// predefinidas por el usuario.
class QuickActions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get subcategory => text()();
  TextColumn get icon => text()();
  TextColumn get color => text().nullable()();
  IntColumn get order => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de Inversiones en la base de datos
/// 
/// Define la estructura de la tabla que almacena todas las inversiones
/// del usuario con su valor actual y evolución.
class Investments extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get platform => text().nullable()();
  RealColumn get amountInvested => real()();
  RealColumn get currentValue => real()();
  DateTimeColumn get dateInvested => dateTime()();
  DateTimeColumn get lastUpdate => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get icon => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de Logros en la base de datos
/// 
/// Define la estructura de la tabla que almacena los logros desbloqueados
/// por el usuario como parte del sistema de gamificación.
class Achievements extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get icon => text()();
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Base de datos principal de la aplicación
/// 
/// Implementa todas las operaciones CRUD (Create, Read, Update, Delete)
/// para gestionar gastos, inversiones, acciones rápidas y logros.
/// Utiliza Drift para un acceso type-safe y eficiente a SQLite.
@DriftDatabase(tables: [Expenses, QuickActions, Investments, Achievements])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ==================== OPERACIONES DE GASTOS ====================

  /// Obtiene todos los gastos ordenados por fecha descendente
  Future<List<Expense>> getAllExpenses() async {
    return await select(expenses).get();
  }

  /// Obtiene gastos filtrados por rango de fechas
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    return await (select(expenses)
          ..where((tbl) => tbl.date.isBetweenValues(start, end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]))
        .get();
  }

  /// Obtiene gastos filtrados por categoría
  Future<List<Expense>> getExpensesByCategory(String category) async {
    return await (select(expenses)
          ..where((tbl) => tbl.category.equals(category))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]))
        .get();
  }

  /// Inserta un nuevo gasto
  Future<int> insertExpense(ExpensesCompanion expense) async {
    return await into(expenses).insert(expense);
  }

  /// Actualiza un gasto existente
  Future<bool> updateExpense(Expense expense) async {
    return await update(expenses).replace(expense);
  }

  /// Elimina un gasto
  Future<int> deleteExpense(String id) async {
    return await (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Calcula el total de gastos en un periodo
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    final query = selectOnly(expenses)
      ..addColumns([expenses.amount.sum()])
      ..where(expenses.date.isBetweenValues(start, end));
    
    final result = await query.getSingle();
    return result.read(expenses.amount.sum()) ?? 0.0;
  }

  /// Obtiene el conteo de gastos
  Future<int> getExpenseCount() async {
    final query = selectOnly(expenses)..addColumns([expenses.id.count()]);
    final result = await query.getSingle();
    return result.read(expenses.id.count()) ?? 0;
  }

  // ==================== OPERACIONES DE ACCIONES RÁPIDAS ====================

  /// Obtiene todas las acciones rápidas activas ordenadas
  Future<List<QuickAction>> getActiveQuickActions() async {
    return await (select(quickActions)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]))
        .get();
  }

  /// Obtiene todas las acciones rápidas
  Future<List<QuickAction>> getAllQuickActions() async {
    return await select(quickActions).get();
  }

  /// Inserta una nueva acción rápida
  Future<int> insertQuickAction(QuickActionsCompanion action) async {
    return await into(quickActions).insert(action);
  }

  /// Actualiza una acción rápida
  Future<bool> updateQuickAction(QuickAction action) async {
    return await update(quickActions).replace(action);
  }

  /// Elimina una acción rápida
  Future<int> deleteQuickAction(String id) async {
    return await (delete(quickActions)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ==================== OPERACIONES DE INVERSIONES ====================

  /// Obtiene todas las inversiones
  Future<List<Investment>> getAllInvestments() async {
    return await (select(investments)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastUpdate)]))
        .get();
  }

  /// Obtiene inversiones por tipo
  Future<List<Investment>> getInvestmentsByType(String type) async {
    return await (select(investments)
          ..where((tbl) => tbl.type.equals(type))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastUpdate)]))
        .get();
  }

  /// Inserta una nueva inversión
  Future<int> insertInvestment(InvestmentsCompanion investment) async {
    return await into(investments).insert(investment);
  }

  /// Actualiza una inversión
  Future<bool> updateInvestment(Investment investment) async {
    return await update(investments).replace(investment);
  }

  /// Elimina una inversión
  Future<int> deleteInvestment(String id) async {
    return await (delete(investments)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Calcula el total invertido
  Future<double> getTotalInvested() async {
    final query = selectOnly(investments)
      ..addColumns([investments.amountInvested.sum()]);
    
    final result = await query.getSingle();
    return result.read(investments.amountInvested.sum()) ?? 0.0;
  }

  /// Calcula el valor actual total de inversiones
  Future<double> getTotalCurrentValue() async {
    final query = selectOnly(investments)
      ..addColumns([investments.currentValue.sum()]);
    
    final result = await query.getSingle();
    return result.read(investments.currentValue.sum()) ?? 0.0;
  }

  // ==================== OPERACIONES DE LOGROS ====================

  /// Obtiene todos los logros
  Future<List<Achievement>> getAllAchievements() async {
    return await select(achievements).get();
  }

  /// Obtiene logros desbloqueados
  Future<List<Achievement>> getUnlockedAchievements() async {
    return await (select(achievements)
          ..where((tbl) => tbl.unlockedAt.isNotNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.unlockedAt)]))
        .get();
  }

  /// Inserta un logro
  Future<int> insertAchievement(AchievementsCompanion achievement) async {
    return await into(achievements).insert(achievement);
  }

  /// Desbloquea un logro
  Future<bool> unlockAchievement(String id) async {
    final result = await (update(achievements)..where((tbl) => tbl.id.equals(id)))
        .write(AchievementsCompanion(unlockedAt: Value(DateTime.now())));
    return result > 0;
  }

  /// Obtiene el conteo de logros desbloqueados
  Future<int> getUnlockedAchievementCount() async {
    final query = selectOnly(achievements)
      ..addColumns([achievements.id.count()])
      ..where(achievements.unlockedAt.isNotNull());
    
    final result = await query.getSingle();
    return result.read(achievements.id.count()) ?? 0;
  }
}

/// Abre la conexión a la base de datos SQLite
/// 
/// Crea el archivo de base de datos en el directorio de documentos
/// de la aplicación para persistencia offline.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gestion_gastos.db'));
    return NativeDatabase(file);
  });
}
