/// Modelo de datos para una Acción Rápida
/// 
/// Representa un gasto predefinido que se puede registrar con un solo toque.
/// Útil para gastos frecuentes y recurrentes (ej: café diario, transporte).
class QuickAction {
  /// Identificador único de la acción rápida
  final String id;
  
  /// Nombre descriptivo de la acción
  final String name;
  
  /// Monto predefinido del gasto
  final double amount;
  
  /// Categoría asociada
  final String category;
  
  /// Subcategoría asociada
  final String subcategory;
  
  /// Emoji o icono representativo
  final String icon;
  
  /// Color personalizado para el botón (en formato hex)
  final String? color;
  
  /// Orden de visualización (para ordenar los botones)
  final int order;
  
  /// Indica si está activa (visible en la UI)
  final bool isActive;

  const QuickAction({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.subcategory,
    required this.icon,
    this.color,
    this.order = 0,
    this.isActive = true,
  });

  /// Crea una copia de la acción rápida con valores opcionales modificados
  QuickAction copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    String? subcategory,
    String? icon,
    String? color,
    int? order,
    bool? isActive,
  }) {
    return QuickAction(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convierte el modelo a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'icon': icon,
      'color': color,
      'order': order,
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Crea un modelo desde un Map de la base de datos
  factory QuickAction.fromMap(Map<String, dynamic> map) {
    return QuickAction(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      subcategory: map['subcategory'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String?,
      order: map['order'] as int,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() => toMap();

  /// Crea un modelo desde JSON
  factory QuickAction.fromJson(Map<String, dynamic> json) => QuickAction.fromMap(json);

  @override
  String toString() {
    return 'QuickAction(id: $id, name: $name, amount: $amount, '
        'category: $category, subcategory: $subcategory, '
        'icon: $icon, color: $color, order: $order, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QuickAction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
