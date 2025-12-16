import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/database.dart';
import 'services/expense_service.dart';
import 'services/investment_service.dart';
import 'services/quick_action_service.dart';
import 'services/gamification_service.dart';
import 'services/category_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

/// Punto de entrada principal de la aplicación
/// 
/// Inicializa la base de datos, servicios y providers necesarios
/// para el funcionamiento de la aplicación de finanzas personales.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar base de datos
  final database = AppDatabase();
  
  // Inicializar SharedPreferences para gamificación
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(database: database, prefs: prefs));
}

/// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  final AppDatabase database;
  final SharedPreferences prefs;

  const MyApp({
    super.key,
    required this.database,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Proveedor de servicios
        ChangeNotifierProvider(
          create: (_) => CategoryService(database),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseService(database),
        ),
        ChangeNotifierProvider(
          create: (_) => InvestmentService(database),
        ),
        ChangeNotifierProvider(
          create: (_) => QuickActionService(database)
            ..initializeDefaultQuickActions(),
        ),
        ChangeNotifierProvider(
          create: (_) => GamificationService(database, prefs),
        ),
      ],
      child: MaterialApp(
        title: 'Gestión de Gastos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
