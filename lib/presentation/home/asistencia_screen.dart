import 'package:dev_mobile/core/mock_data.dart';
import 'package:dev_mobile/presentation/home/asistencia_detail_screen.dart';
import 'package:dev_mobile/presentation/home/projects_screen.dart';
import 'package:dev_mobile/presentation/home/workers_screen.dart';
import 'package:dev_mobile/presentation/home/attendance_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  bool _isCapturingLocation = false;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    await loadAsistencias();
    if (!mounted) return;
    setState(() {
      _loadingData = false;
    });
  }

  Future<Position> _getCurrentPosition() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      throw Exception(
        'Activa la ubicación del dispositivo para registrar la asistencia.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación bloqueado permanentemente.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  void _applyQrCode(int index, String rawValue, StateSetter setModalState) {
    final employee = mockAsistencias[index];
    final normalized = rawValue.trim();
    final lower = normalized.toLowerCase();

    String? project;
    String? employeeName;

    if (lower.startsWith('project:')) {
      project = normalized.substring(8).trim();
    } else if (lower.startsWith('proyecto:')) {
      project = normalized.substring(9).trim();
    } else if (lower.startsWith('employee:')) {
      employeeName = normalized.substring(9).trim();
    } else if (lower.startsWith('empleado:')) {
      employeeName = normalized.substring(9).trim();
    } else if (mockProjects.contains(normalized)) {
      project = normalized;
    } else {
      final existingEmployee = mockAsistencias.firstWhere(
        (item) => item.name.toLowerCase() == lower,
        orElse: () => employee,
      );
      if (existingEmployee.name.toLowerCase() == lower) {
        employeeName = existingEmployee.name;
      } else {
        project = normalized;
      }
    }

    setModalState(() {
      if (project != null && project.isNotEmpty) {
        employee.project = project;
      }
      if (employeeName != null && employeeName.isNotEmpty) {
        employee.name = employeeName;
      }
    });
  }

  Future<void> _openQrScanner(int index, StateSetter setModalState) async {
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
              _applyQrCode(index, rawValue, setModalState);
            },
          ),
        );
      },
    );
  }

  Future<void> _openAttendanceForm(int index) async {
    final employee = mockAsistencias[index];
    String selectedProject = employee.project.isNotEmpty
        ? employee.project
        : mockProjects.first;

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
                          'Registrar asistencia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Escanear QR',
                        onPressed: () => _openQrScanner(index, setModalState),
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(employee.name, style: const TextStyle(fontSize: 15)),
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
                    'La ubicación se capturará en tiempo real al marcar.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isCapturingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _isCapturingLocation
                            ? 'Capturando ubicación...'
                            : 'Marcar asistencia',
                      ),
                      onPressed: _isCapturingLocation
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                setState(() {
                                  _isCapturingLocation = true;
                                });
                                final position = await _getCurrentPosition();
                                final now = DateTime.now();
                                final coordinates =
                                    '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

                                setState(() {
                                  employee.present = true;
                                  employee.project = selectedProject;
                                  employee.checkInTime = now;
                                  employee.latitude = position.latitude;
                                  employee.longitude = position.longitude;
                                  employee.locationLabel = 'GPS $coordinates';
                                });
                                await saveAsistencias();

                                navigator.pop();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Asistencia registrada en $selectedProject',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isCapturingLocation = false;
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

  Widget _buildAttendanceCard(int index) {
    final employee = mockAsistencias[index];
    final isPresent = employee.present;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AsistenciaDetailScreen(
                asistencia: employee,
                onChanged: () async {
                  setState(() {});
                  await saveAsistencias();
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isPresent
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    child: Icon(
                      isPresent ? Icons.check : Icons.person,
                      color: isPresent ? Colors.green : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPresent
                              ? 'Marcado para ${employee.project}'
                              : 'Pendiente de marcaje',
                          style: TextStyle(
                            color: isPresent
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      isPresent ? 'Presente' : 'Pendiente',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: isPresent
                        ? Colors.green.withAlpha((0.2 * 255).round())
                        : Colors.grey.withAlpha((0.2 * 255).round()),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isPresent) ...[
                _buildInfoRow(Icons.work_outline, 'Proyecto', employee.project),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Hora',
                  employee.checkInTime == null
                      ? '-'
                      : '${employee.checkInTime!.hour.toString().padLeft(2, '0')}:${employee.checkInTime!.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Ubicación',
                  employee.locationLabel ?? 'GPS capturado',
                ),
              ] else ...[
                const Text(
                  'Toca la tarjeta para registrar asistencia con proyecto y ubicación.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(
                    isPresent ? 'Actualizar marcaje' : 'Marcar asistencia',
                  ),
                  onPressed: () => _openAttendanceForm(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de asistencia')),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.list),
                      label: const Text('Proyectos'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProjectsScreen(),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.group),
                      label: const Text('Trabajadores'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WorkersScreen(),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('Historial'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AttendanceHistoryScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registro en sitio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Marca tu asistencia, selecciona el proyecto y se guardará la hora con la ubicación GPS del dispositivo. También puedes usar QR para identificar el proyecto o el empleado más rápido.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(mockAsistencias.length, _buildAttendanceCard),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            mockAsistencias.add(
              AsistenciaItem(DateTime.now(), 'Nuevo participante'),
            );
          });
          saveAsistencias();
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
