import 'package:flutter/material.dart';
import 'package:dev_mobile/domain/models/rendicion.dart';
import 'package:intl/intl.dart';

class RendicionCard extends StatelessWidget {
  final Rendicion rendicion;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const RendicionCard({
    Key? key,
    required this.rendicion,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (rendicion.estado) {
      case RendicionStatus.borrador:
        return Colors.grey;
      case RendicionStatus.enviada:
        return Colors.blue;
      case RendicionStatus.observada:
        return Colors.orange;
      case RendicionStatus.aprobada:
        return Colors.green;
      case RendicionStatus.rechazada:
        return Colors.red;
      case RendicionStatus.pagada:
        return Colors.teal;
    }
  }

  String _getStatusLabel() {
    final labels = {
      RendicionStatus.borrador: 'Borrador',
      RendicionStatus.enviada: 'Enviada',
      RendicionStatus.observada: 'Observada',
      RendicionStatus.aprobada: 'Aprobada',
      RendicionStatus.rechazada: 'Rechazada',
      RendicionStatus.pagada: 'Pagada',
    };
    return labels[rendicion.estado] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final formato = DateFormat('dd/MM/yyyy');

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(rendicion.titulo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              rendicion.descripcion,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    _getStatusLabel(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  'S/. ${rendicion.totalGastos.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Creada: ${formato.format(rendicion.fechaCreacion)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: onDelete != null
            ? PopupMenuButton(
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(child: Text('Eliminar')),
                ],
                onSelected: (value) {
                  if (value == 'Eliminar') {
                    onDelete?.call();
                  }
                },
              )
            : null,
      ),
    );
  }
}

class EstadoBadge extends StatelessWidget {
  final RendicionStatus estado;

  const EstadoBadge({Key? key, required this.estado}) : super(key: key);

  Color _getColor() {
    switch (estado) {
      case RendicionStatus.borrador:
        return Colors.grey;
      case RendicionStatus.enviada:
        return Colors.blue;
      case RendicionStatus.observada:
        return Colors.orange;
      case RendicionStatus.aprobada:
        return Colors.green;
      case RendicionStatus.rechazada:
        return Colors.red;
      case RendicionStatus.pagada:
        return Colors.teal;
    }
  }

  String _getLabel() {
    final labels = {
      RendicionStatus.borrador: 'Borrador',
      RendicionStatus.enviada: 'Enviada',
      RendicionStatus.observada: 'Observada',
      RendicionStatus.aprobada: 'Aprobada',
      RendicionStatus.rechazada: 'Rechazada',
      RendicionStatus.pagada: 'Pagada',
    };
    return labels[estado] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColor().withAlpha(200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getLabel(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ResumenFinanciero extends StatelessWidget {
  final double montoComprobantes;
  final double montoGastosManuales;
  final double montoTotal;

  const ResumenFinanciero({
    Key? key,
    required this.montoComprobantes,
    required this.montoGastosManuales,
    required this.montoTotal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Comprobantes:'),
                Text(
                  'S/. ${montoComprobantes.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gastos Manuales:'),
                Text(
                  'S/. ${montoGastosManuales.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'S/. ${montoTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final IconData icono;

  const EmptyStateWidget({
    Key? key,
    required this.titulo,
    required this.mensaje,
    this.icono = Icons.inbox,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
