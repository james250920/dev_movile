import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_mobile/presentation/rendiciones/providers.dart';

class CrearRendicionScreen extends ConsumerStatefulWidget {
  const CrearRendicionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CrearRendicionScreen> createState() =>
      _CrearRendicionScreenState();
}

class _CrearRendicionScreenState extends ConsumerState<CrearRendicionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _proyectoIdController;
  late TextEditingController _centroCostoController;
  bool _esViatico = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController();
    _descripcionController = TextEditingController();
    _proyectoIdController = TextEditingController();
    _centroCostoController = TextEditingController();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _proyectoIdController.dispose();
    _centroCostoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crearState = ref.watch(crearRendicionProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Rendición')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Ej: Rendición Junio 2024',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'El título es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Detalles o motivo de la rendición',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Proyecto
                TextFormField(
                  controller: _proyectoIdController,
                  decoration: const InputDecoration(
                    labelText: 'Proyecto (Opcional)',
                    hintText: 'ID o nombre del proyecto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Centro de Costo
                TextFormField(
                  controller: _centroCostoController,
                  decoration: const InputDecoration(
                    labelText: 'Centro de Costo (Opcional)',
                    hintText: 'Centro de costo asociado',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Es Viático
                CheckboxListTile(
                  value: _esViatico,
                  onChanged: (value) {
                    setState(() {
                      _esViatico = value ?? false;
                    });
                  },
                  title: const Text('Esta es una rendición de viático'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: crearState.isLoading
                            ? null
                            : () => _crearRendicion(ref, userId),
                        child: crearState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Crear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _crearRendicion(WidgetRef ref, String userId) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final notifier = ref.read(crearRendicionProvider.notifier);
        await notifier.crearRendicion(
          userId: userId,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          proyectoId: _proyectoIdController.text.isEmpty
              ? null
              : _proyectoIdController.text,
          centroCosto: _centroCostoController.text.isEmpty
              ? null
              : _centroCostoController.text,
          esViatico: _esViatico,
        );

        // Refrescar lista
        ref.invalidate(rendicionesUsuarioProvider(userId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rendición creada exitosamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
