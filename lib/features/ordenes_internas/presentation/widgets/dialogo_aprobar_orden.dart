import 'package:flutter/material.dart';
// ✅ CORREGIDO: Importamos el modelo unificado
import '../../data/models/orden_interna_model.dart';

class DialogoAprobarOrden extends StatefulWidget {
  final OrdenInterna orden;
  final Function(List<OrdenItemDetalle> items, String observaciones, String? proveedor) onAprobar;

  const DialogoAprobarOrden({
    Key? key,
    required this.orden,
    required this.onAprobar,
  }) : super(key: key);

  @override
  State<DialogoAprobarOrden> createState() => _DialogoAprobarOrdenState();
}

class _DialogoAprobarOrdenState extends State<DialogoAprobarOrden> {
  late List<OrdenItemDetalle> _itemsEditables;
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _proveedorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Creamos una copia de la lista para no mutar el estado original
    _itemsEditables = List.from(widget.orden.items);
    if(widget.orden.proveedorNombre != null) {
      _proveedorController.text = widget.orden.proveedorNombre!;
    }
  }

  void _modificarCantidad(int index, String valor) {
    final nuevaCantidad = int.tryParse(valor);
    if (nuevaCantidad != null && nuevaCantidad >= 0) {
      setState(() {
        _itemsEditables[index] = _itemsEditables[index].copyWith(cantidad: nuevaCantidad);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Revisar y Aprobar Orden'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Puede modificar las cantidades antes de aprobar.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ..._itemsEditables.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.nombreMaterial)),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: item.cantidad.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cant.',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => _modificarCantidad(index, val),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 15),
              TextField(
                controller: _proveedorController,
                decoration: const InputDecoration(
                  labelText: 'Proveedor (Opcional)',
                  hintText: 'Ej: Corralón El Constructor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _observacionesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observaciones de Aprobación',
                  hintText: 'Ej: Se reduce cantidad por falta de stock...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            widget.onAprobar(
              _itemsEditables,
              _observacionesController.text,
              _proveedorController.text.isNotEmpty ? _proveedorController.text : null,
            );
            Navigator.pop(context);
          },
          icon: const Icon(Icons.check),
          label: const Text('Aprobar Orden'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }
}