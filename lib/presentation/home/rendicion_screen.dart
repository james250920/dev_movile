import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dev_mobile/core/mock_data.dart';
import 'package:dev_mobile/presentation/home/rendicion_detail_screen.dart';

class RendicionScreen extends StatefulWidget {
  const RendicionScreen({super.key});

  @override
  State<RendicionScreen> createState() => _RendicionScreenState();
}

class _RendicionScreenState extends State<RendicionScreen> {
  @override
  void initState() {
    super.initState();
    loadRendiciones().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rendición de cuentas')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (mockRendiciones.isEmpty) {
              return Center(
                child: Text(
                  'No hay rendiciones registradas',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            return ListView.separated(
              itemCount: mockRendiciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final r = mockRendiciones[index];
                Color statusColor;
                switch (r.status) {
                  case 'aprobado':
                    statusColor = Colors.green.shade400;
                    break;
                  case 'enviado':
                    statusColor = Colors.orange.shade400;
                    break;
                  case 'rechazado':
                    statusColor = Colors.red.shade400;
                    break;
                  default:
                    statusColor = Colors.grey.shade400;
                }

                return InkWell(
                  onTap: () async {
                    final result = await Navigator.of(context)
                        .push<RendicionItem>(
                          MaterialPageRoute(
                            builder: (context) => RendicionDetailScreen(
                              rendicion: r,
                              index: index,
                            ),
                          ),
                        );
                    if (result != null) {
                      setState(() {
                        mockRendiciones[index] = result;
                      });
                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Preview de imagen de factura
                          if (r.imageBase64 != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                base64Decode(r.imageBase64!),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.receipt,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (r.supplier.isNotEmpty)
                                  Text(
                                    'Proveedor: ${r.supplier}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                if (r.invoiceNumber.isNotEmpty)
                                  Text(
                                    'Factura: ${r.invoiceNumber}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      r.type.toUpperCase(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${r.date.day}/${r.date.month}/${r.date.year}',
                                      style: const TextStyle(fontSize: 12),
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
                                '\$${r.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                backgroundColor: statusColor.withAlpha(
                                  (0.2 * 255).round(),
                                ),
                                label: Text(
                                  r.status,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              final descCtrl = TextEditingController();
              final amountCtrl = TextEditingController();
              final invoiceCtrl = TextEditingController();
              final supplierCtrl = TextEditingController();
              String selectedType = 'otros';
              final formKey = GlobalKey<FormState>();
              String? imageBase64;

              return StatefulBuilder(
                builder: (context, dialogSetState) {
                  return AlertDialog(
                    title: const Text('Nueva rendición'),
                    content: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Preview de imagen
                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: imageBase64 != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(imageBase64!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size: 40,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Sin imagen',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 12),
                            // Botones de captura
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Cámara'),
                                  onPressed: () async {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 80,
                                    );
                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      dialogSetState(() {
                                        imageBase64 = base64Encode(bytes);
                                      });
                                    }
                                  },
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.image),
                                  label: const Text('Galería'),
                                  onPressed: () async {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 80,
                                    );
                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      dialogSetState(() {
                                        imageBase64 = base64Encode(bytes);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Campos de texto
                            TextFormField(
                              controller: descCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Descripción del gasto',
                                hintText: 'Ej: Compra de materiales',
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Ingresa descripción'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: supplierCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Proveedor / Comercio',
                                hintText: 'Ej: Ferretería XYZ',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: invoiceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Número de factura/boleta',
                                hintText: 'Ej: 001-001-000123456',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Monto',
                                prefixText: '\$',
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Ingresa monto';
                                }
                                if (double.tryParse(v) == null) {
                                  return 'Monto inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedType,
                              items: const [
                                DropdownMenuItem(
                                  value: 'asi',
                                  child: Text('ASI'),
                                ),
                                DropdownMenuItem(
                                  value: 'viaticos',
                                  child: Text('Viáticos'),
                                ),
                                DropdownMenuItem(
                                  value: 'otros',
                                  child: Text('Otros'),
                                ),
                              ],
                              onChanged: (v) => selectedType = v ?? 'otros',
                              decoration: const InputDecoration(
                                labelText: 'Tipo',
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
                      TextButton(
                        onPressed: () {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() {
                            mockRendiciones.add(
                              RendicionItem(
                                DateTime.now(),
                                descCtrl.text.trim(),
                                double.parse(amountCtrl.text),
                                type: selectedType,
                                status: 'borrador',
                                invoiceNumber: invoiceCtrl.text.trim(),
                                supplier: supplierCtrl.text.trim(),
                                imageBase64: imageBase64,
                              ),
                            );
                          });
                          saveRendiciones();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Guardar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() {
                            mockRendiciones.add(
                              RendicionItem(
                                DateTime.now(),
                                descCtrl.text.trim(),
                                double.parse(amountCtrl.text),
                                type: selectedType,
                                status: 'enviado',
                                invoiceNumber: invoiceCtrl.text.trim(),
                                supplier: supplierCtrl.text.trim(),
                                imageBase64: imageBase64,
                              ),
                            );
                          });
                          saveRendiciones();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enviado para aprobación'),
                            ),
                          );
                        },
                        child: const Text('Guardar y enviar'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
