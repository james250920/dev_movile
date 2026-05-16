import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dev_mobile/presentation/rendiciones/providers.dart';
import 'package:dev_mobile/presentation/rendiciones/widgets/rendicion_widgets.dart';
import 'package:dev_mobile/presentation/rendiciones/screens/agregar_gasto_screen.dart';
import 'package:dev_mobile/domain/models/rendicion.dart';

class DetalleRendicionScreen extends ConsumerStatefulWidget {
  final String rendicionId;

  const DetalleRendicionScreen({Key? key, required this.rendicionId})
    : super(key: key);

  @override
  ConsumerState<DetalleRendicionScreen> createState() =>
      _DetalleRendicionScreenState();
}

class _DetalleRendicionScreenState extends ConsumerState<DetalleRendicionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rendicionAsync = ref.watch(
      rendicionDetalleProvider(widget.rendicionId),
    );
    final resumenAsync = ref.watch(
      resumenRendicionProvider(widget.rendicionId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Rendición'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gastos'),
            Tab(text: 'Resumen'),
          ],
        ),
      ),
      body: rendicionAsync.when(
        data: (rendicion) {
          if (rendicion == null) {
            return const Center(child: Text('Rendición no encontrada'));
          }

          return Column(
            children: [
              // Header con información básica
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rendicion.titulo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rendicion.descripcion,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        EstadoBadge(estado: rendicion.estado),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (rendicion.proyectoId != null ||
                        rendicion.centroCosto != null) ...[
                      Row(
                        children: [
                          if (rendicion.proyectoId != null) ...[
                            const Icon(Icons.assignment, size: 16),
                            const SizedBox(width: 4),
                            Text(rendicion.proyectoId ?? ''),
                            const SizedBox(width: 16),
                          ],
                          if (rendicion.centroCosto != null) ...[
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Text(rendicion.centroCosto ?? ''),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (rendicion.esViatico)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Viático',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              // Tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab Gastos
                    _BuilderGastos(
                      rendicionId: widget.rendicionId,
                      rendicion: rendicion,
                    ),
                    // Tab Resumen
                    _BuilderResumen(
                      rendicionId: widget.rendicionId,
                      resumenAsync: resumenAsync,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _BuilderGastos extends ConsumerWidget {
  final String rendicionId;
  final Rendicion rendicion;

  const _BuilderGastos({required this.rendicionId, required this.rendicion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comprobantesAsync = ref.watch(
      comprobantesRendicionProvider(rendicionId),
    );
    final gastosAsync = ref.watch(gastosManualesRendicionProvider(rendicionId));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Comprobantes'),
              Tab(text: 'Gastos Manuales'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Comprobantes
                comprobantesAsync.when(
                  data: (comprobantes) {
                    if (comprobantes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.receipt,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text('Sin comprobantes'),
                            const SizedBox(height: 8),
                            _buildBotonAgregar(context, true),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: comprobantes.length,
                      itemBuilder: (context, index) {
                        final comprobante = comprobantes[index];
                        final formato = DateFormat('dd/MM/yyyy');

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.receipt),
                            title: Text(comprobante.proveedor),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comprobante.descripcion,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${comprobante.tipo.name.toUpperCase()} - ${comprobante.numero}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  formato.format(comprobante.fecha),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            trailing: Text(
                              'S/. ${comprobante.monto.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),

                // Gastos Manuales
                gastosAsync.when(
                  data: (gastos) {
                    if (gastos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.attach_money,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text('Sin gastos manuales'),
                            const SizedBox(height: 8),
                            _buildBotonAgregar(context, false),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: gastos.length,
                      itemBuilder: (context, index) {
                        final gasto = gastos[index];
                        final formato = DateFormat('dd/MM/yyyy');

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.attach_money),
                            title: Text(gasto.concepto),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gasto.descripcion,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (gasto.beneficiario != null)
                                  Text(
                                    'Beneficiario: ${gasto.beneficiario}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                Text(
                                  formato.format(gasto.fecha),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            trailing: Text(
                              'S/. ${gasto.monto.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ],
            ),
          ),
          if (rendicion.estado == RendicionStatus.borrador)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgregarGastoScreen(
                              rendicionId: rendicionId,
                              esComprobante: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Comprobante'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgregarGastoScreen(
                              rendicionId: rendicionId,
                              esComprobante: false,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Gasto'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBotonAgregar(BuildContext context, bool esComprobante) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgregarGastoScreen(
              rendicionId: rendicionId,
              esComprobante: esComprobante,
            ),
          ),
        );
      },
      child: Text(esComprobante ? 'Agregar Comprobante' : 'Agregar Gasto'),
    );
  }
}

class _BuilderResumen extends ConsumerWidget {
  final String rendicionId;
  final AsyncValue<dynamic> resumenAsync;

  const _BuilderResumen({
    required this.rendicionId,
    required this.resumenAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return resumenAsync.when(
      data: (resumen) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ResumenFinanciero(
              montoComprobantes: resumen.montoComprobantes,
              montoGastosManuales: resumen.montoGastosManuales,
              montoTotal: resumen.montoTotal,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen de Gastos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BuilderResumenDetalle(
                      titulo: 'Total de Comprobantes',
                      valor: '${resumen.totalComprobantes}',
                    ),
                    _BuilderResumenDetalle(
                      titulo: 'Total de Gastos Manuales',
                      valor: '${resumen.totalGastosManuales}',
                    ),
                    _BuilderResumenDetalle(
                      titulo: 'Total de Evidencias',
                      valor: '${resumen.totalEvidencias}',
                    ),
                  ],
                ),
              ),
            ),
            if (resumen.detallesPorConcepto.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Por Concepto',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...resumen.detallesPorConcepto.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key),
                              Text(
                                'S/. ${e.value.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _BuilderResumenDetalle extends StatelessWidget {
  final String titulo;
  final String valor;

  const _BuilderResumenDetalle({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
