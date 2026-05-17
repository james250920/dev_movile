import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dev_mobile/domain/models/comprobante.dart';
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

  Future<void> _addCargoItem() async {
    final newItem = await showDialog<RendicionLineItem>(
      context: context,
      builder: (context) => const _CargoItemDialog(),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      container.addItem(newItem);
      if (container.category.isEmpty ||
          container.category == newItem.category) {
        container.category = newItem.category;
      } else {
        container.category = 'mixta';
      }

      mockRendiciones.add(
        RendicionItem(
          newItem.date,
          newItem.description,
          newItem.amount,
          correlative: container.correlative,
          category: newItem.category,
          status: container.status,
          comprobanteType: newItem.comprobanteType,
          invoiceNumber: newItem.invoiceNumber,
          supplier: newItem.supplier,
          ruc: newItem.ruc,
          detail: newItem.detail,
          imageBase64: newItem.imageBase64,
        ),
      );
    });

    await saveRendiciones();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cargo a rendir agregado')));
    }
  }

  Future<void> _addViaticoItem() async {
    final newItem = await showDialog<RendicionLineItem>(
      context: context,
      builder: (context) => const _ViaticoItemDialog(),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      container.addItem(newItem);
      if (container.category.isEmpty ||
          container.category == newItem.category) {
        container.category = newItem.category;
      } else {
        container.category = 'mixta';
      }

      mockRendiciones.add(
        RendicionItem(
          newItem.date,
          newItem.description,
          newItem.amount,
          correlative: container.correlative,
          category: newItem.category,
          status: container.status,
          comprobanteType: newItem.comprobanteType,
          invoiceNumber: newItem.invoiceNumber,
          supplier: newItem.supplier,
          ruc: newItem.ruc,
          detail: newItem.detail,
          imageBase64: newItem.imageBase64,
        ),
      );
    });

    await saveRendiciones();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Viático agregado')));
    }
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
                item.date.isAtSameMomentAs(itemToRemove.date) &&
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
    final canSend =
        container.status == 'borrador' && container.items.isNotEmpty;

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

              if (canAddItems) ...[
                _buildQuickAddButtons(canAddItems),
                const SizedBox(height: 24),
              ],

              if (container.items.isNotEmpty) ...[
                _buildItemsSection(),
                const SizedBox(height: 24),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No hay items. Usa los botones para agregar un cargo o un viático.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              _buildActionButtons(canSend),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddButtons(bool canAddItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agregar comprobantes',
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
                onPressed: canAddItems ? _addCargoItem : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flight_takeoff),
                label: const Text('Viáticos'),
                onPressed: canAddItems ? _addViaticoItem : null,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                      if ((item.comprobanteType ?? '').isNotEmpty)
                        Chip(
                          label: Text(
                            item.comprobanteType!.toUpperCase(),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      if (item.imageBase64 != null)
                        const Chip(
                          avatar: Icon(Icons.image, size: 16),
                          label: Text(
                            'Con imagen',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.date.day}/${item.date.month}/${item.date.year}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if ((item.invoiceNumber ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Comprobante: ${item.invoiceNumber}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if ((item.supplier ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Proveedor: ${item.supplier}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if ((item.ruc ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'RUC: ${item.ruc}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if ((item.detail ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Detalle: ${item.detail}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
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

  Widget _buildActionButtons(bool canSend) {
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
        else if (container.status == 'enviado')
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
        else if (container.status == 'aprobado')
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
        else if (container.status == 'rechazado')
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

Future<String?> _pickImageBase64(ImageSource source) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
  if (pickedFile == null) {
    return null;
  }

  final bytes = await pickedFile.readAsBytes();
  return base64Encode(bytes);
}

class _CargoItemDialog extends StatefulWidget {
  const _CargoItemDialog();

  @override
  State<_CargoItemDialog> createState() => _CargoItemDialogState();
}

class _CargoItemDialogState extends State<_CargoItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroController;
  late final TextEditingController _rucController;
  late final TextEditingController _proveedorController;
  late final TextEditingController _detalleController;
  late final TextEditingController _montoController;
  late final TextEditingController _fechaController;
  TipoComprobante _tipoComprobante = TipoComprobante.factura;
  DateTime _selectedDate = DateTime.now();
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController();
    _rucController = TextEditingController();
    _proveedorController = TextEditingController();
    _detalleController = TextEditingController();
    _montoController = TextEditingController();
    _fechaController = TextEditingController(
      text: _selectedDate.toIso8601String().split('T').first,
    );
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _rucController.dispose();
    _proveedorController.dispose();
    _detalleController.dispose();
    _montoController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _setImage(ImageSource source) async {
    final image = await _pickImageBase64(source);
    if (image == null) {
      return;
    }

    setState(() {
      _imageBase64 = image;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _fechaController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjunta una imagen del comprobante')),
      );
      return;
    }

    final number = _numeroController.text.trim();
    final supplier = _proveedorController.text.trim();
    final amount = double.parse(_montoController.text.trim());
    final detail = _detalleController.text.trim();

    Navigator.of(context).pop(
      RendicionLineItem(
        _selectedDate,
        '$supplier - $number',
        amount,
        category: 'cargo',
        comprobanteType: _tipoComprobante.name,
        invoiceNumber: number,
        supplier: supplier,
        ruc: _rucController.text.trim(),
        detail: detail.isEmpty ? null : detail,
        imageBase64: _imageBase64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cargo a rendir'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _setImage(ImageSource.camera),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear factura/boleta'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setImage(ImageSource.gallery),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Cargar imagen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_imageBase64 != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Imagen adjunta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoComprobante>(
                value: _tipoComprobante,
                decoration: const InputDecoration(
                  labelText: 'Tipo de comprobante',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TipoComprobante.factura,
                    child: Text('Factura'),
                  ),
                  DropdownMenuItem(
                    value: TipoComprobante.boleta,
                    child: Text('Boleta'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _tipoComprobante = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número de comprobante',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rucController,
                decoration: const InputDecoration(
                  labelText: 'RUC',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el RUC';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _proveedorController,
                decoration: const InputDecoration(
                  labelText: 'Proveedor / Comercio',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el proveedor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detalleController,
                decoration: const InputDecoration(
                  labelText: 'Detalle',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixText: 'S/. ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

class _ViaticoItemDialog extends StatefulWidget {
  const _ViaticoItemDialog();

  @override
  State<_ViaticoItemDialog> createState() => _ViaticoItemDialogState();
}

class _ViaticoItemDialogState extends State<_ViaticoItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _detalleController;
  late final TextEditingController _montoController;
  late final TextEditingController _fechaController;
  DateTime _selectedDate = DateTime.now();
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _detalleController = TextEditingController();
    _montoController = TextEditingController();
    _fechaController = TextEditingController(
      text: _selectedDate.toIso8601String().split('T').first,
    );
  }

  @override
  void dispose() {
    _detalleController.dispose();
    _montoController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _setImage(ImageSource source) async {
    final image = await _pickImageBase64(source);
    if (image == null) {
      return;
    }

    setState(() {
      _imageBase64 = image;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _fechaController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjunta una imagen del viático')),
      );
      return;
    }

    final detail = _detalleController.text.trim();
    final amount = double.parse(_montoController.text.trim());

    Navigator.of(context).pop(
      RendicionLineItem(
        _selectedDate,
        detail,
        amount,
        category: 'viaticos',
        detail: detail,
        imageBase64: _imageBase64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Viáticos'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _setImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Escanear'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setImage(ImageSource.gallery),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Cargar imagen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_imageBase64 != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Imagen adjunta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detalleController,
                decoration: const InputDecoration(
                  labelText: 'Detalle del viático',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el detalle';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixText: 'S/. ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
