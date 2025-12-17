/// Modelo de datos para un Ingreso
/// 
/// Representa dinero que entra: nómina, bizums, devoluciones, etc.
class Income {
  /// Identificador único del ingreso
  final String id;
  
  /// Monto del ingreso
  final double amount;
  
  /// Categoría del ingreso (ej: Nómina, Bizum, Venta)
  final String category;
  
  /// Subcategoría del ingreso
  final String subcategory;
  
  /// Fecha y hora del ingreso
  final DateTime date;
  
  /// Nota adicional opcional
  final String? note;
  
  /// Emoji o icono representativo
  final String icon;
  
  /// Indica si es una acción rápida predefinida
  final bool isQuickAction;

  const Income({
    required this.id,
    required this.amount,
    required this.category,
    required this.subcategory,
    required this.date,
    this.note,
    required this.icon,
    this.isQuickAction = false,
  });

  /// Crea una copia del ingreso con valores opcionales modificados
  Income copyWith({
    String? id,
    double? amount,
    String? category,
    String? subcategory,
    DateTime? date,
    String? note,
    String? icon,
    bool? isQuickAction,
  }) {
    return Income(
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
  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
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
  factory Income.fromJson(Map<String, dynamic> json) => Income.fromMap(json);

  @override
  String toString() {
    return 'Income(id: $id, amount: $amount, category: $category, '
        'subcategory: $subcategory, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Income && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
