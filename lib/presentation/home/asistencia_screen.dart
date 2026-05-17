import 'package:dev_mobile/core/mock_data.dart';
import 'package:dev_mobile/presentation/home/attendance_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  bool _isMarking = false;
  bool _loadingData = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _loadError = null;
      await Future.wait([
        loadAsistencias(),
        loadProjectsAndWorkers(),
        loadImputacionesTiempo(),
        loadTareos(),
      ]).timeout(const Duration(seconds: 3));
    } catch (e) {
      _loadError = 'Error al cargar asistencia.';
    } finally {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
      }
    }
  }

  Future<void> _openQrScanner(StateSetter setModalState) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final rawValue = barcodes.first.rawValue;
              if (rawValue == null || rawValue.isEmpty) return;

              Navigator.of(context).pop();

              String? project;
              final normalized = rawValue.trim().toLowerCase();

              if (normalized.startsWith('project:')) {
                project = rawValue.substring(8).trim();
              } else if (normalized.startsWith('proyecto:')) {
                project = rawValue.substring(9).trim();
              } else if (mockProjects.contains(rawValue)) {
                project = rawValue;
              }

              if (project != null && project.isNotEmpty) {
                setModalState(() {});
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _openMarkForm() async {
    String selectedProject = mockProjects.isNotEmpty
        ? mockProjects.first
        : 'General';
    double selectedHours = 8;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Marcar asistencia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Escanear QR',
                        onPressed: () => _openQrScanner(setModalState),
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentWorker,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProject,
                    items: mockProjects
                        .map(
                          (project) => DropdownMenuItem(
                            value: project,
                            child: Text(project),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          selectedProject = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Proyecto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Horas a imputar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [4, 6, 8, 10, 12].map((hours) {
                      final isSelected = selectedHours == hours.toDouble();
                      return ChoiceChip(
                        label: Text('${hours}h'),
                        selected: isSelected,
                        onSelected: (_) {
                          setModalState(() {
                            selectedHours = hours.toDouble();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isMarking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isMarking ? 'Registrando...' : 'Marcar asistencia',
                      ),
                      onPressed: _isMarking
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                setState(() {
                                  _isMarking = true;
                                });

                                await registrarAsistenciaConImputacion(
                                  project: selectedProject,
                                  horasTrabajadas: selectedHours,
                                  checkInTime: DateTime.now(),
                                  latitude: null,
                                  longitude: null,
                                  locationLabel: 'Marcado en sitio',
                                );

                                if (mounted) {
                                  setState(() {});
                                }

                                navigator.pop();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Asistencia registrada: $selectedProject ($selectedHours h)',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isMarking = false;
                                  });
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi asistencia')),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadError != null) ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                        ),
                        title: const Text('Advertencia'),
                        subtitle: Text(_loadError!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Trabajador: $currentWorker',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAsistenciaCard(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('Ver historial'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AttendanceHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMarkForm,
        label: const Text('Marcar'),
        icon: const Icon(Icons.add_circle_outline),
      ),
    );
  }

  Widget _buildAsistenciaCard() {
    final asistencia = mockAsistenciasPersonal.isNotEmpty
        ? mockAsistenciasPersonal.first
        : null;
    final isPresent = asistencia?.present ?? false;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isPresent
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  child: Icon(
                    isPresent ? Icons.check : Icons.schedule,
                    color: isPresent ? Colors.green : Colors.grey.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPresent ? 'Presente' : 'Sin marcar hoy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isPresent
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (isPresent && asistencia != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          asistencia.project.isEmpty
                              ? 'Proyecto no asignado'
                              : asistencia.project,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isPresent && asistencia != null) ...[
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 12),
              _infoRow(
                Icons.work_outline,
                'Proyecto',
                asistencia.project.isEmpty ? '-' : asistencia.project,
              ),
              const SizedBox(height: 8),
              _infoRow(
                Icons.access_time,
                'Hora',
                asistencia.checkInTime == null
                    ? '-'
                    : '${asistencia.checkInTime!.hour.toString().padLeft(2, '0')}:${asistencia.checkInTime!.minute.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 8),
              _infoRow(
                Icons.location_on_outlined,
                'Ubicación',
                asistencia.locationLabel ?? 'Sin ubicación',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
