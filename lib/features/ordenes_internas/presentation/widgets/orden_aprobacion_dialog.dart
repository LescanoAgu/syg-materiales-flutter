import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../acopios/presentation/providers/acopio_provider.dart';
import '../../../acopios/data/models/proveedor_model.dart';

class OrdenAprobacionDialog extends StatefulWidget {
  const OrdenAprobacionDialog({super.key});

  @override
  State<OrdenAprobacionDialog> createState() => _OrdenAprobacionDialogState();
}

class _OrdenAprobacionDialogState extends State<OrdenAprobacionDialog> {
  String _fuente = 'stock'; // 'stock' o 'proveedor'
  String? _proveedorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aprobar Orden'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seleccione la fuente de abastecimiento:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            RadioListTile<String>(
              title: const Text('Stock Propio (Pañol)'),
              subtitle: const Text('Se descontará del inventario al despachar'),
              value: 'stock',
              groupValue: _fuente,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _fuente = val!),
            ),

            RadioListTile<String>(
              title: const Text('Compra Directa (Proveedor)'),
              subtitle: const Text('El material va directo a obra (No descuenta stock)'),
              value: 'proveedor',
              groupValue: _fuente,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _fuente = val!),
            ),

            if (_fuente == 'proveedor')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<AcopioProvider>(
                  builder: (context, provider, _) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Proveedor',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
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
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('CONFIRMAR APROBACIÓN'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
          onPressed: () {
            if (_fuente == 'proveedor' && _proveedorId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona un proveedor")));
              return;
            }
            Navigator.pop(context, {'fuente': _fuente, 'proveedorId': _proveedorId});
          },
        ),
      ],
    );
  }
}