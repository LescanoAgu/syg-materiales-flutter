import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/producto_model.dart';
import '../../data/repositories/stock_repository.dart';
import '../providers/producto_provider.dart';

class ProductoFormPage extends StatefulWidget {
  final ProductoModel? producto;
  const ProductoFormPage({super.key, this.producto});

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _unidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockInicialCtrl = TextEditingController();

  String? _categoriaIdSeleccionada;
  final StockRepository _stockRepo = StockRepository();

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _codigoCtrl.text = p?.codigo ?? '';
    _nombreCtrl.text = p?.nombre ?? '';
    _unidadCtrl.text = p?.unidadBase ?? 'u';
    _precioCtrl.text = p?.precioSinIva?.toString() ?? '';
    _categoriaIdSeleccionada = p?.categoriaId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarCategorias();
    });
  }

  void _onCategoriaChanged(String? val) async {
    if (val == null) return;
    setState(() => _categoriaIdSeleccionada = val);

    // Solo autogenerar si es nuevo
    if (widget.producto == null) {
      final nuevoCod = await context
          .read<ProductoProvider>()
          .generarCodigoParaCategoria(val);
      if (!mounted) return;
      setState(() => _codigoCtrl.text = nuevoCod);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.producto != null;

    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar' : 'Nuevo Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Consumer<ProductoProvider>(
                builder: (ctx, prov, _) => DropdownButtonFormField<String>(
                  value: _categoriaIdSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: prov.categorias
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.codigo,
                          child: Text(c.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: esEdicion ? null : _onCategoriaChanged,
                  validator: (v) => v == null ? 'Requerido' : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black12,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unidadCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              if (!esEdicion) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stockInicialCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Stock Inicial',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardar,
                  child: const Text('GUARDAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final prod = ProductoModel(
      id: widget.producto?.id ?? _codigoCtrl.text,
      codigo: _codigoCtrl.text,
      categoriaId: _categoriaIdSeleccionada!,
      nombre: _nombreCtrl.text,
      unidadBase: _unidadCtrl.text,
      precioSinIva: double.tryParse(_precioCtrl.text),
      cantidadDisponible: widget.producto?.cantidadDisponible ?? 0,
    );

    try {
      // Usamos importarProductos como "upsert" (crear o actualizar)
      await context.read<ProductoProvider>().importarProductos([prod]);

      if (!mounted) return;

      if (widget.producto == null && _stockInicialCtrl.text.isNotEmpty) {
        final cant = double.tryParse(_stockInicialCtrl.text) ?? 0;
        if (cant > 0)
          await _stockRepo.establecer(productoId: prod.codigo, cantidad: cant);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
