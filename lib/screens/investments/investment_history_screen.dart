import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/investment_service.dart';
import '../../core/theme/app_theme.dart';
import 'edit_investment_screen.dart';

/// Pantalla de historial de inversiones
/// 
/// Muestra todas las inversiones registradas con opciones de editar y eliminar.
class InvestmentHistoryScreen extends StatefulWidget {
  const InvestmentHistoryScreen({super.key});

  @override
  State<InvestmentHistoryScreen> createState() => _InvestmentHistoryScreenState();
}

class _InvestmentHistoryScreenState extends State<InvestmentHistoryScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _deleteInvestment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Inversión'),
        content: const Text('¿Estás seguro de eliminar esta inversión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final investmentService = context.read<InvestmentService>();
      final success = await investmentService.deleteInvestment(id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inversión eliminada'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Inversiones'),
      ),
      body: Consumer<InvestmentService>(
        builder: (context, investmentService, _) {
          final investments = investmentService.investments;

          if (investments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 80,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  Text(
                    'No hay inversiones registradas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            itemCount: investments.length,
            itemBuilder: (context, index) {
              final investment = investments[index];
              final profitLoss = investment.currentValue - investment.amountInvested;
              final profitLossPercent = (profitLoss / investment.amountInvested * 100);
              final isProfit = profitLoss >= 0;

              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: (isProfit ? AppTheme.successColor : AppTheme.errorColor)
                        .withValues(alpha: 0.2),
                    child: Text(
                      investment.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    investment.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(investment.type),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${investment.currentValue.toStringAsFixed(2)}€',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${isProfit ? '+' : ''}${profitLossPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Invertido:',
                            '${investment.amountInvested.toStringAsFixed(2)}€',
                          ),
                          _buildDetailRow(
                            'Valor actual:',
                            '${investment.currentValue.toStringAsFixed(2)}€',
                          ),
                          _buildDetailRow(
                            'Ganancia/Pérdida:',
                            '${isProfit ? '+' : ''}${profitLoss.toStringAsFixed(2)}€',
                            color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                          if (investment.platform != null)
                            _buildDetailRow('Plataforma:', investment.platform!),
                          _buildDetailRow(
                            'Fecha inversión:',
                            _dateFormat.format(investment.dateInvested),
                          ),
                          if (investment.notes != null && investment.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: AppTheme.paddingS),
                              child: Text(
                                investment.notes!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          const SizedBox(height: AppTheme.paddingM),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditInvestmentScreen(
                                        investment: investment,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Editar'),
                              ),
                              const SizedBox(width: AppTheme.paddingS),
                              TextButton.icon(
                                onPressed: () => _deleteInvestment(investment.id),
                                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                label: const Text(
                                  'Eliminar',
                                  style: TextStyle(color: AppTheme.errorColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
