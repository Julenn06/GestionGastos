/// Modelo de datos para un Gasto
/// 
/// Representa un gasto individual con toda su información relevante.
/// Diseñado para ser inmutable y type-safe siguiendo las mejores prácticas de Dart.
class Expense {
  /// Identificador único del gasto
  final String id;
  
  /// Monto del gasto
  final double amount;
  
  /// Categoría principal del gasto (ej: Alimentación, Transporte)
  final String category;
  
  /// Subcategoría del gasto (ej: Restaurantes, Gasolina)
  final String subcategory;
  
  /// Fecha y hora del gasto
  final DateTime date;
  
  /// Nota adicional opcional
  final String? note;
  
  /// Emoji o icono representativo
  final String icon;
  
  /// Indica si es una acción rápida predefinida
  final bool isQuickAction;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.subcategory,
    required this.date,
    this.note,
    required this.icon,
    this.isQuickAction = false,
  });

  /// Crea una copia del gasto con valores opcionales modificados
  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    String? subcategory,
    DateTime? date,
    String? note,
    String? icon,
    bool? isQuickAction,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      date: date ?? this.date,
      note: note ?? this.note,
      icon: icon ?? this.icon,
      isQuickAction: isQuickAction ?? this.isQuickAction,
    );
  }

  /// Convierte el modelo a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'date': date.toIso8601String(),
      'note': note,
      'icon': icon,
      'isQuickAction': isQuickAction ? 1 : 0,
    };
  }

  /// Crea un modelo desde un Map de la base de datos
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      subcategory: map['subcategory'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      icon: map['icon'] as String,
      isQuickAction: (map['isQuickAction'] as int) == 1,
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() => toMap();

  /// Crea un modelo desde JSON
  factory Expense.fromJson(Map<String, dynamic> json) => Expense.fromMap(json);

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, category: $category, '
        'subcategory: $subcategory, date: $date, note: $note, '
        'icon: $icon, isQuickAction: $isQuickAction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
