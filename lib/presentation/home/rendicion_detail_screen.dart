import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dev_mobile/core/mock_data.dart';

class RendicionDetailScreen extends StatefulWidget {
  final RendicionItem rendicion;
  final int index;

  const RendicionDetailScreen({
    super.key,
    required this.rendicion,
    required this.index,
  });

  @override
  State<RendicionDetailScreen> createState() => _RendicionDetailScreenState();
}

class _RendicionDetailScreenState extends State<RendicionDetailScreen> {
  late RendicionItem rendicion;

  @override
  void initState() {
    super.initState();
    rendicion = widget.rendicion;
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(rendicion.status);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.of(context).pop(rendicion);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Rendición'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(rendicion),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen de factura
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: rendicion.imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(rendicion.imageBase64!),
                          fit: BoxFit.contain,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sin imagen de factura',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Estado
              Row(
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
                    backgroundColor: statusColor.withAlpha((0.2 * 255).round()),
                    label: Text(
                      _getStatusLabel(rendicion.status),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Información de factura
              _buildSection('Información de Factura', [
                _buildInfoRow('Factura/Boleta', rendicion.invoiceNumber),
                _buildInfoRow('Proveedor', rendicion.supplier),
                _buildInfoRow(
                  'Fecha',
                  '${rendicion.date.day}/${rendicion.date.month}/${rendicion.date.year}',
                ),
              ]),
              const SizedBox(height: 16),

              // Información del gasto
              _buildSection('Información del Gasto', [
                _buildInfoRow('Descripción', rendicion.description),
                _buildInfoRow('Tipo', rendicion.type.toUpperCase()),
                _buildInfoRow(
                  'Monto',
                  '\$${rendicion.amount.toStringAsFixed(2)}',
                  isHighlight: true,
                ),
              ]),
              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(height: 1, color: Colors.grey.shade300),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                color: isHighlight ? Colors.green.shade600 : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (rendicion.status == 'borrador')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Enviar para Aprobación'),
              onPressed: () {
                setState(() {
                  rendicion.status = 'enviado';
                });
                saveRendiciones();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enviado para aprobación')),
                );
              },
            ),
          )
        else if (rendicion.status == 'enviado')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Text(
              'La rendición fue enviada y está pendiente de revisión del administrador.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          )
        else if (rendicion.status == 'aprobado')
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
                const Expanded(
                  child: Text(
                    'Rendición aprobada por el administrador',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (rendicion.status == 'rechazado')
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
                const Expanded(
                  child: Text(
                    'Rendición rechazada por el administrador',
                    style: TextStyle(
                      color: Colors.red,
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
            label: const Text('Eliminar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
            ),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Eliminar rendición'),
                    content: const Text(
                      '¿Estás seguro de que deseas eliminar esta rendición?',
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
                          mockRendiciones.removeAt(widget.index);
                          saveRendiciones();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rendición eliminada'),
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
