import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/orden_interna_model.dart';
import '../../../acopios/presentation/providers/acopio_provider.dart';

class DialogoAprobarOrden extends StatefulWidget {
  final OrdenInterna orden;
  final Function(
      List<OrdenItemDetalle> items,
      String observacion,
      String? proveedorId,
      String? proveedorNombre,
      OrigenAbastecimiento origen
      ) onAprobar;

  const DialogoAprobarOrden({
    super.key,
    required this.orden,
    required this.onAprobar
  });

  @override
  State<DialogoAprobarOrden> createState() => _DialogoAprobarOrdenState();
}

class _DialogoAprobarOrdenState extends State<DialogoAprobarOrden> {
  late List<OrdenItemDetalle> _itemsEditables;
  final _observacionCtrl = TextEditingController();

  OrigenAbastecimiento _origenSeleccionado = OrigenAbastecimiento.stock_propio;
  String? _proveedorIdSeleccionado;
  String? _proveedorNombreSeleccionado;

  @override
  void initState() {
    super.initState();
    _itemsEditables = widget.orden.items.map((e) => e.copyWith()).toList();
    _origenSeleccionado = widget.orden.origen;

    // Cargar proveedores para el dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Aprobar Orden"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SELECCIÓN DE ORIGEN
              const Text("Fuente de Abastecimiento:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<OrigenAbastecimiento>(
                value: _origenSeleccionado,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: OrigenAbastecimiento.stock_propio, child: Text("Stock Propio")),
                  DropdownMenuItem(value: OrigenAbastecimiento.compra_proveedor, child: Text("Compra a Proveedor")),
                  DropdownMenuItem(value: OrigenAbastecimiento.acopio_cliente, child: Text("Acopio Cliente")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _origenSeleccionado = val);
                },
              ),
              const SizedBox(height: 12),

              // 2. SELECCIÓN DE PROVEEDOR
              if (_origenSeleccionado != OrigenAbastecimiento.stock_propio) ...[
                const Text("Proveedor Asignado:", style: TextStyle(fontWeight: FontWeight.bold)),
                Consumer<AcopioProvider>(
                    builder: (ctx, acopioProv, _) {
                      if (acopioProv.isLoading) return const LinearProgressIndicator();
                      return DropdownButtonFormField<String>(
                        value: _proveedorIdSeleccionado,
                        hint: const Text("Seleccione..."),
                        isExpanded: true,
                        items: acopioProv.proveedores.map((p) {
                          return DropdownMenuItem(value: p.id, child: Text(p.nombre));
                        }).toList(),
                        onChanged: (val) {
                          final prov = acopioProv.proveedores.firstWhere((p) => p.id == val);
                          setState(() {
                            _proveedorIdSeleccionado = val;
                            _proveedorNombreSeleccionado = prov.nombre;
                          });
                        },
                      );
                    }
                ),
                const SizedBox(height: 12),
              ],

              const Divider(),
              const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
              // Lista simple de items
              ..._itemsEditables.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Row(
                  children: [
                    Expanded(child: Text(item.nombreMaterial, style: const TextStyle(fontSize: 13))),
                    SizedBox(width: 60, child: TextFormField(
                      initialValue: item.cantidad.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                      onChanged: (v) => _itemsEditables[index] = item.copyWith(cantidad: int.tryParse(v) ?? item.cantidad),
                    ))
                  ],
                );
              }),

              const SizedBox(height: 10),
              TextField(controller: _observacionCtrl, decoration: const InputDecoration(labelText: "Observaciones")),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () {
            widget.onAprobar(
                _itemsEditables,
                _observacionCtrl.text,
                _proveedorIdSeleccionado,
                _proveedorNombreSeleccionado,
                _origenSeleccionado
            );
          },
          child: const Text("APROBAR"),
        )
      ],
    );
  }
}