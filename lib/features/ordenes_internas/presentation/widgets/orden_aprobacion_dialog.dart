import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../acopios/presentation/providers/acopio_provider.dart';
import '../../data/models/orden_item_model.dart';

class OrdenAprobacionDialog extends StatefulWidget {
  final List<OrdenItem> items;

  const OrdenAprobacionDialog({super.key, required this.items});

  @override
  State<OrdenAprobacionDialog> createState() => _OrdenAprobacionDialogState();
}

class _OrdenAprobacionDialogState extends State<OrdenAprobacionDialog> {
  // Mapa para guardar la configuración: { itemId : { 'origen': enum, 'proveedorId': string? } }
  final Map<String, Map<String, dynamic>> _configuracion = {};

  // Variable para el dropdown de asignación masiva
  OrigenProducto? _origenMasivo = OrigenProducto.stockPropio;

  @override
  void initState() {
    super.initState();
    // 1. Inicializar todo por defecto a Stock Propio
    for (var item in widget.items) {
      _configuracion[item.id] = {
        'origen': OrigenProducto.stockPropio,
        'proveedorId': null,
      };
    }

    // 2. Cargar proveedores para el dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  // Función para aplicar el cambio a TODOS los items
  void _aplicarA_Todos(OrigenProducto origen) {
    setState(() {
      _origenMasivo = origen;
      for (var key in _configuracion.keys) {
        _configuracion[key]!['origen'] = origen;
        // Si volvemos a stock, limpiamos el proveedor seleccionado
        if (origen == OrigenProducto.stockPropio) {
          _configuracion[key]!['proveedorId'] = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logística de Orden'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500, // Altura suficiente para la lista
        child: Column(
          children: [
            // --- HEADER: ASIGNACIÓN MASIVA ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("⚡ Asignación Rápida", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<OrigenProducto>(
                          isExpanded: true,
                          isDense: true,
                          value: _origenMasivo,
                          underline: Container(), // Quitar línea fea por defecto
                          items: const [
                            DropdownMenuItem(value: OrigenProducto.stockPropio, child: Text('🏭 Todo de Stock S&G')),
                            DropdownMenuItem(value: OrigenProducto.compraDirecta, child: Text('🚚 Todo Compra Directa')),
                            DropdownMenuItem(value: OrigenProducto.descuentoAcopio, child: Text('📦 Todo de Acopio')),
                          ],
                          onChanged: (v) {
                            if (v != null) _aplicarA_Todos(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(),

            // --- LISTA DE ITEMS ---
            Expanded(
              child: ListView.separated(
                itemCount: widget.items.length,
                separatorBuilder: (_,__) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = widget.items[i];
                  return _buildItemConfig(item);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle),
          label: const Text('APROBAR'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          onPressed: _guardar,
        ),
      ],
    );
  }

  Widget _buildItemConfig(OrdenItem item) {
    final config = _configuracion[item.id]!;
    final origenActual = config['origen'] as OrigenProducto;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del producto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.productoNombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${item.cantidadSolicitada} ${item.unidad}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dropdown Origen Individual
          DropdownButtonFormField<OrigenProducto>(
            value: origenActual,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
              labelText: 'Origen',
            ),
            items: const [
              DropdownMenuItem(value: OrigenProducto.stockPropio, child: Text('Stock S&G')),
              DropdownMenuItem(value: OrigenProducto.compraDirecta, child: Text('Compra Directa')),
              DropdownMenuItem(value: OrigenProducto.descuentoAcopio, child: Text('Acopio')),
            ],
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                config['origen'] = val;
                if (val == OrigenProducto.stockPropio) {
                  config['proveedorId'] = null;
                }
              });
            },
          ),

          // Dropdown Proveedor (Condicional)
          if (origenActual != OrigenProducto.stockPropio) ...[
            const SizedBox(height: 8),
            Consumer<AcopioProvider>(
              builder: (context, provider, _) {
                return DropdownButtonFormField<String>(
                  value: config['proveedorId'],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: const OutlineInputBorder(),
                    labelText: origenActual == OrigenProducto.compraDirecta
                        ? '¿A quién compramos?'
                        : '¿En qué depósito está?',
                    fillColor: Colors.orange.withOpacity(0.1),
                    filled: true,
                  ),
                  items: provider.proveedores
                      .where((p) => !p.esDepositoSyg) // Filtramos depósito propio
                      .map((p) => DropdownMenuItem(
                    value: p.id ?? p.codigo,
                    child: Text(p.nombre),
                  ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      config['proveedorId'] = val;
                    });
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _guardar() {
    // Validación: Si eligió proveedor/compra, debe seleccionar UN proveedor
    for (var item in widget.items) {
      final conf = _configuracion[item.id]!;
      if (conf['origen'] != OrigenProducto.stockPropio && conf['proveedorId'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Falta seleccionar proveedor para: ${item.productoNombre}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    Navigator.pop(context, _configuracion);
  }
}