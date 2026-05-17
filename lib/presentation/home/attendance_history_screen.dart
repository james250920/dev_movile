import 'package:flutter/material.dart';
import 'package:dev_mobile/core/mock_data.dart';
import 'package:dev_mobile/presentation/home/asistencia_detail_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime? _selectedDate;
  List<AsistenciaItem> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    try {
      setState(() => _loading = true);
      final list = await getAsistenciasFiltered(
        date: _selectedDate,
      ).timeout(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _results = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAndSearch();
  }

  Future<void> _initializeAndSearch() async {
    try {
      // Load data in parallel, not sequentially
      // Only load asistencias here to speed up this screen
      await loadAsistencias();

      // After loading, perform search with current filters
      if (mounted) {
        await _search();
      }
    } catch (e) {
      // Silently fail - data is already loaded as defaults
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Asistencias')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Text(
                      _selectedDate == null
                          ? 'Seleccionar fecha'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _search, child: const Text('Buscar')),
              ],
            ),
            const SizedBox(height: 12),
            _loading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: _results.isEmpty
                        ? const Center(child: Text('No hay registros'))
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, i) {
                              final a = _results[i];
                              return ListTile(
                                title: Text(a.name),
                                subtitle: Text(
                                  '${a.project} • ${a.locationLabel ?? '-'}',
                                ),
                                trailing: Text(
                                  a.checkInTime == null
                                      ? '-'
                                      : '${a.checkInTime!.hour.toString().padLeft(2, '0')}:${a.checkInTime!.minute.toString().padLeft(2, '0')}',
                                ),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AsistenciaDetailScreen(
                                      asistencia: a,
                                      onChanged: () async {
                                        await _search();
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
