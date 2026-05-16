import 'package:dev_mobile/core/mock_data.dart';
import 'package:flutter/material.dart';

class TareoDetailScreen extends StatelessWidget {
  final TareoItem tareo;
  final int index;
  final Future<void> Function() onChanged;

  const TareoDetailScreen({
    super.key,
    required this.tareo,
    required this.index,
    required this.onChanged,
  });

  Future<void> _showDeleteConfirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tareo'),
        content: const Text('¿Deseas eliminar este tareo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      mockTareos.removeAt(index);
      await saveTareos();
      if (context.mounted) {
        Navigator.pop(context);
      }
      await onChanged();
    }
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final taskController = TextEditingController(text: tareo.task);
    final hoursController = TextEditingController(text: tareo.hours.toString());
    final amountController = TextEditingController(
      text: tareo.amount.toString(),
    );
    String selectedProject = tareo.project.isNotEmpty
        ? tareo.project
        : mockProjects.first;
    String selectedMonth = tareo.month;

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar tareo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(labelText: 'Tarea'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: hoursController,
                  decoration: const InputDecoration(labelText: 'Horas'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedProject,
                  items: mockProjects
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedProject = v);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Proyecto'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedMonth,
                  items: List.generate(12, (i) {
                    final d = DateTime.now();
                    final month = DateTime(d.year, d.month - i, 1);
                    final value =
                        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
                    return DropdownMenuItem(value: value, child: Text(value));
                  }),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedMonth = v);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Mes'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Monto'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      tareo.task = taskController.text.trim();
      tareo.hours = double.tryParse(hoursController.text) ?? tareo.hours;
      tareo.amount = double.tryParse(amountController.text) ?? tareo.amount;
      tareo.project = selectedProject;
      tareo.month = selectedMonth;
      await saveTareos();
      if (context.mounted) {
        Navigator.pop(context);
      }
      await onChanged();
    }
  }

  Future<void> _cambiarEstado(BuildContext context, String nuevoEstado) async {
    tareo.status = nuevoEstado;
    await saveTareos();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tareo marcado como $nuevoEstado')),
      );
    }
    await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de tareo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tareo.task,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row('Mes', tareo.month),
                  _row('Proyecto', tareo.project.isEmpty ? '-' : tareo.project),
                  _row(
                    'Trabajador',
                    tareo.workerName.isEmpty ? '-' : tareo.workerName,
                  ),
                  _row('Horas', '${tareo.hours} h'),
                  _row('Monto', '\$${tareo.amount.toStringAsFixed(2)}'),
                  _row('Origen', tareo.source),
                  _row('Estado', tareo.status),
                  _row(
                    'Fecha',
                    '${tareo.date.day}/${tareo.date.month}/${tareo.date.year}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar tareo'),
              onPressed: () => _showEditDialog(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_outlined),
              label: const Text('Enviar para aprobación'),
              onPressed: () => _cambiarEstado(context, 'enviado'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Aprobar'),
                  onPressed: () => _cambiarEstado(context, 'aprobado'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Rechazar'),
                  onPressed: () => _cambiarEstado(context, 'rechazado'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar tareo'),
              onPressed: () => _showDeleteConfirm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
