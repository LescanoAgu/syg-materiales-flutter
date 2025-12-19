import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/producto_model.dart';
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

  String? _categoriaIdSeleccionada;
  bool _generandoCodigo = false;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    if (p != null) {
      _codigoCtrl.text = p.codigo;
      _nombreCtrl.text = p.nombre;
      _unidadCtrl.text = p.unidadBase;
      _precioCtrl.text = p.precioSinIva?.toString() ?? '';
      _categoriaIdSeleccionada = p.categoriaId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarCategorias();
    });
  }

  void _onCategoriaChanged(String? nuevaCat) async {
    setState(() => _categoriaIdSeleccionada = nuevaCat);

    if (widget.producto == null && _codigoCtrl.text.isEmpty && nuevaCat != null) {
      setState(() => _generandoCodigo = true);
      final nuevoCodigo = await context.read<ProductoProvider>().generarCodigoParaCategoria(nuevaCat);
      if (mounted) {
        setState(() {
          _codigoCtrl.text = nuevoCodigo;
          _generandoCodigo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto == null ? 'Nuevo Producto' : 'Editar Producto'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Consumer<ProductoProvider>(
                builder: (ctx, prov, _) => DropdownButtonFormField<String>(
                  value: _categoriaIdSeleccionada,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: prov.categorias.map((c) => DropdownMenuItem(value: c.codigo, child: Text(c.nombre))).toList(),
                  onChanged: widget.producto == null ? _onCategoriaChanged : null,
                  validator: (v) => v == null ? 'Requerido' : null,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _codigoCtrl,
                decoration: InputDecoration(
                  labelText: 'Código',
                  border: const OutlineInputBorder(),
                  suffixIcon: _generandoCodigo ? const CircularProgressIndicator() : null,
                ),
                readOnly: widget.producto != null,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _unidadCtrl,
                decoration: const InputDecoration(labelText: 'Unidad (u, kg, m, lts)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _precioCtrl,
                decoration: const InputDecoration(labelText: 'Precio de Referencia (Sin IVA)', prefixText: '\$ ', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('GUARDAR PRODUCTO', style: TextStyle(fontWeight: FontWeight.bold)),
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
      id: widget.producto?.id,
      codigo: _codigoCtrl.text,
      categoriaId: _categoriaIdSeleccionada!,
      nombre: _nombreCtrl.text,
      unidadBase: _unidadCtrl.text,
      precioSinIva: double.tryParse(_precioCtrl.text),
      cantidadDisponible: widget.producto?.cantidadDisponible ?? 0,
    );

    // Usamos el método simple de importar para crear/actualizar
    final exito = await context.read<ProductoProvider>().importarProductos([prod]);

    if (exito && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Producto guardado"), backgroundColor: Colors.green));
    }
  }
}