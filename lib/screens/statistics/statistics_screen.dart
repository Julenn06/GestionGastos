import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/investment_service.dart';
import '../../core/theme/app_theme.dart';
import '../expenses/category_detail_screen.dart';
import '../income/income_category_detail_screen.dart';
import '../investments/investment_category_detail_screen.dart';

/// Pantalla de estadísticas con gráficos interactivos
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, double> _categoryData = {};
  bool _isLoading = true;
  String _selectedPeriod = 'month'; // 'week', 'month', 'year', 'all'
  DateTime? _customStart;
  DateTime? _customEnd;
  int _lastExpenseCount = 0;
  int _lastIncomeCount = 0;
  int _lastInvestmentCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar si los datos han cambiado
    final expenseService = context.watch<ExpenseService>();
    final incomeService = context.watch<IncomeService>();
    final investmentService = context.watch<InvestmentService>();
    
    bool shouldReload = false;
    
    if (expenseService.expenseCount != _lastExpenseCount) {
      _lastExpenseCount = expenseService.expenseCount;
      shouldReload = true;
    }
    
    if (incomeService.incomes.length != _lastIncomeCount) {
      _lastIncomeCount = incomeService.incomes.length;
      shouldReload = true;
    }
    
    if (investmentService.investments.length != _lastInvestmentCount) {
      _lastInvestmentCount = investmentService.investments.length;
      shouldReload = true;
    }
    
    if (shouldReload && mounted && !_isLoading) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    Map<String, double> data = {};
    
    // Cargar datos según el tab seleccionado
    if (_tabController.index == 0) {
      // Gastos
      final expenseService = context.read<ExpenseService>();
      data = await _getExpenseData(expenseService);
    } else if (_tabController.index == 1) {
      // Ingresos
      final incomeService = context.read<IncomeService>();
      data = await _getIncomeData(incomeService);
    } else {
      // Inversiones
      final investmentService = context.read<InvestmentService>();
      data = await _getInvestmentData(investmentService);
    }
    
    setState(() {
      _categoryData = data;
      _isLoading = false;
    });
  }

  Future<Map<String, double>> _getExpenseData(ExpenseService expenseService) async {
    switch (_selectedPeriod) {
      case 'week':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return await expenseService.getExpensesByCategoryPeriod(weekStart, weekEnd);
      case 'year':
        final now = DateTime.now();
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year, 12, 31);
        return await expenseService.getExpensesByCategoryPeriod(yearStart, yearEnd);
      case 'all':
        final now = DateTime.now();
        return await expenseService.getExpensesByCategoryPeriod(
          DateTime(2000, 1, 1),
          now,
        );
      case 'custom':
        if (_customStart != null && _customEnd != null) {
          return await expenseService.getExpensesByCategoryPeriod(_customStart!, _customEnd!);
        }
        return await expenseService.getMonthlyExpensesByCategory();
      default:
        return await expenseService.getMonthlyExpensesByCategory();
    }
  }

  Future<Map<String, double>> _getIncomeData(IncomeService incomeService) async {
    final start = _getStartDate() ?? DateTime.now();
    final end = _getEndDate() ?? DateTime.now();
    
    final incomes = await incomeService.getIncomesByDateRange(start, end);
    final Map<String, double> data = {};
    
    for (var income in incomes) {
      data[income.category] = (data[income.category] ?? 0) + income.amount;
    }
    
    return data;
  }

  Future<Map<String, double>> _getInvestmentData(InvestmentService investmentService) async {
    final start = _getStartDate() ?? DateTime.now();
    final end = _getEndDate() ?? DateTime.now();
    
    final investments = investmentService.investments.where((inv) {
      return inv.dateInvested.isAfter(start.subtract(const Duration(days: 1))) &&
             inv.dateInvested.isBefore(end.add(const Duration(days: 1)));
    }).toList();
    
    final Map<String, double> data = {};
    
    // Usar el valor ACTUAL de las inversiones, no el invertido
    for (var investment in investments) {
      data[investment.type] = (data[investment.type] ?? 0) + investment.currentValue;
    }
    
    return data;
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

  DateTime? _getStartDate() {
    switch (_selectedPeriod) {
      case 'week':
        final now = DateTime.now();
        return now.subtract(Duration(days: now.weekday - 1));
      case 'year':
        final now = DateTime.now();
        return DateTime(now.year, 1, 1);
      case 'all':
        return DateTime(2000, 1, 1);
      case 'custom':
        return _customStart;
      default:
        final now = DateTime.now();
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime? _getEndDate() {
    switch (_selectedPeriod) {
      case 'week':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return weekStart.add(const Duration(days: 6));
      case 'year':
        final now = DateTime.now();
        return DateTime(now.year, 12, 31);
      case 'all':
        return DateTime.now();
      case 'custom':
        return _customEnd;
      default:
        final now = DateTime.now();
        return DateTime(now.year, now.month + 1, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPeriodTitle()),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) {
            setState(() {
              _isLoading = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadData();
            });
          },
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Gastos'),
            Tab(icon: Icon(Icons.add_circle), text: 'Ingresos'),
            Tab(icon: Icon(Icons.trending_up), text: 'Inversiones'),
          ],
        ),
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
            child: InkWell(
              onTap: () {
                // Navegar a la pantalla de detalle según el tab actual
                Widget detailScreen;
                if (_tabController.index == 0) {
                  // Gastos
                  detailScreen = CategoryDetailScreen(
                    categoryName: entry.key,
                    categoryColor: color,
                    startDate: _getStartDate(),
                    endDate: _getEndDate(),
                  );
                } else if (_tabController.index == 1) {
                  // Ingresos
                  detailScreen = IncomeCategoryDetailScreen(
                    categoryName: entry.key,
                    categoryColor: color,
                    startDate: _getStartDate(),
                    endDate: _getEndDate(),
                  );
                } else {
                  // Inversiones
                  detailScreen = InvestmentCategoryDetailScreen(
                    categoryName: entry.key,
                    categoryColor: color,
                    startDate: _getStartDate(),
                    endDate: _getEndDate(),
                  );
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => detailScreen),
                );
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.value.toStringAsFixed(2)}€',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
          );
        })),
      ],
    );
  }
}
