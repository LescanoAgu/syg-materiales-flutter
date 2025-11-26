import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
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
  final _formKey = GlobalKey<FormState>(); // Agregamos validación
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController(); // Agregamos controlador para motivo

  ProductoConStock? _productoSeleccionado;
  TipoMovimiento _tipo = TipoMovimiento.entrada;

  @override
  void initState() {
    super.initState();
    _productoSeleccionado = widget.productoInicial;

    // Si no venimos con un producto, cargamos la lista
    if (widget.productoInicial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductoProvider>().cargarProductos();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 1. Selector de Producto (Solo si no vino preseleccionado)
              if (widget.productoInicial != null)
                _buildProductoInfoCard(widget.productoInicial!)
              else
                _buildProductoDropdown(),

              const SizedBox(height: 20),

              // 2. Selector de Tipo de Movimiento (Mejorado)
              DropdownButtonFormField<TipoMovimiento>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Movimiento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: TipoMovimiento.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(_getIcono(t), color: _getColor(t), size: 20),
                        const SizedBox(width: 10),
                        Text(
                            _getLabel(t),
                            style: TextStyle(color: _getColor(t), fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),

              const SizedBox(height: 20),

              // 3. Cantidad
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
                  if (double.parse(value) <= 0) return 'La cantidad debe ser mayor a 0';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 4. Motivo (Opcional pero recomendado)
              TextFormField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo / Referencia (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),

              const SizedBox(height: 30),

              // Botón de Guardar
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
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

  Widget _buildProductoInfoCard(ProductoConStock p) {
    return Card(
      color: AppColors.backgroundGray,
      child: ListTile(
        leading: const Icon(Icons.inventory_2, color: AppColors.primary),
        title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${p.codigo} • Stock actual: ${p.cantidadFormateada}'),
      ),
    );
  }

  Widget _buildProductoDropdown() {
    return Consumer<ProductoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const LinearProgressIndicator();

        return DropdownButtonFormField<ProductoConStock>(
          value: _productoSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Seleccionar Producto',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          isExpanded: true,
          items: provider.productos.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text('${p.nombre} (${p.cantidadFormateada})', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) => setState(() => _productoSeleccionado = v),
          validator: (v) => v == null ? 'Debes seleccionar un producto' : null,
        );
      },
    );
  }

  // Helpers para estética
  String _getLabel(TipoMovimiento t) {
    switch (t) {
      case TipoMovimiento.entrada: return 'Entrada de Stock';
      case TipoMovimiento.salida: return 'Salida de Stock';
      case TipoMovimiento.ajuste: return 'Ajuste de Inventario';
    }
  }

  Color _getColor(TipoMovimiento t) {
    switch (t) {
      case TipoMovimiento.entrada: return AppColors.success;
      case TipoMovimiento.salida: return AppColors.error;
      case TipoMovimiento.ajuste: return AppColors.warning;
    }
  }

  IconData _getIcono(TipoMovimiento t) {
    switch (t) {
      case TipoMovimiento.entrada: return Icons.arrow_downward;
      case TipoMovimiento.salida: return Icons.arrow_upward;
      case TipoMovimiento.ajuste: return Icons.tune;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productoSeleccionado == null) return;

    final cant = double.tryParse(_cantidadCtrl.text) ?? 0;
    final motivo = _motivoCtrl.text.isEmpty ? 'Manual' : _motivoCtrl.text;

    // Feedback de carga (opcional, usando un dialogo simple o estado)
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    await context.read<MovimientoStockProvider>().registrarMovimiento(
      productoId: _productoSeleccionado!.productoId,
      tipo: _tipo,
      cantidad: cant,
      motivo: motivo,
      usuarioId: 'usuario_actual', // Aquí iría el ID del auth
    );

    if(mounted) {
      Navigator.pop(context); // Cerrar loading
      Navigator.pop(context); // Cerrar pantalla
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Movimiento registrado exitosamente'), backgroundColor: AppColors.success),
      );
    }
  }
}