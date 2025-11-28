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
    for (var i in widget.ordenDetalle.items) {
      if (!i.estaCompleto) {
        _cantidadesADespachar[i.item.id!] = 0.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsPendientes = widget.ordenDetalle.items.where((i) => !i.estaCompleto).toList();

    return AlertDialog(
      title: const Text('🚚 Nuevo Despacho'),
      content: SizedBox(
        width: double.maxFinite,
        child: itemsPendientes.isEmpty
            ? const Text("¡Esta orden ya está completa!")
            : ListView.separated(
          shrinkWrap: true,
          itemCount: itemsPendientes.length,
          separatorBuilder: (_,__) => const Divider(),
          itemBuilder: (ctx, i) {
            final detalle = itemsPendientes[i];
            final pendiente = detalle.cantidadFinal - detalle.item.cantidadEntregada;
            final controller = TextEditingController(text: _cantidadesADespachar[detalle.item.id]?.toStringAsFixed(0));

            controller.addListener(() {
              final val = double.tryParse(controller.text) ?? 0.0;
              _cantidadesADespachar[detalle.item.id!] = val;
            });

            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detalle.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Pendiente: ${pendiente.toStringAsFixed(1)} ${detalle.unidadBase}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Llevo',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.all_inclusive, color: Colors.blue),
                  tooltip: 'Llevar todo',
                  onPressed: () {
                    // Hack simple para actualizar UI (no óptimo pero funcional)
                    controller.text = pendiente.toString();
                    setState(() {
                      _cantidadesADespachar[detalle.item.id!] = pendiente;
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
        final itemOriginal = widget.ordenDetalle.items.firstWhere((element) => element.item.id == itemId);
        itemsAEnviar.add({
          'itemId': itemId,
          'productoId': itemOriginal.item.productoId,
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