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

/// Tabla de Categorías Personalizadas en la base de datos
/// 
/// Define la estructura de la tabla que almacena categorías personalizadas
/// creadas por el usuario con sus iconos y colores asociados.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get type => text()(); // 'expense' o 'income'
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de Acciones Rápidas de Inversiones en la base de datos
/// 
/// Define la estructura de la tabla que almacena las acciones rápidas
/// para inversiones recurrentes.
class QuickInvestments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get linkedInvestmentId => text().nullable()();
  TextColumn get investmentName => text()();
  TextColumn get platform => text().nullable()();
  TextColumn get icon => text()();
  TextColumn get color => text().nullable()();
  IntColumn get order => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de Ingresos en la base de datos
/// 
/// Define la estructura de la tabla que almacena todos los ingresos del usuario.
class Incomes extends Table {
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

/// Base de datos principal de la aplicación
/// 
/// Implementa todas las operaciones CRUD (Create, Read, Update, Delete)
/// para gestionar gastos, inversiones, acciones rápidas y logros.
/// Utiliza Drift para un acceso type-safe y eficiente a SQLite.
@DriftDatabase(tables: [Expenses, QuickActions, Investments, Achievements, Categories, QuickInvestments, Incomes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insertar categorías predeterminadas
        await _insertDefaultCategories();
        // Crear índices para optimizar consultas
        await _createIndexes();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(categories);
          await _insertDefaultCategories();
        }
        if (from < 3) {
          await m.createTable(quickInvestments);
        }
        if (from < 4) {
          await m.createTable(incomes);
        }
        if (from < 5) {
          // Versión 5: Agregar índices para optimizar rendimiento
          await _createIndexes();
        }
      },
    );
  }

  /// Crea índices en las tablas para optimizar consultas frecuentes
  Future<void> _createIndexes() async {
    // Índices para Expenses
    await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_category_date ON expenses(category, date);');
    
    // Índices para Investments
    await customStatement('CREATE INDEX IF NOT EXISTS idx_investments_type ON investments(type);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_investments_date ON investments(date_invested);');
    
    // Índices para Incomes
    await customStatement('CREATE INDEX IF NOT EXISTS idx_incomes_category ON incomes(category);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_incomes_date ON incomes(date);');
  }

  /// Inserta las categorías predeterminadas al crear la BD
  Future<void> _insertDefaultCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(
        id: 'cat_alimentacion',
        name: 'Alimentación',
        icon: '🍔',
        color: '#FF9800',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
      CategoriesCompanion.insert(
        id: 'cat_transporte',
        name: 'Transporte',
        icon: '🚗',
        color: '#2196F3',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
      CategoriesCompanion.insert(
        id: 'cat_vivienda',
        name: 'Vivienda',
        icon: '🏠',
        color: '#4CAF50',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
      CategoriesCompanion.insert(
        id: 'cat_entretenimiento',
        name: 'Entretenimiento',
        icon: '🎮',
        color: '#E91E63',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
      CategoriesCompanion.insert(
        id: 'cat_salud',
        name: 'Salud',
        icon: '⚕️',
        color: '#F44336',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
      CategoriesCompanion.insert(
        id: 'cat_educacion',
        name: 'Educación',
        icon: '📚',
        color: '#9C27B0',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
      CategoriesCompanion.insert(
        id: 'cat_ropa',
        name: 'Ropa',
        icon: '👕',
        color: '#FF5722',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
      CategoriesCompanion.insert(
        id: 'cat_tecnologia',
        name: 'Tecnología',
        icon: '💻',
        color: '#607D8B',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
      CategoriesCompanion.insert(
        id: 'cat_servicios',
        name: 'Servicios',
        icon: '🔧',
        color: '#795548',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
      CategoriesCompanion.insert(
        id: 'cat_otros',
        name: 'Otros',
        icon: '📦',
        color: '#9E9E9E',
        type: 'expense',
        isDefault: const Value(true),
        createdAt: DateTime.now(),
      ),
    ];

    for (final category in defaultCategories) {
      await into(categories).insert(
        category,
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

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

  // ==================== OPERACIONES DE CATEGORÍAS ====================

  /// Obtiene todas las categorías de gastos
  Future<List<Category>> getAllCategories({String? type}) async {
    final query = select(categories);
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    return await (query..orderBy([(tbl) => OrderingTerm.asc(tbl.name)])).get();
  }

  /// Obtiene una categoría por ID
  Future<Category?> getCategoryById(String id) async {
    return await (select(categories)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserta una nueva categoría
  Future<int> insertCategory(CategoriesCompanion category) async {
    return await into(categories).insert(category);
  }

  /// Actualiza una categoría
  Future<bool> updateCategory(Category category) async {
    return await update(categories).replace(category);
  }

  /// Elimina una categoría (solo si no es predeterminada)
  Future<int> deleteCategory(String id) async {
    return await (delete(categories)
          ..where((tbl) => tbl.id.equals(id) & tbl.isDefault.equals(false)))
        .go();
  }

  /// Verifica si una categoría tiene gastos asociados
  Future<bool> categoryHasExpenses(String categoryName) async {
    final query = selectOnly(expenses)
      ..addColumns([expenses.id.count()])
      ..where(expenses.category.equals(categoryName));
    
    final result = await query.getSingle();
    final count = result.read(expenses.id.count()) ?? 0;
    return count > 0;
  }

  // ==================== OPERACIONES DE ACCIONES RÁPIDAS DE INVERSIONES ====================

  /// Obtiene todas las acciones rápidas de inversión activas
  Future<List<QuickInvestment>> getActiveQuickInvestments() async {
    return await (select(quickInvestments)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]))
        .get();
  }

  /// Obtiene todas las acciones rápidas de inversión
  Future<List<QuickInvestment>> getAllQuickInvestments() async {
    return await (select(quickInvestments)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]))
        .get();
  }

  /// Inserta una acción rápida de inversión
  Future<int> insertQuickInvestment(QuickInvestmentsCompanion quickInvestment) async {
    return await into(quickInvestments).insert(quickInvestment);
  }

  /// Actualiza una acción rápida de inversión
  Future<bool> updateQuickInvestment(QuickInvestment quickInvestment) async {
    return await update(quickInvestments).replace(quickInvestment);
  }

  /// Elimina una acción rápida de inversión
  Future<int> deleteQuickInvestment(String id) async {
    return await (delete(quickInvestments)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ==================== OPERACIONES DE INGRESOS ====================

  /// Obtiene todos los ingresos
  Future<List<Income>> getAllIncomes() async {
    return await (select(incomes)..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])).get();
  }

  /// Obtiene ingresos por rango de fechas
  Future<List<Income>> getIncomesByDateRange(DateTime start, DateTime end) async {
    return await (select(incomes)
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]))
        .get();
  }

  /// Obtiene ingresos por categoría
  Future<List<Income>> getIncomesByCategory(String category) async {
    return await (select(incomes)
          ..where((tbl) => tbl.category.equals(category))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]))
        .get();
  }

  /// Inserta un ingreso
  Future<int> insertIncome(IncomesCompanion income) async {
    return await into(incomes).insert(income);
  }

  /// Actualiza un ingreso
  Future<bool> updateIncome(Income income) async {
    return await update(incomes).replace(income);
  }

  /// Elimina un ingreso
  Future<int> deleteIncome(String id) async {
    return await (delete(incomes)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Obtiene el total de ingresos en un periodo
  Future<double> getTotalIncomes(DateTime start, DateTime end) async {
    final query = selectOnly(incomes)
      ..addColumns([incomes.amount.sum()])
      ..where(incomes.date.isBiggerOrEqualValue(start) & incomes.date.isSmallerOrEqualValue(end));

    final result = await query.getSingle();
    return result.read(incomes.amount.sum()) ?? 0.0;
  }

  /// Obtiene el total de ingresos del mes actual
  Future<double> getMonthlyIncomes() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return await getTotalIncomes(startOfMonth, endOfMonth);
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
    return NativeDatabase(
      file,
      logStatements: false, // Desactivar logs SQL en producción
    );
  });
}
