import 'package:flutter/material.dart';
import 'package:dev_mobile/core/mock_data.dart';

class RendicionDetailScreen extends StatefulWidget {
  final RendicionContainer container;

  const RendicionDetailScreen({super.key, required this.container});

  @override
  State<RendicionDetailScreen> createState() => _RendicionDetailScreenState();
}

class _RendicionDetailScreenState extends State<RendicionDetailScreen> {
  late RendicionContainer container;

  @override
  void initState() {
    super.initState();
    container = widget.container;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aprobado':
        return Colors.green.shade400;
      case 'enviado':
        return Colors.orange.shade400;
      case 'rechazado':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'aprobado':
        return 'Aprobado';
      case 'enviado':
        return 'Enviado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return 'Borrador';
    }
  }

  void _selectCategory(String category) {
    setState(() {
      container.category = category;
    });
    saveRendiciones();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          category == 'cargo'
              ? 'Se configuró como Cargo a rendir'
              : 'Se configuró como Viáticos',
        ),
      ),
    );
  }

  void _addNewItem() {
    if (container.category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero selecciona el tipo de rendición (Cargo/Viáticos)',
          ),
        ),
      );
      return;
    }

    showDialog<RendicionLineItem>(
      context: context,
      builder: (context) => _AddItemDialog(category: container.category),
    ).then((newItem) {
      if (newItem != null) {
        setState(() {
          container.addItem(newItem);
          // También agregar a mockRendiciones para persistencia
          final legacyItem = RendicionItem(
            newItem.date,
            newItem.description,
            newItem.amount,
            correlative: container.correlative,
            category: newItem.category,
            status: container.status,
          );
          mockRendiciones.add(legacyItem);
        });
        saveRendiciones();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item agregado a la rendición')),
        );
      }
    });
  }

  void _removeItem(int index) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar item'),
        content: const Text('¿Eliminar este item de la rendición?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true) {
        setState(() {
          final itemToRemove = container.items[index];
          container.removeItem(index);

          // También remover de mockRendiciones
          mockRendiciones.removeWhere(
            (item) =>
                item.correlative == container.correlative &&
                item.description == itemToRemove.description &&
                item.amount == itemToRemove.amount,
          );
        });
        saveRendiciones();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item eliminado')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(container.status);
    final canAddItems = container.status == 'borrador';
    final needsCategory =
        container.status == 'borrador' && container.category.isEmpty;
    final canSend =
        container.status == 'borrador' &&
        container.category.isNotEmpty &&
        container.items.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.of(context).pop(container);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Rendición'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(container),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del contenedor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correlativo ${container.correlative}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      container.description,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          avatar: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          backgroundColor: statusColor.withAlpha(
                            (0.2 * 255).round(),
                          ),
                          label: Text(
                            _getStatusLabel(container.status),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          'Total: \$${container.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Selección de categoría si es necesaria
              if (needsCategory) ...[
                _buildCategoryPicker(),
                const SizedBox(height: 24),
              ],

              // Items del contenedor
              if (container.items.isNotEmpty) ...[
                _buildItemsSection(),
                const SizedBox(height: 24),
              ] else if (!needsCategory && container.status == 'borrador') ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No hay items. Agrega uno nuevo presionando el botón +',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Botones de acción
              _buildActionButtons(canAddItems, canSend, needsCategory),
            ],
          ),
        ),
        floatingActionButton: canAddItems && !needsCategory
            ? FloatingActionButton(
                onPressed: _addNewItem,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona el tipo de rendición',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Cargo a rendir'),
                onPressed: () => _selectCategory('cargo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flight_takeoff),
                label: const Text('Viáticos'),
                onPressed: () => _selectCategory('viaticos'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items de rendición (${container.items.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          container.items.length,
          (index) => _buildItemCard(index),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final item = container.items[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          item.category == 'cargo' ? 'Cargo' : 'Viático',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: item.category == 'cargo'
                            ? Colors.blue.shade100
                            : Colors.orange.shade100,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.date.day}/${item.date.month}/${item.date.year}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                if (container.status == 'borrador')
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                    ),
                    onPressed: () => _removeItem(index),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool canAdd, bool canSend, bool needsCategory) {
    return Column(
      children: [
        if (canSend)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Enviar rendición completa para aprobación'),
              onPressed: () {
                setState(() {
                  updateRendicionesByCorrelative(
                    container.correlative,
                    'enviado',
                  );
                  container.status = 'enviado';
                });
                saveRendiciones();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rendición ${container.correlative} enviada con ${container.items.length} item(s) para aprobación del administrador.',
                    ),
                  ),
                );
              },
            ),
          )
        else if (needsCategory)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Selecciona el tipo de rendición para continuar.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
          )
        else if (!canAdd && container.status == 'enviado')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'Rendición ${container.correlative} enviada. Contiene ${container.items.length} item(s) y está pendiente de revisión.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade900,
              ),
            ),
          )
        else if (!canAdd && container.status == 'aprobado')
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rendición aprobada. ${container.items.length} item(s) procesado(s).',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (!canAdd && container.status == 'rechazado')
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rendición rechazada. ${container.items.length} item(s) requieren revisión.',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar rendición completa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
            ),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Eliminar rendición'),
                    content: Text(
                      'Eliminar la rendición ${container.correlative} con ${container.items.length} item(s)?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                        ),
                        onPressed: () {
                          mockRendiciones.removeWhere(
                            (item) => item.correlative == container.correlative,
                          );
                          saveRendiciones();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Rendición ${container.correlative} eliminada',
                              ),
                            ),
                          );
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Diálogo para agregar nuevos items
class _AddItemDialog extends StatefulWidget {
  final String category;

  const _AddItemDialog({required this.category});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  late TextEditingController descriptionController;
  late TextEditingController amountController;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController();
    amountController = TextEditingController();
    selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar item a la rendición'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Compra de materiales',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                hintText: '0.00',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: const Text('Cambiar'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (descriptionController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingresa una descripción')),
              );
              return;
            }
            final amount = double.tryParse(amountController.text) ?? 0.0;
            if (amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingresa un monto válido')),
              );
              return;
            }

            final newItem = RendicionLineItem(
              selectedDate,
              descriptionController.text,
              amount,
              category: widget.category,
            );
            Navigator.pop(context, newItem);
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
