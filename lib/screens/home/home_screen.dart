import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/investment_service.dart';
import '../../services/income_service.dart';
import '../../services/quick_action_service.dart';
import '../../services/quick_investment_service.dart';
import '../../services/gamification_service.dart';
import '../../widgets/common/balance_card.dart';
import '../../widgets/common/quick_action_button.dart';
import '../../widgets/common/quick_investment_button.dart';
import '../../widgets/common/success_snackbar.dart';
import '../../core/theme/app_theme.dart';
import '../expenses/add_expense_screen.dart';
import '../investments/add_investment_screen.dart';
import '../income/add_income_screen.dart';
import '../quick_actions/add_quick_action_screen.dart';
import '../quick_actions/add_quick_investment_screen.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';

/// Pantalla principal de la aplicación
/// 
/// Muestra el balance total, resumen de gastos del mes,
/// acciones rápidas y acceso a todas las funcionalidades principales.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double _monthlyExpenses = 0;
  double _totalInvested = 0;
  double _totalCurrentValue = 0;
  double _totalIncomes = 0;
  int _lastExpenseCount = 0;
  int _lastIncomeCount = 0;
  int _lastInvestmentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _checkForDataChanges() {
    final expenseService = context.read<ExpenseService>();
    final incomeService = context.read<IncomeService>();
    final investmentService = context.read<InvestmentService>();
    
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
    
    if (shouldReload && mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    _checkForDataChanges();
    final expenseService = context.read<ExpenseService>();
    final investmentService = context.read<InvestmentService>();
    final incomeService = context.read<IncomeService>();

    final monthly = await expenseService.getMonthlyTotal();
    final amountInvested = await investmentService.getTotalInvested();
    final currentValue = await investmentService.getTotalCurrentValue();
    final totalIncomes = await incomeService.getAllTimeTotal();
    
    // Actualizar precios automáticamente al cargar
    _updateInvestmentPricesInBackground();

    setState(() {
      _monthlyExpenses = monthly;
      _totalInvested = amountInvested;
      _totalCurrentValue = currentValue;
      _totalIncomes = totalIncomes;
    });
  }
  
  /// Actualiza los precios de las inversiones en segundo plano
  Future<void> _updateInvestmentPricesInBackground() async {
    try {
      final investmentService = context.read<InvestmentService>();
      // Actualizar precios sin mostrar loading ni interrumpir la UI
      await investmentService.updateAllPricesFromApi();
    } catch (e) {
      // Ignorar errores silenciosamente (sin internet, API caída, etc.)
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleQuickAction(BuildContext context, action) async {
    final expenseService = context.read<ExpenseService>();
    final gamificationService = context.read<GamificationService>();

    final success = await expenseService.addExpense(
      amount: action.amount,
      category: action.category,
      subcategory: action.subcategory,
      date: DateTime.now(),
      icon: action.icon,
      isQuickAction: true,
    );

    if (success) {
      // Actualizar racha
      await gamificationService.updateStreak();
      
      // Verificar logros
      await gamificationService.checkExpenseAchievements(
        expenseService.expenseCount,
      );

      // Recargar datos
      await _loadData();

      if (context.mounted) {
        SuccessSnackBar.show(
          context,
          title: 'Gasto registrado',
          subtitle: '${action.name} - ${action.amount.toStringAsFixed(2)}€',
          icon: Icons.check_circle_outline,
        );
      }
    }
  }

  Future<void> _handleQuickInvestment(BuildContext context, investment) async {
    final investmentService = context.read<InvestmentService>();

    // Si está vinculada a una inversión existente, actualizarla
    if (investment.linkedInvestmentId != null) {
      final existingInvestment = investmentService.investments
          .firstWhere((inv) => inv.id == investment.linkedInvestmentId);
      
      // Solo actualizar el monto invertido, no el valor actual
      final success = await investmentService.updateInvestment(
        existingInvestment.copyWith(
          amountInvested: existingInvestment.amountInvested + investment.amount,
          lastUpdate: DateTime.now(),
        ),
      );

      // Intentar actualizar el precio desde la API
      if (success) {
        final apiSuccess = await investmentService.updatePriceFromApi(investment.linkedInvestmentId);
        
        // Si la API no funciona (activo sin API), actualizar manualmente
        if (!apiSuccess) {
          await investmentService.updateInvestment(
            existingInvestment.copyWith(
              amountInvested: existingInvestment.amountInvested + investment.amount,
              currentValue: existingInvestment.currentValue + investment.amount,
              lastUpdate: DateTime.now(),
            ),
          );
        }
      }

      if (success && mounted) {
        await _loadData();
        if (mounted) {
          SuccessSnackBar.show(
            // ignore: use_build_context_synchronously
            context,
            title: 'Inversión actualizada',
            subtitle: '+${investment.amount.toStringAsFixed(2)}€ en ${investment.investmentName}',
            icon: Icons.trending_up,
          );
        }
      }
    } else {
      // Crear nueva inversión con valor inicial igual al monto
      final success = await investmentService.addInvestment(
        type: investment.type,
        name: investment.investmentName,
        platform: investment.platform,
        amountInvested: investment.amount,
        currentValue: investment.amount, // Valor inicial
        dateInvested: DateTime.now(),
        notes: 'Aportación vía acción rápida',
        icon: investment.icon,
      );

      // Intentar actualizar el precio desde la API si se creó exitosamente
      if (success) {
        // Encontrar la inversión recién creada
        await investmentService.loadInvestments();
        final newInvestment = investmentService.investments
            .where((inv) => inv.name == investment.investmentName)
            .reduce((a, b) => a.lastUpdate.isAfter(b.lastUpdate) ? a : b);
        
        // Si la API falla, el valor ya está establecido correctamente
        await investmentService.updatePriceFromApi(newInvestment.id);
      }

      if (success && mounted) {
        await _loadData();
        if (mounted) {
          SuccessSnackBar.show(
            // ignore: use_build_context_synchronously
            context,
            title: 'Inversión registrada',
            subtitle: '${investment.amount.toStringAsFixed(2)}€ en ${investment.investmentName}',
            icon: Icons.trending_up,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeContent(),
      const StatisticsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas Personales'),
        actions: [
          // Indicador de racha
          Consumer<GamificationService>(
            builder: (context, gamificationService, _) {
              if (gamificationService.currentStreak > 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.paddingM),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '${gamificationService.currentStreak}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Balance Card
          BalanceCard(
            totalExpenses: _monthlyExpenses,
            totalInvestmentsInvested: _totalInvested,
            totalInvestmentsCurrent: _totalCurrentValue,
            totalIncomes: _totalIncomes,
          ),

          const SizedBox(height: AppTheme.paddingM),

          const SizedBox(height: AppTheme.paddingM),

          // Sección de Acciones Rápidas
          _buildSectionHeader(
            context,
            'Acciones Rápidas',
            Icons.flash_on,
          ),
          const SizedBox(height: AppTheme.paddingS),
          Consumer<QuickActionService>(
            builder: (context, quickActionService, _) {
              return QuickActionsRow(
                actions: quickActionService.activeQuickActions,
                onActionTap: (action) => _handleQuickAction(context, action),
                onAddNew: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddQuickActionScreen(),
                    ),
                  );
                },
                onReorder: (reorderedActions) async {
                  await quickActionService.updateOrder(reorderedActions);
                },
              );
            },
          ),

          const SizedBox(height: AppTheme.paddingL),

          // Sección de Acciones Rápidas de Inversiones
          _buildSectionHeader(
            context,
            'Inversiones Rápidas',
            Icons.trending_up,
          ),
          const SizedBox(height: AppTheme.paddingS),
          Consumer<QuickInvestmentService>(
            builder: (context, quickInvestmentService, _) {
              return QuickInvestmentsRow(
                investments: quickInvestmentService.activeQuickInvestments,
                onInvestmentTap: (investment) => _handleQuickInvestment(context, investment),
                onAddNew: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddQuickInvestmentScreen(),
                    ),
                  );
                },
                onReorder: (reorderedInvestments) async {
                  await quickInvestmentService.updateOrder(reorderedInvestments);
                },
              );
            },
          ),

          const SizedBox(height: AppTheme.paddingL),

          // Resumen del Mes
          _buildSectionHeader(
            context,
            'Resumen del Mes',
            Icons.calendar_today,
          ),
          const SizedBox(height: AppTheme.paddingS),
          _buildMonthSummary(),

          const SizedBox(height: AppTheme.paddingL),

          // Accesos Rápidos
          _buildQuickAccessSection(),

          const SizedBox(height: AppTheme.paddingXL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: AppTheme.paddingS),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Column(
            children: [
              _buildSummaryRow(
                'Total Gastado',
                '${_monthlyExpenses.toStringAsFixed(2)}€',
                Icons.shopping_cart,
                AppTheme.errorColor,
              ),
              const Divider(height: AppTheme.paddingL),
              _buildSummaryRow(
                'Inversiones',
                '${_totalCurrentValue.toStringAsFixed(2)}€',
                Icons.trending_up,
                AppTheme.successColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppTheme.paddingS),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accesos Rápidos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.paddingM),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessButton(
                  context,
                  'Nuevo Gasto',
                  Icons.receipt_long,
                  AppTheme.primaryColor,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddExpenseScreen(),
                      ),
                    );
                    await _loadData();
                  },
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),
              Expanded(
                child: _buildQuickAccessButton(
                  context,
                  'Nuevo Ingreso',
                  Icons.add_circle,
                  AppTheme.successColor,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddIncomeScreen(),
                      ),
                    );
                    await _loadData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingM),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessButton(
                  context,
                  'Nueva Inversión',
                  Icons.trending_up,
                  AppTheme.secondaryColor,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddInvestmentScreen(),
                      ),
                    );
                    await _loadData();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppTheme.paddingS),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
