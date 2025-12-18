import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

/// Widget reutilizable para mostrar el balance total
///
/// Muestra el balance total con un diseño atractivo y profesional,
/// incluyendo iconos, gradientes y animaciones opcionales.
class BalanceCard extends StatelessWidget {
  final double totalExpenses;
  final double totalInvestmentsInvested;
  final double totalInvestmentsCurrent;
  final double totalIncomes;
  final bool showDetails;
  final VoidCallback? onTap;

  // Cachear NumberFormat para evitar recrearlo en cada build
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '€',
    decimalDigits: 2,
  );

  const BalanceCard({
    super.key,
    required this.totalExpenses,
    required this.totalInvestmentsInvested,
    required this.totalInvestmentsCurrent,
    this.totalIncomes = 0.0,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Balance = Ingresos - Gastos - Inversiones (monto invertido)
    // Las inversiones restan porque el dinero sale de la cartera
    final balance = totalIncomes - totalExpenses - totalInvestmentsInvested;

    // Ganancia/pérdida de las inversiones
    final investmentProfit = totalInvestmentsCurrent - totalInvestmentsInvested;
    final hasProfit = investmentProfit >= 0;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(AppTheme.paddingM),
          padding: const EdgeInsets.all(AppTheme.paddingL),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.black87,
                    size: 28,
                  ),
                  const SizedBox(width: AppTheme.paddingS),
                  Text(
                    'Balance Total',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingM),

              // Balance principal
              Text(
                _currencyFormat.format(balance),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                ),
              ),

              if (showDetails) ...[
                const SizedBox(height: AppTheme.paddingL),
                const Divider(color: Colors.black26, thickness: 1),
                const SizedBox(height: AppTheme.paddingM),

                // Detalles
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailItem(
                          icon: Icons.arrow_downward,
                          label: 'Ingresos',
                          value: _currencyFormat.format(totalIncomes),
                          color: Colors.green[700]!,
                        ),
                        _DetailItem(
                          icon: Icons.arrow_upward,
                          label: 'Gastos',
                          value: _currencyFormat.format(totalExpenses),
                          color: Colors.red[700]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailItemWithSubtitle(
                          icon: Icons.trending_up,
                          label: 'Inversiones',
                          value: _currencyFormat.format(
                            totalInvestmentsCurrent,
                          ),
                          subtitle: investmentProfit != 0
                              ? '${hasProfit ? '+' : ''}${_currencyFormat.format(investmentProfit)}'
                              : null,
                          color: hasProfit
                              ? Colors.green[700]!
                              : Colors.red[700]!,
                        ),
                        _DetailItem(
                          icon: Icons.account_balance_wallet,
                          label: 'Balance',
                          value: _currencyFormat.format(balance),
                          color: balance >= 0
                              ? Colors.green[700]!
                              : Colors.red[700]!,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DetailItemWithSubtitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _DetailItemWithSubtitle({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
