/// Modelo de datos para una Acción Rápida de Inversión
/// 
/// Representa una inversión predefinida que se puede actualizar con un solo toque.
/// Útil para inversiones recurrentes (ej: aportación mensual, DCA en crypto).
class QuickInvestment {
  /// Identificador único de la acción rápida
  final String id;
  
  /// Nombre descriptivo de la acción
  final String name;
  
  /// Tipo de inversión (Acciones, ETFs, Crypto, etc.)
  final String type;
  
  /// Monto predefinido a invertir
  final double amount;
  
  /// ID de la inversión existente (si aplica)
  final String? linkedInvestmentId;
  
  /// Nombre o símbolo de la inversión
  final String investmentName;
  
  /// Plataforma o broker
  final String? platform;
  
  /// Emoji o icono representativo
  final String icon;
  
  /// Color personalizado para el botón (en formato hex)
  final String? color;
  
  /// Orden de visualización
  final int order;
  
  /// Indica si está activa (visible en la UI)
  final bool isActive;

  const QuickInvestment({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.linkedInvestmentId,
    required this.investmentName,
    this.platform,
    required this.icon,
    this.color,
    this.order = 0,
    this.isActive = true,
  });

  /// Crea una copia de la acción rápida con valores opcionales modificados
  QuickInvestment copyWith({
    String? id,
    String? name,
    String? type,
    double? amount,
    String? linkedInvestmentId,
    String? investmentName,
    String? platform,
    String? icon,
    String? color,
    int? order,
    bool? isActive,
  }) {
    return QuickInvestment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      linkedInvestmentId: linkedInvestmentId ?? this.linkedInvestmentId,
      investmentName: investmentName ?? this.investmentName,
      platform: platform ?? this.platform,
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
      'type': type,
      'amount': amount,
      'linkedInvestmentId': linkedInvestmentId,
      'investmentName': investmentName,
      'platform': platform,
      'icon': icon,
      'color': color,
      'order': order,
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Crea un modelo desde un Map de la base de datos
  factory QuickInvestment.fromMap(Map<String, dynamic> map) {
    return QuickInvestment(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      linkedInvestmentId: map['linkedInvestmentId'] as String?,
      investmentName: map['investmentName'] as String,
      platform: map['platform'] as String?,
      icon: map['icon'] as String,
      color: map['color'] as String?,
      order: map['order'] as int,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() => toMap();

  /// Crea un modelo desde JSON
  factory QuickInvestment.fromJson(Map<String, dynamic> json) => 
      QuickInvestment.fromMap(json);

  @override
  String toString() {
    return 'QuickInvestment(id: $id, name: $name, type: $type, '
        'amount: $amount, investmentName: $investmentName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QuickInvestment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
