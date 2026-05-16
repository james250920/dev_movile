import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_mobile/presentation/rendiciones/providers.dart';
import 'package:dev_mobile/presentation/rendiciones/widgets/rendicion_widgets.dart';
import 'package:dev_mobile/presentation/rendiciones/screens/crear_rendicion_screen.dart';
import 'package:dev_mobile/presentation/rendiciones/screens/detalle_rendicion_screen.dart';
import 'package:dev_mobile/domain/models/rendicion.dart';

class ListadoRendicionesScreen extends ConsumerStatefulWidget {
  const ListadoRendicionesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ListadoRendicionesScreen> createState() =>
      _ListadoRendicionesScreenState();
}

class _ListadoRendicionesScreenState
    extends ConsumerState<ListadoRendicionesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final filtros = [
    ('Todos', null),
    ('Borrador', RendicionStatus.borrador),
    ('Enviadas', RendicionStatus.enviada),
    ('Observadas', RendicionStatus.observada),
    ('Aprobadas', RendicionStatus.aprobada),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: filtros.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendiciones de Cuentas'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: filtros.map((f) => Tab(text: f.$1)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: filtros.map((filtro) {
          if (filtro.$2 == null) {
            // Mostrar todas las rendiciones
            return _BuilderTodasRendiciones(userId: userId);
          } else {
            // Mostrar por estado
            return _BuilderRendicionesPorEstado(
              userId: userId,
              estado: filtro.$2!,
            );
          }
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearRendicionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BuilderTodasRendiciones extends ConsumerWidget {
  final String userId;

  const _BuilderTodasRendiciones({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rendicionesAsync = ref.watch(rendicionesUsuarioProvider(userId));

    return rendicionesAsync.when(
      data: (rendiciones) {
        if (rendiciones.isEmpty) {
          return EmptyStateWidget(
            titulo: 'Sin Rendiciones',
            mensaje: 'No tienes rendiciones registradas. ¡Crea una nueva!',
            icono: Icons.folder_open,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: rendiciones.length,
          itemBuilder: (context, index) {
            final rendicion = rendiciones[index];
            return RendicionCard(
              rendicion: rendicion,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetalleRendicionScreen(rendicionId: rendicion.id),
                  ),
                );
              },
              onDelete: () {
                _mostrarConfirmacionEliminar(context, ref, rendicion.id);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  void _mostrarConfirmacionEliminar(
    BuildContext context,
    WidgetRef ref,
    String rendicionId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rendición'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta rendición?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(rendicionesServiceProvider).deleteRendicion(rendicionId);
              ref.invalidate(rendicionesUsuarioProvider(userId));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rendición eliminada')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _BuilderRendicionesPorEstado extends ConsumerWidget {
  final String userId;
  final RendicionStatus estado;

  const _BuilderRendicionesPorEstado({
    required this.userId,
    required this.estado,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rendicionesAsync = ref.watch(
      rendicionesPorEstadoProvider((userId: userId, estado: estado)),
    );

    return rendicionesAsync.when(
      data: (rendiciones) {
        if (rendiciones.isEmpty) {
          return EmptyStateWidget(
            titulo: 'Sin Rendiciones',
            mensaje: 'No hay rendiciones en este estado',
            icono: Icons.filter_alt,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: rendiciones.length,
          itemBuilder: (context, index) {
            final rendicion = rendiciones[index];
            return RendicionCard(
              rendicion: rendicion,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetalleRendicionScreen(rendicionId: rendicion.id),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
