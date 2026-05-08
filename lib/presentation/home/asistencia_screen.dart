import 'package:flutter/material.dart';
import 'package:dev_mobile/core/mock_data.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de asistencia')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockAsistencias.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final a = mockAsistencias[i];
          return ListTile(
            title: Text(a.name),
            subtitle: Text('${a.date.day}/${a.date.month}/${a.date.year}'),
            trailing: Switch(
              value: a.present,
              onChanged: (v) {
                setState(() => a.present = v);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            mockAsistencias.add(
              AsistenciaItem(DateTime.now(), 'Nuevo participante'),
            );
          });
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
