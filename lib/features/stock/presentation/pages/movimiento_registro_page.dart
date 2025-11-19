import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import '../providers/movimiento_stock_provider.dart';

class MovimientoRegistroPage extends StatefulWidget {
  final ProductoConStock? productoInicial;
  const MovimientoRegistroPage({super.key, this.productoInicial});

  @override
  State<MovimientoRegistroPage> createState() => _MovimientoRegistroPageState();
}

class _MovimientoRegistroPageState extends State<MovimientoRegistroPage> {
  final _cantidadCtrl = TextEditingController();
  ProductoConStock? _productoSeleccionado;
  TipoMovimiento _tipo = TipoMovimiento.entrada;

  @override
  void initState() {
    super.initState();
    _productoSeleccionado = widget.productoInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_productoSeleccionado != null)
              Text('Producto: ${_productoSeleccionado!.nombre}'),
            DropdownButton<TipoMovimiento>(
              value: _tipo,
              items: TipoMovimiento.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            TextField(controller: _cantidadCtrl, decoration: const InputDecoration(labelText: 'Cantidad'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _guardar, child: const Text('Registrar')),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_productoSeleccionado == null) return;
    final cant = double.tryParse(_cantidadCtrl.text) ?? 0;

    await context.read<MovimientoStockProvider>().registrarMovimiento(
      productoId: _productoSeleccionado!.productoId, // String
      tipo: _tipo,
      cantidad: cant,
      motivo: 'Manual',
    );

    if(mounted) Navigator.pop(context);
  }
}