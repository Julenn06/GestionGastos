import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
  String _selectedPeriod = 'month'; // 'week', 'month', 'year', 'all'
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final expenseService = context.read<ExpenseService>();
    
    Map<String, double> data;
    switch (_selectedPeriod) {
      case 'week':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        data = await expenseService.getExpensesByCategoryPeriod(weekStart, weekEnd);
        break;
      case 'year':
        final now = DateTime.now();
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year, 12, 31);
        data = await expenseService.getExpensesByCategoryPeriod(yearStart, yearEnd);
        break;
      case 'all':
        final now = DateTime.now();
        data = await expenseService.getExpensesByCategoryPeriod(
          DateTime(2000, 1, 1),
          now,
        );
        break;
      case 'custom':
        if (_customStart != null && _customEnd != null) {
          data = await expenseService.getExpensesByCategoryPeriod(_customStart!, _customEnd!);
        } else {
          data = await expenseService.getMonthlyExpensesByCategory();
        }
        break;
      default:
        data = await expenseService.getMonthlyExpensesByCategory();
    }
    
    setState(() {
      _categoryData = data;
      _isLoading = false;
    });
  }

  Future<void> _selectCustomPeriod() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customStart = picked.start;
        _customEnd = picked.end;
      });
      await _loadData();
    }
  }

  String _getPeriodTitle() {
    switch (_selectedPeriod) {
      case 'week':
        return 'Estadísticas de la Semana';
      case 'year':
        return 'Estadísticas del Año';
      case 'all':
        return 'Todas las Estadísticas';
      case 'custom':
        if (_customStart != null && _customEnd != null) {
          final format = DateFormat('dd/MM/yy');
          return '${format.format(_customStart!)} - ${format.format(_customEnd!)}';
        }
        return 'Período Personalizado';
      default:
        return 'Estadísticas del Mes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPeriodTitle()),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) async {
              if (value == 'custom') {
                await _selectCustomPeriod();
              } else {
                setState(() {
                  _selectedPeriod = value;
                });
                await _loadData();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_view_week,
                      color: _selectedPeriod == 'week' ? AppTheme.primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Esta Semana'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _selectedPeriod == 'month' ? AppTheme.primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Este Mes'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'year',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _selectedPeriod == 'year' ? AppTheme.primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Este Año'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: _selectedPeriod == 'all' ? AppTheme.primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Todo el Tiempo'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'custom',
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: _selectedPeriod == 'custom' ? AppTheme.primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Período Personalizado'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                children: [
                  if (_categoryData.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.paddingXL),
                        child: Text('No hay datos para mostrar'),
                      ),
                    )
                  else ...[
                    _buildPieChart(),
                    const SizedBox(height: AppTheme.paddingXL),
                    _buildCategoryList(),
                  ],
                ],
              ),
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
