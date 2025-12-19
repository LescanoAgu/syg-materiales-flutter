import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/producto_search_delegate.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/models/producto_model.dart';
import '../providers/movimiento_stock_provider.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import '../../../obras/data/models/obra_model.dart';

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
  ObraModel? _obraSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _productoSeleccionado = widget.productoInicial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraProvider>().cargarObras();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento'), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Producto", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildProductoSelector(),
              const SizedBox(height: 20),

              const Text("Tipo de Acción", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTipoSelector(),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cantidadCtrl,
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        suffixText: _productoSeleccionado?.unidadBase ?? 'u',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Selector de Obra
                  Expanded(
                    child: _tipo == TipoMovimiento.salida
                        ? Consumer<ObraProvider>(
                      builder: (ctx, obraProv, _) {
                        return DropdownButtonFormField<ObraModel>(
                          value: _obraSeleccionada,
                          decoration: const InputDecoration(labelText: "Destino / Obra", border: OutlineInputBorder()),
                          items: obraProv.obras.map((o) => DropdownMenuItem(value: o, child: Text(o.nombre))).toList(),
                          onChanged: (val) => setState(() => _obraSeleccionada = val),
                          isExpanded: true,
                        );
                      },
                    )
                        : Container(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(labelText: 'Motivo / Referencia', border: OutlineInputBorder()),
                maxLines: 2,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tipo == TipoMovimiento.entrada ? Colors.green : (_tipo == TipoMovimiento.salida ? Colors.red : Colors.blue),
                  ),
                  child: _guardando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("CONFIRMAR MOVIMIENTO", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductoSelector() {
    return InkWell(
      onTap: () async {
        final p = await showSearch(context: context, delegate: ProductoSearchDelegate());
        if (p != null) setState(() => _productoSeleccionado = p);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                style: TextStyle(fontSize: 16, color: _productoSeleccionado == null ? Colors.grey : Colors.black),
              ),
            ),
            if (_productoSeleccionado != null)
              Text("Stock: ${_productoSeleccionado!.cantidadFormateada}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoSelector() {
    return Row(
      children: [
        Expanded(child: _radioTile("Entrada", TipoMovimiento.entrada, Colors.green)),
        Expanded(child: _radioTile("Salida", TipoMovimiento.salida, Colors.red)),
        Expanded(child: _radioTile("Ajuste", TipoMovimiento.ajuste, Colors.blue)),
      ],
    );
  }

  Widget _radioTile(String label, TipoMovimiento val, Color color) {
    return InkWell(
      onTap: () => setState(() => _tipo = val),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          // ✅ Fix deprecated
          color: _tipo == val ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: _tipo == val ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              val == TipoMovimiento.entrada ? Icons.arrow_downward : (val == TipoMovimiento.salida ? Icons.arrow_upward : Icons.tune),
              color: _tipo == val ? color : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
                color: _tipo == val ? color : Colors.grey,
                fontWeight: FontWeight.bold
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un producto')));
      return;
    }

    setState(() => _guardando = true);

    final exito = await context.read<MovimientoStockProvider>().registrarMovimiento(
      productoId: _productoSeleccionado!.codigo,
      productoNombre: _productoSeleccionado!.nombre,
      tipo: _tipo,
      cantidad: double.tryParse(_cantidadCtrl.text) ?? 0,
      motivo: _motivoCtrl.text,
      obraId: _obraSeleccionada?.codigo,
      obraNombre: _obraSeleccionada?.nombre,
    );

    if (mounted) {
      setState(() => _guardando = false);
      if (exito) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Movimiento registrado"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al registrar"), backgroundColor: Colors.red));
      }
    }
  }
}