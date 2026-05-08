import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dev_mobile/core/mock_data.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  @override
  void initState() {
    super.initState();
    loadProjectsAndWorkers().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trabajadores')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: mockWorkers.length,
        itemBuilder: (context, i) {
          final w = mockWorkers[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(w.name),
              subtitle: Text(w.qr),
              trailing: SizedBox(width: 80, child: QrImageView(data: w.qr)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nameCtrl = TextEditingController();
          final ok = await showDialog<bool?>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Nuevo trabajador'),
              content: TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Nombre'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Agregar'),
                ),
              ],
            ),
          );
          if (ok == true && nameCtrl.text.trim().isNotEmpty) {
            final name = nameCtrl.text.trim();
            mockWorkers.add(WorkerItem(name, 'employee:$name'));
            await saveProjectsAndWorkers();
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
