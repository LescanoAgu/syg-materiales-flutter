import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/producto_search_delegate.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/models/producto_model.dart';
import '../providers/movimiento_stock_provider.dart';

class MovimientoRegistroPage extends StatefulWidget {
  final ProductoModel? productoInicial;
  const MovimientoRegistroPage({super.key, this.productoInicial});

  @override
  State<MovimientoRegistroPage> createState() => _MovimientoRegistroPageState();
}

class _MovimientoRegistroPageState extends State<MovimientoRegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();

  ProductoModel? _productoSeleccionado;
  TipoMovimiento _tipo = TipoMovimiento.entrada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _productoSeleccionado = widget.productoInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSelectorProducto(),
              const SizedBox(height: 16),
              DropdownButtonFormField<TipoMovimiento>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: TipoMovimiento.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('REGISTRAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorProducto() {
    if (widget.productoInicial != null) {
      return ListTile(
        title: Text(
          widget.productoInicial!.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(widget.productoInicial!.codigo),
        tileColor: Colors.grey[200],
      );
    }

    return InkWell(
      onTap: () async {
        final p = await showSearch(
          context: context,
          delegate: ProductoSearchDelegate(),
        );
        if (p != null) setState(() => _productoSeleccionado = p);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _productoSeleccionado?.nombre ?? 'Buscar Producto...',
                style: TextStyle(
                  fontSize: 16,
                  color: _productoSeleccionado == null
                      ? Colors.grey
                      : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_productoSeleccionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un producto')));
      return;
    }

    setState(() => _guardando = true);

    final exito = await context
        .read<MovimientoStockProvider>()
        .registrarMovimiento(
          productoId: _productoSeleccionado!.codigo,
          productoNombre: _productoSeleccionado!.nombre,
          tipo: _tipo,
          cantidad: double.tryParse(_cantidadCtrl.text) ?? 0,
          motivo: _motivoCtrl.text,
        );

    if (mounted) {
      setState(() => _guardando = false);
      if (exito) Navigator.pop(context);
    }
  }
}
