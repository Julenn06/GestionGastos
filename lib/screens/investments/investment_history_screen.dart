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
              final isProfit = profitLoss >= 0;

              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (isProfit ? AppTheme.successColor : AppTheme.errorColor)
                        .withValues(alpha: 0.2),
                    child: Text(
                      investment.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    investment.type,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (investment.platform != null && investment.platform!.isNotEmpty)
                        Text(investment.platform!),
                      Text(
                        _dateFormat.format(investment.dateInvested),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (investment.notes != null && investment.notes!.isNotEmpty)
                        Text(
                          investment.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${investment.currentValue.toStringAsFixed(2)}€',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                                SizedBox(width: 8),
                                Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditInvestmentScreen(
                                  investment: investment,
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            await _deleteInvestment(investment.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
