import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import '../providers/movimiento_stock_provider.dart';

class MovimientoRegistroPage extends StatefulWidget { // CLASE CORRECTA
  final ProductoConStock? productoInicial;
  const MovimientoRegistroPage({super.key, this.productoInicial});

  @override
  State<MovimientoRegistroPage> createState() => _MovimientoRegistroPageState();
}

class _MovimientoRegistroPageState extends State<MovimientoRegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();

  ProductoConStock? _productoSeleccionado;
  TipoMovimiento _tipo = TipoMovimiento.entrada;

  @override
  void initState() {
    super.initState();
    _productoSeleccionado = widget.productoInicial;

    if (_productoSeleccionado == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductoProvider>().cargarProductos();
      });
    }
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Movimiento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.productoInicial != null)
                _buildProductoInfoCard(widget.productoInicial!)
              else
                _buildSelectorProducto(),

              const SizedBox(height: 24),

              Text('Tipo de Movimiento', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TipoMovimiento>(
                    value: _tipo,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: TipoMovimiento.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(_getIconoMovimiento(t), color: _getColorMovimiento(t), size: 20),
                            const SizedBox(width: 12),
                            Text(_capitalizar(t.name), style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _tipo = v!),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa una cantidad';
                  if (double.tryParse(value) == null) return 'Número inválido';
                  if (double.parse(value) <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo / Referencia (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.save),
                  label: const Text('REGISTRAR MOVIMIENTO', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---
  Widget _buildProductoInfoCard(ProductoConStock p) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.inventory_2, color: AppColors.primary),
        ),
        title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Cód: ${p.codigo} • Stock actual: ${p.cantidadFormateada}'),
      ),
    );
  }

  Widget _buildSelectorProducto() {
    return Consumer<ProductoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const LinearProgressIndicator();

        return DropdownButtonFormField<ProductoConStock>(
          decoration: const InputDecoration(
            labelText: 'Seleccionar Producto',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          isExpanded: true,
          hint: const Text('Busca un material...'),
          value: _productoSeleccionado,
          items: provider.productos.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) => setState(() => _productoSeleccionado = val),
          validator: (val) => val == null ? 'Debes seleccionar un producto' : null,
        );
      },
    );
  }

  // --- Helpers Estéticos ---
  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  IconData _getIconoMovimiento(TipoMovimiento t) {
    switch (t) {
      case TipoMovimiento.entrada: return Icons.arrow_circle_down;
      case TipoMovimiento.salida: return Icons.arrow_circle_up;
      case TipoMovimiento.ajuste: return Icons.tune;
    }
  }

  Color _getColorMovimiento(TipoMovimiento t) {
    switch (t) {
      case TipoMovimiento.entrada: return Colors.green;
      case TipoMovimiento.salida: return Colors.red;
      case TipoMovimiento.ajuste: return Colors.orange;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productoSeleccionado == null) return;

    final cant = double.tryParse(_cantidadCtrl.text) ?? 0;
    final motivo = _motivoCtrl.text.isEmpty ? 'Ajuste manual' : _motivoCtrl.text;

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    final success = await context.read<MovimientoStockProvider>().registrarMovimiento(
      productoId: _productoSeleccionado!.productoId,
      tipo: _tipo,
      cantidad: cant,
      motivo: motivo,
      usuarioId: 'usuario_app',
    );

    if(mounted) {
      Navigator.pop(context); // Cerrar loading
      if (success) {
        Navigator.pop(context); // Cerrar pantalla
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Movimiento registrado'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${context.read<MovimientoStockProvider>().errorMessage}'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}