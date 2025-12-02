import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../acopios/presentation/providers/acopio_provider.dart';
import '../../data/models/orden_item_model.dart';

class OrdenAprobacionDialog extends StatefulWidget {
  final List<OrdenItemDetalle> items; // Recibimos los items

  const OrdenAprobacionDialog({super.key, required this.items});

  @override
  State<OrdenAprobacionDialog> createState() => _OrdenAprobacionDialogState();
}

class _OrdenAprobacionDialogState extends State<OrdenAprobacionDialog> {
  String? _proveedorId;
  final Map<String, String> _fuentePorItem = {}; // 'stock' o 'proveedor'

  @override
  void initState() {
    super.initState();
    // Inicializar todo en 'stock'
    for (var item in widget.items) {
      _fuentePorItem[item.item.id!] = 'stock';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si hay al menos un item marcado como 'proveedor'
    bool hayItemsExternos = _fuentePorItem.containsValue('proveedor');

    return AlertDialog(
      title: const Text('Aprobar Orden'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Definir fuente por producto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            // Lista de items con switch
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.items.length,
                separatorBuilder: (_,__) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = widget.items[i];
                  final esStock = _fuentePorItem[item.item.id!] == 'stock';

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productoNombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${item.cantidadFinal} ${item.unidadBase}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          esStock ? "STOCK" : "PROVEEDOR",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: esStock ? AppColors.success : AppColors.secondary
                          ),
                        ),
                        Switch(
                          value: !esStock, // true = proveedor
                          activeColor: AppColors.secondary,
                          inactiveThumbColor: AppColors.success,
                          inactiveTrackColor: AppColors.success.withOpacity(0.3),
                          onChanged: (val) {
                            setState(() {
                              _fuentePorItem[item.item.id!] = val ? 'proveedor' : 'stock';
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Selector de Proveedor (solo si hay items externos)
            if (hayItemsExternos)
              Consumer<AcopioProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Proveedor para items externos',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      prefixIcon: Icon(Icons.store),
                    ),
                    value: _proveedorId,
                    items: provider.proveedores
                        .where((p) => !p.esDepositoSyg)
                        .map((p) => DropdownMenuItem(value: p.codigo, child: Text(p.nombre)))
                        .toList(),
                    onChanged: (val) => setState(() => _proveedorId = val),
                  );
                },
              ),

            if (!hayItemsExternos)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text("Todo saldrá del stock interno.", style: TextStyle(fontSize: 12, color: Colors.green)))
                ]),
              )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('CONFIRMAR'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
          onPressed: () {
            // Validación: Si hay items externos, debe haber proveedor seleccionado
            if (hayItemsExternos && _proveedorId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona un proveedor para los ítems externos")));
              return;
            }
            Navigator.pop(context, {
              'configuracionItems': _fuentePorItem,
              'proveedorId': _proveedorId
            });
          },
        ),
      ],
    );
  }
}