import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dev_mobile/core/mock_data.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    loadProjectsAndWorkers().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proyectos')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: mockProjects.length,
        itemBuilder: (context, i) {
          final p = mockProjects[i];
          final qrData = 'project:$p';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(p),
              trailing: SizedBox(width: 80, child: QrImageView(data: qrData)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ctrl = TextEditingController();
          final ok = await showDialog<bool?>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Nuevo proyecto'),
              content: TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  hintText: 'Nombre del proyecto',
                ),
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
          if (ok == true && ctrl.text.trim().isNotEmpty) {
            mockProjects.add(ctrl.text.trim());
            await saveProjectsAndWorkers();
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
