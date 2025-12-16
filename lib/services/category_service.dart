import 'package:flutter/material.dart';
import '../data/database.dart';
import '../core/utils/log_service.dart';
import 'package:drift/drift.dart' as drift;

/// Servicio para gestionar categorías personalizadas
/// 
/// Proporciona funcionalidades para crear, editar, eliminar y
/// consultar categorías de gastos e ingresos.
class CategoryService extends ChangeNotifier {
  final AppDatabase _database;

  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryService(this._database) {
    loadCategories();
  }

  /// Carga todas las categorías
  Future<void> loadCategories({String? type}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _categories = await _database.getAllCategories(type: type);
      
      LogService.info('Categorías cargadas: ${_categories.length}');
    } catch (e) {
      LogService.error('Error al cargar categorías', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene categorías de gastos
  Future<List<Category>> getExpenseCategories() async {
    try {
      return await _database.getAllCategories(type: 'expense');
    } catch (e) {
      LogService.error('Error al obtener categorías de gastos', e);
      return [];
    }
  }

  /// Obtiene categorías de ingresos
  Future<List<Category>> getIncomeCategories() async {
    try {
      return await _database.getAllCategories(type: 'income');
    } catch (e) {
      LogService.error('Error al obtener categorías de ingresos', e);
      return [];
    }
  }

  /// Crea una nueva categoría
  Future<bool> createCategory({
    required String name,
    required String icon,
    required String color,
    required String type,
  }) async {
    try {
      final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
      
      final category = CategoriesCompanion.insert(
        id: id,
        name: name,
        icon: icon,
        color: color,
        type: type,
        isDefault: const drift.Value(false),
        createdAt: DateTime.now(),
      );

      await _database.insertCategory(category);
      await loadCategories();
      
      LogService.info('Categoría creada: $name');
      return true;
    } catch (e) {
      LogService.error('Error al crear categoría', e);
      return false;
    }
  }

  /// Actualiza una categoría existente
  Future<bool> updateCategory(Category category) async {
    try {
      if (category.isDefault) {
        LogService.warning('No se pueden editar categorías predeterminadas');
        return false;
      }

      final success = await _database.updateCategory(category);
      if (success) {
        await loadCategories();
        LogService.info('Categoría actualizada: ${category.name}');
      }
      
      return success;
    } catch (e) {
      LogService.error('Error al actualizar categoría', e);
      return false;
    }
  }

  /// Elimina una categoría
  Future<bool> deleteCategory(String id) async {
    try {
      final category = await _database.getCategoryById(id);
      
      if (category == null) {
        LogService.warning('Categoría no encontrada: $id');
        return false;
      }

      if (category.isDefault) {
        LogService.warning('No se pueden eliminar categorías predeterminadas');
        return false;
      }

      // Verificar si tiene gastos asociados
      final hasExpenses = await _database.categoryHasExpenses(category.name);
      if (hasExpenses) {
        LogService.warning('No se puede eliminar categoría con gastos asociados');
        return false;
      }

      final result = await _database.deleteCategory(id);
      if (result > 0) {
        await loadCategories();
        LogService.info('Categoría eliminada: ${category.name}');
        return true;
      }
      
      return false;
    } catch (e) {
      LogService.error('Error al eliminar categoría', e);
      return false;
    }
  }

  /// Obtiene una categoría por nombre
  Future<Category?> getCategoryByName(String name) async {
    try {
      return _categories.firstWhere(
        (cat) => cat.name == name,
        orElse: () => throw Exception('Categoría no encontrada'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el color de una categoría por nombre
  Color getCategoryColor(String categoryName) {
    try {
      final category = _categories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => throw Exception('Categoría no encontrada'),
      );
      return _parseColor(category.color);
    } catch (e) {
      return Colors.grey;
    }
  }

  /// Obtiene el icono de una categoría por nombre
  String getCategoryIcon(String categoryName) {
    try {
      final category = _categories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => throw Exception('Categoría no encontrada'),
      );
      return category.icon;
    } catch (e) {
      return '📦';
    }
  }

  /// Convierte un string hexadecimal a Color
  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  /// Convierte un Color a string hexadecimal
  String colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Obtiene nombres de todas las categorías
  List<String> getCategoryNames({String? type}) {
    if (type != null) {
      return _categories
          .where((cat) => cat.type == type)
          .map((cat) => cat.name)
          .toList();
    }
    return _categories.map((cat) => cat.name).toList();
  }
}
