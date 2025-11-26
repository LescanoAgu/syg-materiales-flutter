import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/acopio_model.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
// IMPORT FALTANTE:
import '../../../stock/data/models/producto_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../../data/models/proveedor_model.dart';
import '../providers/acopio_provider.dart';

class AcopioTraspasoPage extends StatefulWidget {
  const AcopioTraspasoPage({super.key});

  @override
  State<AcopioTraspasoPage> createState() => _AcopioTraspasoPageState();
}

class _AcopioTraspasoPageState extends State<AcopioTraspasoPage> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _facturaNumeroController = TextEditingController();

  // Ahora sí reconoce ProductoConStock
  ProductoConStock? _productoSeleccionado;
  ClienteModel? _origenClienteSeleccionado;
  ProveedorModel? _origenProveedorSeleccionado;
  AcopioDetalle? _acopioOrigenSeleccionado;

  ClienteModel? _destinoClienteSeleccionado;
  ProveedorModel? _destinoProveedorSeleccionado;
  DateTime? _facturaFecha;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<ClienteProvider>().cargarClientes();
      context.read<AcopioProvider>().cargarProveedores();
      context.read<AcopioProvider>().cargarAcopios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traspaso')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSelectorAcopioOrigen(),
            const SizedBox(height: 16),
            _buildSelectorClienteDestino(),
            const SizedBox(height: 16),
            _buildSelectorProveedorDestino(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registrarTraspaso,
              child: const Text('Registrar Traspaso'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorAcopioOrigen() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, _) {
        return DropdownButtonFormField<AcopioDetalle>(
          initialValue: _acopioOrigenSeleccionado,
          hint: const Text('Seleccionar Origen'),
          isExpanded: true,
          items: provider.acopios.map((a) {
            return DropdownMenuItem(
              value: a,
              child: Text('${a.productoNombre} - ${a.clienteRazonSocial}'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _acopioOrigenSeleccionado = val;
              if (val != null) {
                // Crear objeto ProductoConStock ficticio para mantener compatibilidad
                _productoSeleccionado = ProductoConStock(
                    id: val.acopio.productoId,
                    codigo: val.productoCodigo,
                    categoriaId: '',
                    nombre: val.productoNombre,
                    unidadBase: val.unidadBase
                );
                _origenClienteSeleccionado = ClienteModel(
                    id: val.acopio.clienteId,
                    codigo: val.clienteCodigo,
                    razonSocial: val.clienteRazonSocial
                );
                _origenProveedorSeleccionado = ProveedorModel(
                    id: val.acopio.proveedorId,
                    codigo: val.proveedorCodigo,
                    nombre: val.proveedorNombre,
                    tipo: TipoProveedor.proveedor,
                    createdAt: DateTime.now()
                );
              }
            });
          },
        );
      },
    );
  }

  Widget _buildSelectorClienteDestino() {
    return Consumer<ClienteProvider>(
        builder: (ctx, prov, _) => DropdownButtonFormField<ClienteModel>(
          hint: const Text('Cliente Destino'),
          items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial))).toList(),
          onChanged: (v) => setState(() => _destinoClienteSeleccionado = v),
        )
    );
  }

  Widget _buildSelectorProveedorDestino() {
    return Consumer<AcopioProvider>(
        builder: (ctx, prov, _) => DropdownButtonFormField<ProveedorModel>(
          hint: const Text('Ubicación Destino'),
          items: prov.proveedores.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
          onChanged: (v) => setState(() => _destinoProveedorSeleccionado = v),
        )
    );
  }

  Future<void> _registrarTraspaso() async {
    if (_acopioOrigenSeleccionado == null || _destinoClienteSeleccionado == null || _destinoProveedorSeleccionado == null) {
      return;
    }

    final cantidad = double.tryParse(_cantidadController.text) ?? 0;

    // Casting seguro de IDs
    final exito = await context.read<AcopioProvider>().registrarTraspaso(
      productoCodigo: _productoSeleccionado!.productoCodigo,
      origenClienteCodigo: _origenClienteSeleccionado!.id ?? _origenClienteSeleccionado!.codigo,
      origenProveedorCodigo: _origenProveedorSeleccionado!.id ?? _origenProveedorSeleccionado!.codigo,
      destinoClienteCodigo: _destinoClienteSeleccionado!.id ?? _destinoClienteSeleccionado!.codigo,
      destinoProveedorCodigo: _destinoProveedorSeleccionado!.id ?? _destinoProveedorSeleccionado!.codigo,
      cantidad: cantidad,
      motivo: _motivoController.text,
      referencia: _referenciaController.text,
      facturaNumero: _facturaNumeroController.text,
      facturaFecha: _facturaFecha,
    );

    if (exito && mounted) Navigator.pop(context, true);
  }
}