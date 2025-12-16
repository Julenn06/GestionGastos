import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/expense_service.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla de estadísticas con gráficos interactivos
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, double> _categoryData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final expenseService = context.read<ExpenseService>();
    final data = await expenseService.getMonthlyExpensesByCategory();
    setState(() {
      _categoryData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              children: [
                Text(
                  'Estadísticas del Mes',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.paddingL),
                
                if (_categoryData.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.paddingXL),
                      child: Text('No hay datos para mostrar'),
                    ),
                  )
                else
                  _buildPieChart(),

                const SizedBox(height: AppTheme.paddingXL),
                _buildCategoryList(),
              ],
            ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: _categoryData.entries.map((entry) {
            final index = _categoryData.keys.toList().indexOf(entry.key);
            return PieChartSectionData(
              value: entry.value,
              title: '${entry.value.toStringAsFixed(0)}€',
              color: AppTheme.chartColors[index % AppTheme.chartColors.length],
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desglose por Categoría',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.paddingM),
        ...(_categoryData.entries.map((entry) {
          final index = _categoryData.keys.toList().indexOf(entry.key);
          final color = AppTheme.chartColors[index % AppTheme.chartColors.length];
          final total = _categoryData.values.reduce((a, b) => a + b);
          final percentage = (entry.value / total * 100).toStringAsFixed(1);

          return Card(
            margin: const EdgeInsets.only(bottom: AppTheme.paddingS),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.category, color: color),
                ),
              ),
              title: Text(entry.key),
              subtitle: Text('$percentage%'),
              trailing: Text(
                '${entry.value.toStringAsFixed(2)}€',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          );
        })),
      ],
    );
  }
}
