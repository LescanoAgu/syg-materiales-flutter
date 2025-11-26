import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/producto_model.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/producto_repository.dart';
import '../providers/producto_provider.dart';

class ProductoFormPage extends StatefulWidget {
  final String? productoId; // String
  const ProductoFormPage({super.key, this.productoId});

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _unidadCtrl = TextEditingController();
  final _stockInicialCtrl = TextEditingController();

  final ProductoRepository _prodRepo = ProductoRepository();
  final StockRepository _stockRepo = StockRepository();
  final String _categoriaId = 'OG'; // Default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.productoId == null ? 'Nuevo Producto' : 'Editar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _codigoCtrl, decoration: const InputDecoration(labelText: 'Código')),
              TextFormField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              TextFormField(controller: _unidadCtrl, decoration: const InputDecoration(labelText: 'Unidad')),
              if (widget.productoId == null)
                TextFormField(
                  controller: _stockInicialCtrl,
                  decoration: const InputDecoration(labelText: 'Stock Inicial'),
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final prod = ProductoModel(
      id: widget.productoId ?? _codigoCtrl.text,
      codigo: _codigoCtrl.text,
      categoriaId: _categoriaId,
      nombre: _nombreCtrl.text,
      unidadBase: _unidadCtrl.text,
    );

    try {
      if (widget.productoId == null) {
        await _prodRepo.crear(prod);
        if (_stockInicialCtrl.text.isNotEmpty) {
          await _stockRepo.establecer(
              productoId: prod.codigo,
              cantidad: double.tryParse(_stockInicialCtrl.text) ?? 0
          );
        }
      } else {
        await _prodRepo.actualizar(prod);
      }
      if(mounted) {
        context.read<ProductoProvider>().cargarProductos();
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}