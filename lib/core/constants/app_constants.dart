/// Constantes globales de la aplicación
/// 
/// Este archivo centraliza todas las constantes utilizadas en la app
/// para facilitar el mantenimiento y escalabilidad del proyecto.
class AppConstants {
  // Prevenir instanciación
  AppConstants._();

  // ============ Categorías de Gastos ============
  static const List<String> expenseCategories = [
    'Alimentación',
    'Transporte',
    'Vivienda',
    'Entretenimiento',
    'Salud',
    'Educación',
    'Ropa',
    'Tecnología',
    'Servicios',
    'Otros',
  ];

  // ============ Subcategorías por Categoría ============
  static const Map<String, List<String>> expenseSubcategories = {
    'Alimentación': ['Supermercado', 'Restaurantes', 'Cafetería', 'Comida rápida'],
    'Transporte': ['Gasolina', 'Transporte público', 'Taxi/Uber', 'Mantenimiento', 'Parking'],
    'Vivienda': ['Alquiler', 'Hipoteca', 'Luz', 'Agua', 'Gas', 'Internet', 'Limpieza'],
    'Entretenimiento': ['Cine', 'Conciertos', 'Videojuegos', 'Streaming', 'Deportes'],
    'Salud': ['Médico', 'Farmacia', 'Gimnasio', 'Seguro médico'],
    'Educación': ['Matrícula', 'Libros', 'Cursos', 'Material'],
    'Ropa': ['Vestimenta', 'Calzado', 'Accesorios'],
    'Tecnología': ['Dispositivos', 'Software', 'Reparaciones'],
    'Servicios': ['Telefonía', 'Suscripciones', 'Seguros'],
    'Otros': ['Varios', 'Regalos', 'Donaciones'],
  };

  // ============ Tipos de Inversión ============
  static const List<String> investmentTypes = [
    'Acciones',
    'ETFs',
    'Fondos de Inversión',
    'Criptomonedas',
    'Bonos',
    'Bienes Raíces',
    'Otros',
  ];

  // ============ Iconos por Categoría ============
  static const Map<String, String> categoryIcons = {
    'Alimentación': '🍔',
    'Transporte': '🚗',
    'Vivienda': '🏠',
    'Entretenimiento': '🎮',
    'Salud': '⚕️',
    'Educación': '📚',
    'Ropa': '👕',
    'Tecnología': '💻',
    'Servicios': '🔧',
    'Otros': '📦',
  };

  // ============ Gamificación - Logros ============
  static const Map<String, dynamic> achievements = {
    'first_expense': {
      'title': '¡Primer Gasto!',
      'description': 'Registraste tu primer gasto',
      'icon': '🎯',
    },
    'week_streak': {
      'title': 'Racha Semanal',
      'description': 'Registraste gastos durante 7 días seguidos',
      'icon': '🔥',
    },
    'month_streak': {
      'title': 'Racha Mensual',
      'description': 'Registraste gastos durante 30 días seguidos',
      'icon': '⭐',
    },
    'first_investment': {
      'title': 'Inversor Novato',
      'description': 'Registraste tu primera inversión',
      'icon': '📈',
    },
    'expense_master': {
      'title': 'Maestro del Ahorro',
      'description': 'Registraste más de 100 gastos',
      'icon': '🏆',
    },
    'export_data': {
      'title': 'Analista Financiero',
      'description': 'Exportaste tus datos por primera vez',
      'icon': '📊',
    },
  };

  // ============ Configuración de Base de Datos ============
  static const String databaseName = 'gestion_gastos.db';
  static const int databaseVersion = 1;

  // ============ Claves de Almacenamiento Seguro ============
  static const String pinKey = 'user_pin';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String lastStreakDateKey = 'last_streak_date';
  static const String currentStreakKey = 'current_streak';
  static const String achievementsKey = 'unlocked_achievements';

  // ============ Configuración de Exportación ============
  static const String csvFileName = 'gastos_export';
  static const String pdfFileName = 'reporte_financiero';

  // ============ Límites y Validaciones ============
  static const double maxExpenseAmount = 999999999.99;
  static const double minExpenseAmount = 0.01;
  static const int maxNoteLenght = 500;
  static const int pinLength = 4;

  // ============ Duraciones de Animación ============
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
