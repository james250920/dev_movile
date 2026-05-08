import 'package:dev_mobile/core/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AsistenciaDetailScreen extends StatelessWidget {
  final AsistenciaItem asistencia;
  final Future<void> Function() onChanged;

  const AsistenciaDetailScreen({
    super.key,
    required this.asistencia,
    required this.onChanged,
  });

  Color _statusColor(bool present) {
    return present ? Colors.green.shade600 : Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        asistencia.latitude != null && asistencia.longitude != null;
    final point = hasLocation
        ? LatLng(asistencia.latitude!, asistencia.longitude!)
        : const LatLng(-12.0464, -77.0428);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de asistencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _statusColor(
                            asistencia.present,
                          ).withAlpha((0.2 * 255).round()),
                          child: Icon(
                            asistencia.present ? Icons.check : Icons.person,
                            color: _statusColor(asistencia.present),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                asistencia.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                asistencia.present ? 'Presente' : 'Pendiente',
                                style: TextStyle(
                                  color: _statusColor(asistencia.present),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _infoRow(
                      'Proyecto',
                      asistencia.project.isEmpty ? '-' : asistencia.project,
                    ),
                    _infoRow(
                      'Hora',
                      asistencia.checkInTime == null
                          ? '-'
                          : '${asistencia.checkInTime!.hour.toString().padLeft(2, '0')}:${asistencia.checkInTime!.minute.toString().padLeft(2, '0')}',
                    ),
                    _infoRow(
                      'Fecha',
                      '${asistencia.date.day}/${asistencia.date.month}/${asistencia.date.year}',
                    ),
                    _infoRow('Ubicación', asistencia.locationLabel ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ubicación en mapa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasLocation
                    ? FlutterMap(
                        options: MapOptions(
                          initialCenter: point,
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'dev_mobile',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: point,
                                width: 50,
                                height: 50,
                                child: Icon(
                                  Icons.location_pin,
                                  color: Colors.red.shade600,
                                  size: 44,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Text('No hay ubicación registrada'),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar vista'),
                onPressed: () async {
                  await onChanged();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Detalle actualizado')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
