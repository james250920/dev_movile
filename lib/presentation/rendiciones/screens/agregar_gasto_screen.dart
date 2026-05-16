import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_mobile/presentation/rendiciones/providers.dart';
import 'package:dev_mobile/domain/models/comprobante.dart';
import 'package:dev_mobile/domain/models/rendicion.dart';

class AgregarGastoScreen extends ConsumerStatefulWidget {
  final String rendicionId;
  final bool esComprobante;

  const AgregarGastoScreen({
    Key? key,
    required this.rendicionId,
    this.esComprobante = false,
  }) : super(key: key);

  @override
  ConsumerState<AgregarGastoScreen> createState() => _AgregarGastoScreenState();
}

class _AgregarGastoScreenState extends ConsumerState<AgregarGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fechaController;
  late TextEditingController _proveedorController;
  late TextEditingController _conceptoController;
  late TextEditingController _descripcionController;
  late TextEditingController _montoController;
  late TextEditingController _numeroController;

  TipoComprobante _tipoComprobante = TipoComprobante.factura;
  TipoPago _metodoPago = TipoPago.efectivo;
  String _metodoPagoManual = 'efectivo';

  @override
  void initState() {
    super.initState();
    _fechaController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );
    _proveedorController = TextEditingController();
    _conceptoController = TextEditingController();
    _descripcionController = TextEditingController();
    _montoController = TextEditingController();
    _numeroController = TextEditingController();
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _proveedorController.dispose();
    _conceptoController.dispose();
    _descripcionController.dispose();
    _montoController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agregarState = widget.esComprobante
        ? ref.watch(agregarComprobanteProvider)
        : ref.watch(agregarGastoManualProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.esComprobante ? 'Agregar Comprobante' : 'Agregar Gasto',
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.esComprobante) ...[
                  // Tipo de Comprobante
                  DropdownButtonFormField<TipoComprobante>(
                    value: _tipoComprobante,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Comprobante *',
                      border: OutlineInputBorder(),
                    ),
                    items: TipoComprobante.values.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _tipoComprobante = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Número de Comprobante
                  TextFormField(
                    controller: _numeroController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Comprobante *',
                      hintText: 'Ej: F001-123456',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Número requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Proveedor
                  TextFormField(
                    controller: _proveedorController,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor/Comercio *',
                      hintText: 'Nombre del establecimiento',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Proveedor requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Concepto (para gasto manual)
                  TextFormField(
                    controller: _conceptoController,
                    decoration: const InputDecoration(
                      labelText: 'Concepto *',
                      hintText: 'Ej: Pasajes, Comidas, etc.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Concepto requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Fecha
                TextFormField(
                  controller: _fechaController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _seleccionarFecha(context),
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Detalle del gasto',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Monto
                TextFormField(
                  controller: _montoController,
                  decoration: const InputDecoration(
                    labelText: 'Monto *',
                    hintText: '0.00',
                    border: OutlineInputBorder(),
                    prefixText: 'S/. ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Monto requerido';
                    }
                    if (double.tryParse(value!) == null) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Método de Pago
                if (widget.esComprobante)
                  DropdownButtonFormField<TipoPago>(
                    value: _metodoPago,
                    decoration: const InputDecoration(
                      labelText: 'Método de Pago *',
                      border: OutlineInputBorder(),
                    ),
                    items: TipoPago.values.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(
                          tipo.name.replaceAll('_', ' ').toUpperCase(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _metodoPago = value);
                      }
                    },
                  )
                else
                  TextFormField(
                    controller: TextEditingController(text: _metodoPagoManual),
                    decoration: const InputDecoration(
                      labelText: 'Método de Pago *',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Selecciona método de pago'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('Efectivo'),
                                onTap: () {
                                  setState(
                                    () => _metodoPagoManual = 'efectivo',
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text('Transferencia'),
                                onTap: () {
                                  setState(
                                    () => _metodoPagoManual = 'transferencia',
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text('Tarjeta'),
                                onTap: () {
                                  setState(() => _metodoPagoManual = 'tarjeta');
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                        onPressed: agregarState.isLoading
                            ? null
                            : () => _guardar(ref),
                        child: agregarState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar'),
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

  Future<void> _seleccionarFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaController.text = picked.toString().split(' ')[0];
      });
    }
  }

  void _guardar(WidgetRef ref) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        if (widget.esComprobante) {
          final notifier = ref.read(agregarComprobanteProvider.notifier);
          await notifier.agregar(
            rendicionId: widget.rendicionId,
            tipo: _tipoComprobante,
            numero: _numeroController.text,
            fecha: DateTime.parse(_fechaController.text),
            proveedor: _proveedorController.text,
            descripcion: _descripcionController.text,
            monto: double.parse(_montoController.text),
            metodoPago: _metodoPago,
          );
        } else {
          final notifier = ref.read(agregarGastoManualProvider.notifier);
          await notifier.agregar(
            rendicionId: widget.rendicionId,
            fecha: DateTime.parse(_fechaController.text),
            concepto: _conceptoController.text,
            descripcion: _descripcionController.text,
            monto: double.parse(_montoController.text),
            metodoPago: _metodoPagoManual,
          );
        }

        // Refrescar datos
        ref.invalidate(comprobantesRendicionProvider(widget.rendicionId));
        ref.invalidate(gastosManualesRendicionProvider(widget.rendicionId));
        ref.invalidate(resumenRendicionProvider(widget.rendicionId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.esComprobante
                    ? 'Comprobante agregado'
                    : 'Gasto registrado',
              ),
            ),
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
