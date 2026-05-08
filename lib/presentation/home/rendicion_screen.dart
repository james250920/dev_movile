import 'package:flutter/material.dart';
import 'package:dev_mobile/core/mock_data.dart';

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

                return Card(
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
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (r.status == 'borrador')
                                  IconButton(
                                    icon: const Icon(Icons.send, size: 20),
                                    tooltip: 'Enviar',
                                    onPressed: () {
                                      setState(() {
                                        r.status = 'enviado';
                                      });
                                      saveRendiciones();
                                    },
                                  ),
                                if (r.status == 'enviado') ...[
                                  IconButton(
                                    icon: const Icon(Icons.check, size: 20),
                                    tooltip: 'Aprobar',
                                    onPressed: () {
                                      setState(() {
                                        r.status = 'aprobado';
                                      });
                                      saveRendiciones();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    tooltip: 'Rechazar',
                                    onPressed: () {
                                      setState(() {
                                        r.status = 'rechazado';
                                      });
                                      saveRendiciones();
                                    },
                                  ),
                                ],
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  tooltip: 'Eliminar',
                                  onPressed: () {
                                    setState(() {
                                      mockRendiciones.removeAt(index);
                                    });
                                    saveRendiciones();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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
              String selectedType = 'otros';
              final formKey = GlobalKey<FormState>();

              return AlertDialog(
                title: const Text('Nuevo reembolso'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Ingresa descripción'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Monto'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa monto';
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
                            DropdownMenuItem(value: 'asi', child: Text('ASI')),
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
                          decoration: const InputDecoration(labelText: 'Tipo'),
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
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setState(() {
                        mockRendiciones.add(
                          RendicionItem(
                            DateTime.now(),
                            descCtrl.text.trim(),
                            double.parse(amountCtrl.text),
                            type: selectedType,
                            status: 'borrador',
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
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setState(() {
                        mockRendiciones.add(
                          RendicionItem(
                            DateTime.now(),
                            descCtrl.text.trim(),
                            double.parse(amountCtrl.text),
                            type: selectedType,
                            status: 'enviado',
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
