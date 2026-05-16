import 'package:flutter/material.dart';
import 'package:dev_mobile/core/mock_data.dart';
import 'package:dev_mobile/presentation/home/rendicion_detail_screen.dart';

class RendicionScreen extends StatefulWidget {
  const RendicionScreen({super.key});

  @override
  State<RendicionScreen> createState() => _RendicionScreenState();
}

class _RendicionScreenState extends State<RendicionScreen> {
  @override
  void initState() {
    super.initState();
    loadRendiciones().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rendición de cuentas')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final containers = getRendicionContainers();

            if (containers.isEmpty) {
              return Center(
                child: Text(
                  'No hay rendiciones registradas',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            return ListView.separated(
              itemCount: containers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final container = containers[index];
                Color statusColor;
                switch (container.status) {
                  case 'aprobado':
                    statusColor = Colors.green.shade400;
                    break;
                  case 'enviado':
                    statusColor = Colors.orange.shade400;
                    break;
                  case 'rechazado':
                    statusColor = Colors.red.shade400;
                    break;
                  default:
                    statusColor = Colors.grey.shade400;
                }

                return InkWell(
                  onTap: () async {
                    final result = await Navigator.of(context)
                        .push<RendicionContainer>(
                          MaterialPageRoute(
                            builder: (context) =>
                                RendicionDetailScreen(container: container),
                          ),
                        );
                    if (result != null) {
                      setState(() {
                        // Actualizar estado del contenedor
                        updateRendicionesByCorrelative(
                          result.correlative,
                          result.status,
                        );
                        saveRendiciones();
                      });
                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  container.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        'Correlativo ${container.correlative}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Colors.blue.shade50,
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        '${container.items.length} item(s)',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Colors.purple.shade50,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total: \$${container.totalAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    Text(
                                      '${container.dateCreated.day}/${container.dateCreated.month}/${container.dateCreated.year}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Chip(
                            backgroundColor: statusColor.withAlpha(
                              (0.2 * 255).round(),
                            ),
                            label: Text(
                              _statusLabel(container.status),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _createAndOpenDraft(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'aprobado':
        return 'Aprobado';
      case 'enviado':
        return 'Enviado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return 'Borrador';
    }
  }

  void _createAndOpenDraft(BuildContext context) {
    final correlative = nextRendicionCorrelative();
    final draft = RendicionItem(
      DateTime.now(),
      '',
      0,
      correlative: correlative,
      category: '',
      status: 'borrador',
    );

    setState(() {
      mockRendiciones.add(draft);
    });
    saveRendiciones();

    final container = RendicionContainer(
      correlative: correlative,
      items: [],
      status: 'borrador',
    );

    Navigator.of(context)
        .push<RendicionContainer>(
          MaterialPageRoute(
            builder: (context) => RendicionDetailScreen(container: container),
          ),
        )
        .then((result) {
          if (result != null) {
            setState(() {
              // Actualizar base de datos
              saveRendiciones();
            });
          }
        });
  }
}
