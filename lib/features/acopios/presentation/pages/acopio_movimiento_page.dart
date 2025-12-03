import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
// IMPORT FALTANTE:
import '../../../stock/data/models/producto_model.dart';
import '../providers/acopio_provider.dart';

class AcopioMovimientoPage extends StatefulWidget {
  final AcopioDetalle? acopioInicial;

  const AcopioMovimientoPage({
    super.key,
    this.acopioInicial,
  });

  @override
  State<AcopioMovimientoPage> createState() => _AcopioMovimientoPageState();
}

class _AcopioMovimientoPageState extends State<AcopioMovimientoPage> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _facturaNumeroController = TextEditingController();

  // Variables de estado
  TipoMovimientoAcopio _tipoMovimiento = TipoMovimientoAcopio.entrada;


  ProductoConStock? _productoSeleccionado;
  ClienteModel? _clienteSeleccionado;
  ProveedorModel? _proveedorSeleccionado;

  @override
  void initState() {
    super.initState();
    if (widget.acopioInicial != null) {
      // Precargar datos si venimos de un detalle
      _tipoMovimiento = TipoMovimientoAcopio.salida;
      // Lógica de precarga simplificada...
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<ClienteProvider>().cargarClientes();
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selectores simplificados para el ejemplo
            _buildDropdownProductos(),
            const SizedBox(height: 10),
            _buildDropdownClientes(),
            const SizedBox(height: 10),
            _buildDropdownProveedores(),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardar,
              child: const Text('Guardar'),
            )
          ],
        ),
      ),
    );
  }

  // Widgets placeholders para que compile
  Widget _buildDropdownProductos() {
    return Consumer<ProductoProvider>(
        builder: (ctx, prov, _) => DropdownButtonFormField<ProductoConStock>(
          hint: const Text('Producto'),
          items: prov.productos.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
          onChanged: (v) => setState(() => _productoSeleccionado = v),
        )
    );
  }

  Widget _buildDropdownClientes() {
    return Consumer<ClienteProvider>(
        builder: (ctx, prov, _) => DropdownButtonFormField<ClienteModel>(
          hint: const Text('Cliente'),
          items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial))).toList(),
          onChanged: (v) => setState(() => _clienteSeleccionado = v),
        )
    );
  }

  Widget _buildDropdownProveedores() {
    return Consumer<AcopioProvider>(
        builder: (ctx, prov, _) => DropdownButtonFormField<ProveedorModel>(
          hint: const Text('Proveedor'),
          items: prov.proveedores.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
          onChanged: (v) => setState(() => _proveedorSeleccionado = v),
        )
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _productoSeleccionado == null || _clienteSeleccionado == null) {
      return; // Proveedor puede ser null si es 'stockPropio'
    }

    final cantidad = double.tryParse(_cantidadController.text) ?? 0;
    // Si es salida, la cantidad debe ser negativa para la lógica de billetera
    final cantidadFinal = _tipoMovimiento == TipoMovimientoAcopio.salida ? -cantidad : cantidad;

    // Determinamos el ID del destino/origen
    final destinoId = _proveedorSeleccionado != null
        ? (_proveedorSeleccionado!.id ?? _proveedorSeleccionado!.codigo)
        : 'stockPropio';

    final exito = await context.read<AcopioProvider>().registrarMovimiento(
      clienteId: _clienteSeleccionado!.id ?? _clienteSeleccionado!.codigo,
      clienteNombre: _clienteSeleccionado!.razonSocial, // ✅ AGREGADO
      productoId: _productoSeleccionado!.productoId,
      productoNombre: _productoSeleccionado!.nombre, // ✅ AGREGADO
      cantidad: cantidadFinal,
      proveedorId: destinoId, // Pasamos el ID calculado
      tipo: _tipoMovimiento,
      motivo: _motivoController.text,
      facturaNumero: _facturaNumeroController.text,
    );

    if (exito && mounted) Navigator.pop(context, true);
  }}