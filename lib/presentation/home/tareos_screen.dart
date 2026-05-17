import 'package:flutter/material.dart';
import 'package:dev_mobile/core/mock_data.dart';
import 'package:dev_mobile/presentation/home/asistencia_screen.dart';
import 'package:dev_mobile/presentation/home/tareo_detail_screen.dart';

class TareosScreen extends StatefulWidget {
  const TareosScreen({super.key});

  @override
  State<TareosScreen> createState() => _TareosScreenState();
}

class _TareosScreenState extends State<TareosScreen> {
  final _taskController = TextEditingController();
  final _workerController = TextEditingController();
  final _hoursController = TextEditingController();
  final _amountController = TextEditingController();
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTareosSafely();
  }

  String get _currentMonth {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTareosSafely() async {
    try {
      _loadError = null;
      await Future.wait([loadTareos(), loadImputacionesTiempo()]);
    } catch (e) {
      _loadError = 'Error inesperado al cargar tareos. Se usan datos locales.';
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
    _workerController.dispose();
    _hoursController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<TareoItem> _sortedTareos() {
    return mockTareos.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _resyncFromAttendance() async {
    setState(() => _loading = true);
    await regenerarTareosDesdeImputaciones(month: _currentMonth);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tareos del mes recalculados desde asistencias'),
        ),
      );
    }
  }

  Future<void> _showTareoDialog({int? index}) async {
    final isEdit = index != null;
    final tareo = isEdit ? mockTareos[index] : null;

    _taskController.text = tareo?.task ?? '';
    _workerController.text = tareo?.workerName ?? '';
    _hoursController.text = tareo?.hours.toString() ?? '';
    _amountController.text = tareo?.amount.toString() ?? '';
    final projectForDialog = tareo?.project.isNotEmpty == true
        ? tareo!.project
        : (mockProjects.isNotEmpty ? mockProjects.first : 'General');
    var monthForDialog =
        tareo?.month ??
        '${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}';
    var selectedProjectDialog = projectForDialog;

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
                  controller: _workerController,
                  decoration: const InputDecoration(
                    labelText: 'Trabajador (opcional)',
                  ),
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
                  initialValue: selectedProjectDialog,
                  items: mockProjects
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        selectedProjectDialog = v;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Proyecto'),
                ),
                const SizedBox(height: 8),
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
                    workerName: _workerController.text.trim(),
                    project: selectedProjectDialog,
                    month: monthForDialog,
                    amount: amount,
                    status: tareo?.status ?? 'borrador',
                    source: tareo?.source ?? 'manual',
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
    _workerController.clear();
    _hoursController.clear();
    _amountController.clear();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      case 'enviado':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tareos = _sortedTareos();
    final resumen = resumenMensualTareos(_currentMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Tareos'),
        actions: [
          IconButton(
            tooltip: 'Recalcular desde asistencia',
            onPressed: _resyncFromAttendance,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tareos.length + (_loadError != null ? 2 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  child: ListTile(
                    title: Text(
                      'Resumen mensual ${resumen['month']}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Horas: ${(resumen['totalHoras'] as double).toStringAsFixed(1)} • Costo: \$${(resumen['totalCosto'] as double).toStringAsFixed(2)}',
                    ),
                  ),
                ),
              ],
            );
          }

          if (_loadError != null && i == 1) {
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

          final adjustedIndex = _loadError != null ? i - 2 : i - 1;
          final t = tareos[adjustedIndex];
          final rawIndex = mockTareos.indexOf(t);
          return Card(
            child: ListTile(
              leading: Icon(
                t.source == 'asistencia'
                    ? Icons.qr_code_scanner_outlined
                    : Icons.work_outline,
              ),
              title: Text(t.task),
              subtitle: Text(
                '${t.month} • ${t.project} • ${t.hours} h${t.workerName.isEmpty ? '' : ' • ${t.workerName}'}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${t.amount.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(t.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      t.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: _statusColor(t.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () async {
                final shouldMark = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Tareo: ${t.task}'),
                    content: Text('Proyecto: ${t.project}\nHoras: ${t.hours}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Marcar asistencia'),
                      ),
                    ],
                  ),
                );

                if (shouldMark == true) {
                  try {
                    await registrarAsistenciaConImputacion(
                      project: t.project,
                      horasTrabajadas: t.hours > 0 ? t.hours : 8.0,
                      checkInTime: DateTime.now(),
                      latitude: null,
                      longitude: null,
                      locationLabel: 'Marcado desde tareo',
                    );
                    if (mounted) setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Asistencia marcada para ${t.project}'),
                      ),
                    );
                    if (context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AsistenciaScreen(),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al marcar: $e')),
                    );
                  }
                }
              },
            ),
          );
        },
      ),
      // No permitir crear tareos manualmente desde esta vista; son provistos por la empresa
      floatingActionButton: null,
    );
  }
}
