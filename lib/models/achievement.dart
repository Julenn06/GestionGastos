/// Modelo de datos para Logros de Gamificación
/// 
/// Representa un logro desbloqueado por el usuario para motivar
/// el uso constante de la aplicación.
class Achievement {
  /// Identificador único del logro
  final String id;
  
  /// Título del logro
  final String title;
  
  /// Descripción del logro
  final String description;
  
  /// Icono o emoji del logro
  final String icon;
  
  /// Fecha en que se desbloqueó el logro
  final DateTime? unlockedAt;
  
  /// Indica si el logro está desbloqueado
  bool get isUnlocked => unlockedAt != null;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  /// Crea una copia del logro con valores opcionales modificados
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  /// Convierte el modelo a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  /// Crea un modelo desde un Map de la base de datos
  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'] as String)
          : null,
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() => toMap();

  /// Crea un modelo desde JSON
  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement.fromMap(json);

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, description: $description, '
        'icon: $icon, unlockedAt: $unlockedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Achievement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
