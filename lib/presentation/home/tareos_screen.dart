import 'package:flutter/material.dart';
import 'package:dev_mobile/core/mock_data.dart';
import 'package:dev_mobile/presentation/home/tareo_detail_screen.dart';

class TareosScreen extends StatefulWidget {
  const TareosScreen({super.key});

  @override
  State<TareosScreen> createState() => _TareosScreenState();
}

class _TareosScreenState extends State<TareosScreen> {
  final _taskController = TextEditingController();
  final _hoursController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedProject = mockProjects.first;
  String _selectedMonth =
      '${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}';
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTareosSafely();
  }

  Future<void> _loadTareosSafely() async {
    try {
      _loadError = null;
      await loadTareos();
      if (mockTareos.isNotEmpty) {
        _selectedProject = mockTareos.first.project.isNotEmpty
            ? mockTareos.first.project
            : _selectedProject;
      }
    } catch (e) {
      // If SQLite fails for any reason, keep the screen usable with in-memory data.
      _loadError =
          'No se pudo cargar tareos desde SQLite. Se usan datos locales.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    _hoursController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<String> _last12Months() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _showTareoDialog({int? index}) async {
    final isEdit = index != null;
    final tareo = isEdit ? mockTareos[index] : null;

    _taskController.text = tareo?.task ?? '';
    _hoursController.text = tareo?.hours.toString() ?? '';
    _amountController.text = tareo?.amount.toString() ?? '';
    _selectedProject = tareo?.project.isNotEmpty == true
        ? tareo!.project
        : (mockProjects.isNotEmpty ? mockProjects.first : '');
    _selectedMonth =
        tareo?.month ??
        '${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar tareo' : 'Nuevo tareo'),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProject,
                  items: mockProjects
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        _selectedProject = v;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Proyecto'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMonth,
                  items: _last12Months()
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        _selectedMonth = v;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Mes'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final task = _taskController.text.trim();
                final hours = double.tryParse(_hoursController.text) ?? 0.0;
                final amount = double.tryParse(_amountController.text) ?? 0.0;
                if (task.isEmpty) return;

                setState(() {
                  final updated = TareoItem(
                    isEdit ? tareo!.date : DateTime.now(),
                    task,
                    hours,
                    project: _selectedProject,
                    month: _selectedMonth,
                    amount: amount,
                  );
                  if (isEdit) {
                    mockTareos[index] = updated;
                  } else {
                    mockTareos.add(updated);
                  }
                });

                await saveTareos();
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(isEdit ? 'Guardar cambios' : 'Agregar'),
            ),
          ],
        ),
      ),
    );

    _taskController.clear();
    _hoursController.clear();
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Sistema de Tareos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockTareos.length + (_loadError != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (_loadError != null && i == 0) {
            return Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                title: const Text('Carga parcial de tareos'),
                subtitle: Text(_loadError!),
                trailing: TextButton(
                  onPressed: _loadTareosSafely,
                  child: const Text('Reintentar'),
                ),
              ),
            );
          }

          final adjustedIndex = _loadError != null ? i - 1 : i;
          final t = mockTareos[adjustedIndex];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.work_outline),
              title: Text(t.task),
              subtitle: Text('${t.month} • ${t.project} • ${t.hours} h'),
              trailing: Text('\$${t.amount.toStringAsFixed(2)}'),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TareoDetailScreen(
                      tareo: t,
                      index: adjustedIndex,
                      onChanged: () async {
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                );
                if (mounted) setState(() {});
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTareoDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
