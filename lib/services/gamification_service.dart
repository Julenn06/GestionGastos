import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database.dart';
import '../models/achievement.dart' as model;
import '../core/constants/app_constants.dart';
import 'package:drift/drift.dart' as drift;

/// Servicio de gamificación
/// 
/// Gestiona logros, rachas (streaks) y sistema de recompensas
/// para motivar al usuario a usar la aplicación constantemente.
class GamificationService extends ChangeNotifier {
  final AppDatabase _database;
  final SharedPreferences _prefs;

  List<model.Achievement> _achievements = [];
  int _currentStreak = 0;
  DateTime? _lastStreakDate;
  bool _isLoading = false;
  String? _error;

  GamificationService(this._database, this._prefs) {
    _loadStreakData();
    loadAchievements();
  }

  // ============ Getters ============
  
  List<model.Achievement> get achievements => _achievements;
  List<model.Achievement> get unlockedAchievements => 
      _achievements.where((a) => a.isUnlocked).toList();
  List<model.Achievement> get lockedAchievements => 
      _achievements.where((a) => !a.isUnlocked).toList();
  int get currentStreak => _currentStreak;
  DateTime? get lastStreakDate => _lastStreakDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unlockedCount => unlockedAchievements.length;
  int get totalAchievements => _achievements.length;
  double get completionPercentage => 
      totalAchievements > 0 ? (unlockedCount / totalAchievements) * 100 : 0;

  // ============ Métodos de Carga ============

  /// Carga todos los logros desde la base de datos
  Future<void> loadAchievements() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final dbAchievements = await _database.getAllAchievements();
      _achievements = dbAchievements.map((e) => _mapToModel(e)).toList();

      // Si no hay logros, inicializar los predefinidos
      if (_achievements.isEmpty) {
        await _initializeDefaultAchievements();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar logros: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga datos de racha desde SharedPreferences
  void _loadStreakData() {
    _currentStreak = _prefs.getInt(AppConstants.currentStreakKey) ?? 0;
    final lastDateStr = _prefs.getString(AppConstants.lastStreakDateKey);
    if (lastDateStr != null) {
      _lastStreakDate = DateTime.parse(lastDateStr);
    }
  }

  // ============ Métodos de Logros ============

  /// Desbloquea un logro específico
  Future<bool> unlockAchievement(String achievementId) async {
    try {
      final achievement = _achievements.firstWhere((a) => a.id == achievementId);
      
      // Si ya está desbloqueado, no hacer nada
      if (achievement.isUnlocked) {
        return false;
      }

      await _database.unlockAchievement(achievementId);
      await loadAchievements();
      
      return true; // Retorna true para indicar que se desbloqueó un nuevo logro
    } catch (e) {
      _error = 'Error al desbloquear logro: $e';
      notifyListeners();
      return false;
    }
  }

  /// Verifica y desbloquea logros basados en el número de gastos
  Future<void> checkExpenseAchievements(int expenseCount) async {
    if (expenseCount >= 1) {
      await unlockAchievement('first_expense');
    }
    if (expenseCount >= 100) {
      await unlockAchievement('expense_master');
    }
  }

  /// Verifica y desbloquea logros basados en inversiones
  Future<void> checkInvestmentAchievements(int investmentCount) async {
    if (investmentCount >= 1) {
      await unlockAchievement('first_investment');
    }
  }

  /// Desbloquea el logro de exportación de datos
  Future<void> unlockExportAchievement() async {
    await unlockAchievement('export_data');
  }

  // ============ Métodos de Rachas (Streaks) ============

  /// Actualiza la racha del usuario
  Future<void> updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastStreakDate == null) {
      // Primera vez que se registra un gasto
      _currentStreak = 1;
      _lastStreakDate = today;
    } else {
      final lastDate = DateTime(
        _lastStreakDate!.year,
        _lastStreakDate!.month,
        _lastStreakDate!.day,
      );

      final difference = today.difference(lastDate).inDays;

      if (difference == 0) {
        // Mismo día, no hacer nada
        return;
      } else if (difference == 1) {
        // Día consecutivo, aumentar racha
        _currentStreak++;
        _lastStreakDate = today;
      } else {
        // Se rompió la racha, reiniciar
        _currentStreak = 1;
        _lastStreakDate = today;
      }
    }

    // Guardar en SharedPreferences
    await _prefs.setInt(AppConstants.currentStreakKey, _currentStreak);
    await _prefs.setString(
      AppConstants.lastStreakDateKey,
      _lastStreakDate!.toIso8601String(),
    );

    // Verificar logros de racha
    await _checkStreakAchievements();

    notifyListeners();
  }

  /// Verifica y desbloquea logros basados en rachas
  Future<void> _checkStreakAchievements() async {
    if (_currentStreak >= 7) {
      await unlockAchievement('week_streak');
    }
    if (_currentStreak >= 30) {
      await unlockAchievement('month_streak');
    }
  }

  /// Reinicia la racha manualmente
  Future<void> resetStreak() async {
    _currentStreak = 0;
    _lastStreakDate = null;
    await _prefs.remove(AppConstants.currentStreakKey);
    await _prefs.remove(AppConstants.lastStreakDateKey);
    notifyListeners();
  }

  // ============ Inicialización de Logros Predefinidos ============

  Future<void> _initializeDefaultAchievements() async {
    final defaultAchievements = AppConstants.achievements;

    for (final entry in defaultAchievements.entries) {
      final id = entry.key;
      final data = entry.value as Map<String, dynamic>;
      
      final companion = AchievementsCompanion(
        id: drift.Value(id),
        title: drift.Value(data['title'] as String),
        description: drift.Value(data['description'] as String),
        icon: drift.Value(data['icon'] as String),
        unlockedAt: const drift.Value(null),
      );

      await _database.insertAchievement(companion);
    }

    await loadAchievements();
  }

  // ============ Métodos de Mapeo ============

  /// Convierte un objeto de base de datos a modelo
  model.Achievement _mapToModel(Achievement dbAchievement) {
    return model.Achievement(
      id: dbAchievement.id,
      title: dbAchievement.title,
      description: dbAchievement.description,
      icon: dbAchievement.icon,
      unlockedAt: dbAchievement.unlockedAt,
    );
  }
}
