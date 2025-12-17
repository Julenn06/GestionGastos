import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/investment_service.dart';
import '../../services/income_service.dart';
import '../../services/quick_action_service.dart';
import '../../services/quick_investment_service.dart';
import '../../services/export_service.dart';
import '../../services/gamification_service.dart';
import '../../core/theme/app_theme.dart';
import 'manage_quick_actions_screen.dart';
import 'security_settings_screen.dart';
import 'advanced_export_screen.dart';
import '../expenses/expense_history_screen.dart';
import '../investments/investment_history_screen.dart';

/// Pantalla de ajustes y configuración
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSection(
          context,
          'Gestión',
          [
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
              title: const Text('Historial de Gastos'),
              subtitle: const Text('Ver, editar y eliminar gastos'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpenseHistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up, color: AppTheme.secondaryColor),
              title: const Text('Mis Inversiones'),
              subtitle: const Text('Ver y gestionar inversiones'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InvestmentHistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.orange),
              title: const Text('Acciones Rápidas'),
              subtitle: const Text('Gestionar acciones rápidas'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageQuickActionsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        _buildSection(
          context,
          'Seguridad',
          [
            ListTile(
              leading: const Icon(Icons.security, color: Colors.green),
              title: const Text('PIN y Biometría'),
              subtitle: const Text('Configurar seguridad de la app'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecuritySettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        _buildSection(
          context,
          'Exportar Datos',
          [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exportación Avanzada'),
              subtitle: const Text('PDF con gráficos o Excel'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdvancedExportScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download, color: AppTheme.primaryColor),
              title: const Text('Exportar Gastos (CSV)'),
              subtitle: const Text('Descarga rápida en CSV'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _exportExpensesCSV(context),
            ),
            ListTile(
              leading: const Icon(Icons.file_download, color: AppTheme.secondaryColor),
              title: const Text('Exportar Gastos (PDF)'),
              subtitle: const Text('Reporte simple en PDF'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _exportExpensesPDF(context),
            ),
          ],
        ),
        _buildSection(
          context,
          'Logros',
          [
            Consumer<GamificationService>(
              builder: (context, gamificationService, _) {
                return ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: const Text('Mis Logros'),
                  subtitle: Text(
                    '${gamificationService.unlockedCount} de ${gamificationService.totalAchievements} desbloqueados',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAchievements(context, gamificationService),
                );
              },
            ),
          ],
        ),
        _buildSection(
          context,
          'Acerca de',
          [
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Versión'),
              subtitle: Text('1.0.0'),
            ),
            const ListTile(
              leading: Icon(Icons.code),
              title: Text('Desarrollado con Flutter'),
              subtitle: Text('Material Design 3'),
            ),
          ],
        ),
        _buildSection(
          context,
          'Zona de Peligro',
          [
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
              title: const Text('Eliminar Todos los Datos', style: TextStyle(color: AppTheme.errorColor)),
              subtitle: const Text('Borra todos los gastos, inversiones e ingresos'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.errorColor),
              onTap: () => _confirmDeleteAllData(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Todos los Datos'),
        content: const Text(
          'Esta acción eliminará TODOS tus datos:\n\n'
          '• Gastos\n'
          '• Inversiones\n'
          '• Ingresos\n'
          '• Acciones rápidas personalizadas\n'
          '• Inversiones rápidas personalizadas\n\n'
          'Esta acción NO se puede deshacer.\n\n'
          '¿Estás completamente seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Eliminar Todo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAllData(context);
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    try {
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Eliminando todos los datos...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Obtener servicios
      final expenseService = context.read<ExpenseService>();
      final investmentService = context.read<InvestmentService>();
      final incomeService = context.read<IncomeService>();
      final quickActionService = context.read<QuickActionService>();
      final quickInvestmentService = context.read<QuickInvestmentService>();

      // Eliminar todos los gastos
      final expenses = expenseService.expenses.toList();
      for (final expense in expenses) {
        await expenseService.deleteExpense(expense.id);
      }

      // Eliminar todas las inversiones
      final investments = investmentService.investments.toList();
      for (final investment in investments) {
        await investmentService.deleteInvestment(investment.id);
      }

      // Eliminar todos los ingresos
      final incomes = incomeService.incomes.toList();
      for (final income in incomes) {
        await incomeService.deleteIncome(income.id);
      }

      // Eliminar acciones rápidas personalizadas (no las predeterminadas)
      final quickActions = quickActionService.quickActions.toList();
      for (final action in quickActions) {
        await quickActionService.deleteQuickAction(action.id);
      }

      // Eliminar inversiones rápidas personalizadas
      final quickInvestments = quickInvestmentService.quickInvestments.toList();
      for (final investment in quickInvestments) {
        await quickInvestmentService.deleteQuickInvestment(investment.id);
      }

      // Cerrar diálogo de carga
      if (context.mounted) {
        Navigator.pop(context);
        
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los datos han sido eliminados'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de carga si hay error
      if (context.mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar datos: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingM,
            AppTheme.paddingL,
            AppTheme.paddingM,
            AppTheme.paddingS,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _exportExpensesCSV(BuildContext context) async {
    final expenseService = context.read<ExpenseService>();
    final exportService = ExportService();
    final gamificationService = context.read<GamificationService>();

    final expenses = expenseService.expenses;
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay gastos para exportar')),
      );
      return;
    }

    final filePath = await exportService.exportExpensesToCsv(expenses);
    await gamificationService.unlockExportAchievement();

    if (filePath != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exportado: $filePath'),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => exportService.shareFile(filePath, 'text/csv'),
          ),
        ),
      );
    }
  }

  Future<void> _exportExpensesPDF(BuildContext context) async {
    final expenseService = context.read<ExpenseService>();
    final exportService = ExportService();
    final gamificationService = context.read<GamificationService>();

    final expenses = expenseService.expenses;
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay gastos para exportar')),
      );
      return;
    }

    final total = await expenseService.getMonthlyTotal();
    final filePath = await exportService.exportExpensesToPdf(expenses, total);
    await gamificationService.unlockExportAchievement();

    if (filePath != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF generado'),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => exportService.shareFile(filePath, 'application/pdf'),
          ),
        ),
      );
    }
  }

  void _showAchievements(BuildContext context, GamificationService service) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logros',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.paddingM),
            Expanded(
              child: ListView.builder(
                itemCount: service.achievements.length,
                itemBuilder: (context, index) {
                  final achievement = service.achievements[index];
                  return ListTile(
                    leading: Text(achievement.icon, style: const TextStyle(fontSize: 32)),
                    title: Text(achievement.title),
                    subtitle: Text(achievement.description),
                    trailing: achievement.isUnlocked
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.lock, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
