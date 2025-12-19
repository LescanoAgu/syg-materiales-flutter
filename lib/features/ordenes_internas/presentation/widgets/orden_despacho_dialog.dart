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
    for (var item in widget.ordenDetalle.items) {
      if (!item.estaCompleto) {
        // Usamos productoCodigo o materialId como clave
        _cantidadesADespachar[item.productoCodigo ?? item.materialId] = 0.0;
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
        height: 400,
        child: itemsPendientes.isEmpty
            ? const Center(child: Text("Todo entregado"))
            : ListView.separated(
          itemCount: itemsPendientes.length,
          separatorBuilder: (_,__) => const Divider(),
          itemBuilder: (ctx, i) {
            final detalle = itemsPendientes[i];
            final pendiente = detalle.cantidad - detalle.cantidadEntregada;
            final key = detalle.productoCodigo ?? detalle.materialId;

            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detalle.nombreMaterial, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Pendiente: $pendiente ${detalle.unidadBase}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: '0',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      double valor = double.tryParse(val) ?? 0;
                      if (valor > pendiente) valor = pendiente.toDouble();
                      _cantidadesADespachar[key] = valor;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.all_inclusive, color: AppColors.primary),
                  tooltip: 'Llevar todo',
                  onPressed: () {
                    // ✅ CORRECCIÓN: Agregado .toDouble() para evitar error de tipo
                    _cantidadesADespachar[key] = pendiente.toDouble();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se seleccionó el total pendiente"), duration: Duration(milliseconds: 500)));
                    // Forzamos reconstrucción para que (idealmente) se viera reflejado,
                    // aunque para input manual necesitaríamos controladores.
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
          label: const Text('IR A FIRMAR', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _irAFirmar,
        ),
      ],
    );
  }

  void _irAFirmar() {
    final itemsAEnviar = <Map<String, dynamic>>[];

    _cantidadesADespachar.forEach((prodId, cantidad) {
      if (cantidad > 0) {
        final item = widget.ordenDetalle.items.firstWhere(
                (i) => (i.productoCodigo == prodId) || (i.materialId == prodId),
            orElse: () => widget.ordenDetalle.items.first
        );

        itemsAEnviar.add({
          'productoId': prodId,
          'cantidad': cantidad,
          'productoNombre': item.nombreMaterial
        });
      }
    });

    if (itemsAEnviar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona al menos un item para despachar")));
      return;
    }

    Navigator.pop(context, itemsAEnviar);
  }
}