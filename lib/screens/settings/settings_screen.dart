import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/export_service.dart';
import '../../services/gamification_service.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla de ajustes y configuración
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSection(
          context,
          'Exportar Datos',
          [
            ListTile(
              leading: const Icon(Icons.file_download, color: AppTheme.primaryColor),
              title: const Text('Exportar Gastos (CSV)'),
              subtitle: const Text('Descarga tus gastos en formato CSV'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _exportExpensesCSV(context),
            ),
            ListTile(
              leading: const Icon(Icons.file_download, color: AppTheme.secondaryColor),
              title: const Text('Exportar Gastos (PDF)'),
              subtitle: const Text('Genera un reporte en PDF'),
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
      ],
    );
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
