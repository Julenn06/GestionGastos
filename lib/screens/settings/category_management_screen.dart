import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/category_service.dart';
import '../../data/database.dart';

/// Pantalla de Gestión de Categorías
/// 
/// Permite crear, editar y eliminar categorías personalizadas
/// con selección de icono y color.
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  String _selectedType = 'expense';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
        bottom: TabBar(
          onTap: (index) {
            setState(() {
              _selectedType = index == 0 ? 'expense' : 'income';
            });
          },
          tabs: const [
            Tab(text: 'Gastos', icon: Icon(Icons.trending_down)),
            Tab(text: 'Ingresos', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: _CategoryList(type: _selectedType),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Categoría'),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, [Category? category]) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        category: category,
        type: _selectedType,
      ),
    );
  }
}

/// Lista de categorías
class _CategoryList extends StatelessWidget {
  final String type;

  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryService>(
      builder: (context, service, child) {
        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = service.categories
            .where((cat) => cat.type == type)
            .toList();

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'expense' ? Icons.category_outlined : Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  type == 'expense'
                      ? 'No hay categorías de gastos'
                      : 'No hay categorías de ingresos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => service.loadCategories(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(category: category);
            },
          ),
        );
      },
    );
  }
}

/// Tarjeta de categoría
class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            category.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(category.isDefault ? 'Predeterminada' : 'Personalizada'),
          ],
        ),
        trailing: category.isDefault
            ? null
            : PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(context);
                  } else if (value == 'delete') {
                    _confirmDelete(context);
                  }
                },
              ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        category: category,
        type: category.type,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Eliminar la categoría "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final service = context.read<CategoryService>();
              final success = await service.deleteCategory(category.id);
              
              if (context.mounted) {
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Categoría eliminada'
                          : 'No se puede eliminar categoría con gastos',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Diálogo para crear/editar categoría
class _CategoryDialog extends StatefulWidget {
  final Category? category;
  final String type;

  const _CategoryDialog({
    this.category,
    required this.type,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = '📦';
  Color _selectedColor = Colors.blue;

  // Lista de iconos disponibles
  final List<String> _icons = [
    '🍔', '🍕', '🍜', '☕', '🍰', '🥗', '🍱', '🍝',
    '🚗', '🚕', '🚌', '🚇', '✈️', '🚲', '⛽', '🚦',
    '🏠', '🏢', '💡', '💧', '🔥', '🌐', '📱', '🖥️',
    '🎮', '🎬', '🎵', '🎨', '⚽', '🎯', '🎪', '🎭',
    '⚕️', '💊', '🏥', '🏋️', '🧘', '🩺', '💉', '🔬',
    '📚', '✏️', '📖', '🎓', '📝', '🖊️', '📐', '🔭',
    '👕', '👔', '👗', '👠', '👟', '👜', '🎩', '👓',
    '💻', '⌨️', '🖱️', '📱', '💾', '🔌', '🖨️', '📷',
    '🔧', '🔨', '⚙️', '🔩', '🛠️', '📞', '📺', '🎙️',
    '💰', '💵', '💳', '🏦', '📊', '📈', '💹', '🎁',
    '📦', '🎯', '⭐', '🌟', '💎', '🏆', '🎖️', '🏅',
  ];

  // Lista de colores disponibles
  final List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.icon;
      _selectedColor = _parseColor(widget.category!.color);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona un icono:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final icon = _icons[index];
                    final isSelected = icon == _selectedIcon;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? _selectedColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona un color:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saveCategory,
          child: Text(isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<CategoryService>();
    final colorHex = service.colorToHex(_selectedColor);

    bool success;
    
    if (widget.category != null) {
      // Editar categoría existente
      final updatedCategory = widget.category!.copyWith(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: colorHex,
      );
      success = await service.updateCategory(updatedCategory);
    } else {
      // Crear nueva categoría
      success = await service.createCategory(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: colorHex,
        type: widget.type,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (widget.category != null
                    ? 'Categoría actualizada'
                    : 'Categoría creada')
                : 'Error al guardar categoría',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
