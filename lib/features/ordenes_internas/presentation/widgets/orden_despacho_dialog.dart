import 'package:flutter/material.dart';
import '../../data/models/orden_interna_model.dart';
import '../../../../core/constants/app_colors.dart';

class OrdenDespachoDialog extends StatefulWidget {
  final OrdenInternaDetalle ordenDetalle;

  const OrdenDespachoDialog({super.key, required this.ordenDetalle});

  @override
  State<OrdenDespachoDialog> createState() => _OrdenDespachoDialogState();
}

class _OrdenDespachoDialogState extends State<OrdenDespachoDialog> {
  final Map<String, double> _cantidadesADespachar = {};

  @override
  void initState() {
    super.initState();
    // Inicializamos con 0
    for (var i in widget.ordenDetalle.items) {
      if (!i.estaCompleto) {
        _cantidadesADespachar[i.item.id] = 0.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtramos solo los items que NO están completos
    final itemsPendientes = widget.ordenDetalle.items.where((i) => !i.estaCompleto).toList();

    return AlertDialog(
      title: const Text('🚚 Nuevo Despacho'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Altura fija para evitar errores de layout
        child: itemsPendientes.isEmpty
            ? const Center(child: Text("¡Esta orden ya está completa!"))
            : ListView.separated(
          shrinkWrap: true,
          itemCount: itemsPendientes.length,
          separatorBuilder: (_,__) => const Divider(),
          itemBuilder: (ctx, i) {
            final detalle = itemsPendientes[i];
            final pendiente = detalle.cantidadFinal - detalle.item.cantidadEntregada;

            // Controlador desechable para cada fila (simple approach)
            final controller = TextEditingController(
                text: _cantidadesADespachar[detalle.item.id] == 0
                    ? ''
                    : _cantidadesADespachar[detalle.item.id]?.toStringAsFixed(0)
            );

            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detalle.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Pendiente: ${pendiente.toStringAsFixed(1)} ${detalle.unidadBase}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      // Mostrar origen para referencia
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text(
                          detalle.item.origen.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Llevo',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                    onChanged: (val) {
                      final v = double.tryParse(val) ?? 0.0;
                      _cantidadesADespachar[detalle.item.id] = v;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.all_inclusive, color: AppColors.primary),
                  tooltip: 'Llevar todo',
                  onPressed: () {
                    setState(() {
                      _cantidadesADespachar[detalle.item.id] = pendiente;
                    });
                  },
                )
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton.icon(
          icon: const Icon(Icons.local_shipping),
          label: const Text('CONFIRMAR SALIDA'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: _procesarDespacho,
        ),
      ],
    );
  }

  void _procesarDespacho() {
    final itemsAEnviar = <Map<String, dynamic>>[];

    _cantidadesADespachar.forEach((itemId, cantidad) {
      if (cantidad > 0) {
        // Buscamos el item original para tener referencia segura
        // Como _cantidadesADespachar usa IDs, es seguro.
        itemsAEnviar.add({
          'itemId': itemId,
          'cantidad': cantidad,
        });
      }
    });

    if (itemsAEnviar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa al menos una cantidad")));
      return;
    }

    Navigator.pop(context, itemsAEnviar);
  }
}