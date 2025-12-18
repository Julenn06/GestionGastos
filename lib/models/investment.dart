/// Modelo de datos para una Inversión
/// 
/// Representa una inversión financiera con su valor actual y evolución.
/// Soporta múltiples tipos de inversión (acciones, ETFs, crypto, etc.).
class Investment {
  /// Identificador único de la inversión
  final String id;
  
  /// Tipo de inversión (Acciones, ETFs, Crypto, etc.)
  final String type;
  
  /// Nombre o símbolo de la inversión (ej: AAPL, BTC)
  final String name;
  
  /// Plataforma o broker donde se realiza la inversión
  final String? platform;
  
  /// Cantidad monetaria invertida inicialmente
  final double amountInvested;
  
  /// Valor actual de la inversión
  final double currentValue;
  
  /// Fecha de la inversión inicial
  final DateTime dateInvested;
  
  /// Fecha de la última actualización del valor
  final DateTime lastUpdate;
  
  /// Notas adicionales sobre la inversión
  final String? notes;
  
  /// Icono o emoji representativo
  final String icon;

  // Cache para evitar recalcular en cada acceso
  double? _cachedProfitLoss;
  double? _cachedProfitLossPercentage;

  Investment({
    required this.id,
    required this.type,
    required this.name,
    this.platform,
    required this.amountInvested,
    required this.currentValue,
    required this.dateInvested,
    required this.lastUpdate,
    this.notes,
    required this.icon,
  });

  /// Calcula la ganancia o pérdida absoluta (cached)
  double get profitLoss {
    _cachedProfitLoss ??= currentValue - amountInvested;
    return _cachedProfitLoss!;
  }

  /// Calcula el porcentaje de ganancia o pérdida (cached)
  double get profitLossPercentage {
    if (_cachedProfitLossPercentage != null) return _cachedProfitLossPercentage!;
    if (amountInvested == 0) {
      _cachedProfitLossPercentage = 0;
      return 0;
    }
    _cachedProfitLossPercentage = ((currentValue - amountInvested) / amountInvested) * 100;
    return _cachedProfitLossPercentage!;
  }

  /// Indica si la inversión está en positivo
  bool get isProfit => profitLoss > 0;

  /// Indica si la inversión está en negativo
  bool get isLoss => profitLoss < 0;

  /// Crea una copia de la inversión con valores opcionales modificados
  Investment copyWith({
    String? id,
    String? type,
    String? name,
    String? platform,
    double? amountInvested,
    double? currentValue,
    DateTime? dateInvested,
    DateTime? lastUpdate,
    String? notes,
    String? icon,
  }) {
    return Investment(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      amountInvested: amountInvested ?? this.amountInvested,
      currentValue: currentValue ?? this.currentValue,
      dateInvested: dateInvested ?? this.dateInvested,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      notes: notes ?? this.notes,
      icon: icon ?? this.icon,
    );
  }

  /// Convierte el modelo a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'platform': platform,
      'amountInvested': amountInvested,
      'currentValue': currentValue,
      'dateInvested': dateInvested.toIso8601String(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'notes': notes,
      'icon': icon,
    };
  }

  /// Crea un modelo desde un Map de la base de datos
  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'] as String,
      type: map['type'] as String,
      name: map['name'] as String,
      platform: map['platform'] as String?,
      amountInvested: (map['amountInvested'] as num).toDouble(),
      currentValue: (map['currentValue'] as num).toDouble(),
      dateInvested: DateTime.parse(map['dateInvested'] as String),
      lastUpdate: DateTime.parse(map['lastUpdate'] as String),
      notes: map['notes'] as String?,
      icon: map['icon'] as String,
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() => toMap();

  /// Crea un modelo desde JSON
  factory Investment.fromJson(Map<String, dynamic> json) => Investment.fromMap(json);

  @override
  String toString() {
    return 'Investment(id: $id, type: $type, name: $name, '
        'platform: $platform, amountInvested: $amountInvested, '
        'currentValue: $currentValue, dateInvested: $dateInvested, '
        'lastUpdate: $lastUpdate, notes: $notes, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Investment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
