import 'package:flutter/material.dart';
import 'package:dev_mobile/core/mock_data.dart';

class TareosScreen extends StatefulWidget {
  const TareosScreen({super.key});

  @override
  State<TareosScreen> createState() => _TareosScreenState();
}

class _TareosScreenState extends State<TareosScreen> {
  final _taskController = TextEditingController();
  final _hoursController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo tareo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskController,
                decoration: const InputDecoration(labelText: 'Tarea'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _hoursController,
                decoration: const InputDecoration(labelText: 'Horas'),
                keyboardType: TextInputType.number,
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
              final task = _taskController.text.trim();
              final hours = double.tryParse(_hoursController.text) ?? 0.0;
              if (task.isNotEmpty) {
                setState(() {
                  mockTareos.add(TareoItem(DateTime.now(), task, hours));
                });
                _taskController.clear();
                _hoursController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sistema de Tareos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockTareos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final t = mockTareos[i];
          return ListTile(
            leading: const Icon(Icons.work_outline),
            title: Text(t.task),
            subtitle: Text(
              '${t.date.day}/${t.date.month}/${t.date.year} - ${t.hours} h',
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
