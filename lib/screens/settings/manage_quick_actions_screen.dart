import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/quick_action_service.dart';
import '../../models/quick_action.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

/// Pantalla de gestión de acciones rápidas
/// 
/// Permite al usuario crear, editar, eliminar y ordenar acciones rápidas personalizadas.
class ManageQuickActionsScreen extends StatelessWidget {
  const ManageQuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Acciones Rápidas'),
      ),
      body: Consumer<QuickActionService>(
        builder: (context, service, _) {
          final actions = service.quickActions;

          if (actions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flash_off,
                    size: 80,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  Text(
                    'No hay acciones rápidas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  Text(
                    'Crea una para registrar gastos con un toque',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            itemCount: actions.length,
            onReorder: (oldIndex, newIndex) {
              // TODO: Implementar reordenamiento
            },
            itemBuilder: (context, index) {
              final action = actions[index];
              return Card(
                key: ValueKey(action.id),
                margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: action.isActive
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    child: Text(
                      action.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(action.name),
                  subtitle: Text(
                    '${action.amount.toStringAsFixed(2)}€ • ${action.category}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: action.isActive,
                        onChanged: (value) async {
                          await service.toggleQuickAction(action.id, value);
                        },
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
                            await _showEditDialog(context, action);
                          } else if (value == 'delete') {
                            await _deleteAction(context, action.id);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Acción'),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const _QuickActionDialog(),
    );
  }

  Future<void> _showEditDialog(BuildContext context, QuickAction action) async {
    await showDialog(
      context: context,
      builder: (context) => _QuickActionDialog(action: action),
    );
  }

  Future<void> _deleteAction(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Acción Rápida'),
        content: const Text('¿Estás seguro de eliminar esta acción rápida?'),
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

    if (confirmed == true && context.mounted) {
      final service = context.read<QuickActionService>();
      await service.deleteQuickAction(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acción rápida eliminada'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }
}

class _QuickActionDialog extends StatefulWidget {
  final QuickAction? action;

  const _QuickActionDialog({this.action});

  @override
  State<_QuickActionDialog> createState() => _QuickActionDialogState();
}

class _QuickActionDialogState extends State<_QuickActionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late String? _selectedCategory;
  late String? _selectedSubcategory;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.action?.name ?? '');
    _amountController = TextEditingController(
      text: widget.action?.amount.toString() ?? '',
    );
    _selectedCategory = widget.action?.category;
    _selectedSubcategory = widget.action?.subcategory.isEmpty == true
        ? null
        : widget.action?.subcategory;
    _selectedIcon = widget.action?.icon ?? '💰';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    final service = context.read<QuickActionService>();
    
    if (widget.action == null) {
      // Crear nueva
      await service.createQuickAction(
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        subcategory: _selectedSubcategory ?? '',
        icon: _selectedIcon,
      );
    } else {
      // Actualizar existente
      final updated = QuickAction(
        id: widget.action!.id,
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        subcategory: _selectedSubcategory ?? '',
        icon: _selectedIcon,
        color: widget.action!.color,
        order: widget.action!.order,
        isActive: widget.action!.isActive,
      );
      await service.updateQuickAction(updated);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.action == null
                ? 'Acción rápida creada'
                : 'Acción rápida actualizada',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.action == null ? 'Nueva Acción Rápida' : 'Editar Acción'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Café, Transporte',
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: AppTheme.paddingM),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '€ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty == true) return 'Ingresa un monto';
                  if (double.tryParse(value!) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.paddingM),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: AppConstants.expenseCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(AppConstants.categoryIcons[category] ?? '📦'),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubcategory = null;
                    _selectedIcon = AppConstants.categoryIcons[value] ?? '📦';
                  });
                },
              ),
              if (_selectedCategory != null) ...[
                const SizedBox(height: AppTheme.paddingM),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubcategory,
                  decoration: const InputDecoration(labelText: 'Subcategoría'),
                  items: AppConstants.expenseSubcategories[_selectedCategory]
                      ?.map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubcategory = value);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
