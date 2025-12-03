import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/billetera_acopio_model.dart'; // ✅ Usar Billetera
import '../../data/models/proveedor_model.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
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

  BilleteraAcopio? _billeteraOrigenSeleccionada; // ✅ Cambio de tipo
  ClienteModel? _destinoClienteSeleccionado;
  ProveedorModel? _destinoProveedorSeleccionado;

  // Origen específico dentro de la billetera (ej: Proveedor A)
  String? _origenSubId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<ClienteProvider>().cargarClientes();
      context.read<AcopioProvider>().cargarTodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traspaso de Material')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSelectorBilletera(),
            const SizedBox(height: 16),
            // Si hay billetera, preguntar de dónde sale (S&G o Proveedor X)
            if (_billeteraOrigenSeleccionada != null)
              _buildSelectorSubOrigen(),
            const SizedBox(height: 16),
            const Divider(),
            const Text("Destino", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildSelectorClienteDestino(),
            const SizedBox(height: 10),
            _buildSelectorProveedorDestino(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(labelText: 'Cantidad a Mover', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registrarTraspaso,
              child: const Text('CONFIRMAR TRASPASO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorBilletera() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, _) {
        return DropdownButtonFormField<BilleteraAcopio>(
          decoration: const InputDecoration(labelText: 'Origen (Cliente / Producto)'),
          value: _billeteraOrigenSeleccionada,
          isExpanded: true,
          items: provider.acopios.map((b) { // 'acopios' ahora es lista de Billeteras
            return DropdownMenuItem(
              value: b,
              child: Text('${b.clienteNombre} - ${b.productoNombre} (Total: ${b.saldoTotal})'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _billeteraOrigenSeleccionada = val;
              _origenSubId = null; // Reset sub-origen
            });
          },
        );
      },
    );
  }

  Widget _buildSelectorSubOrigen() {
    final b = _billeteraOrigenSeleccionada!;
    List<DropdownMenuItem<String>> items = [];

    // Opción Stock Propio
    if (b.cantidadEnDepositoPropio > 0) {
      items.add(DropdownMenuItem(
        value: 'stockPropio',
        child: Text('Depósito S&G (${b.cantidadEnDepositoPropio})'),
      ));
    }
    // Opciones Proveedores
    b.cantidadEnProveedores.forEach((provId, cant) {
      if (cant > 0) {
        items.add(DropdownMenuItem(
          value: provId,
          child: Text('Proveedor $provId ($cant)'), // Idealmente buscar nombre en provider
        ));
      }
    });

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: '¿De qué depósito sale?'),
      value: _origenSubId,
      items: items,
      onChanged: (val) => setState(() => _origenSubId = val),
    );
  }

  Widget _buildSelectorClienteDestino() {
    return Consumer<ClienteProvider>(
        builder: (ctx, prov, _) => DropdownButtonFormField<ClienteModel>(
          decoration: const InputDecoration(labelText: 'Cliente Destino'),
          items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial))).toList(),
          onChanged: (v) => setState(() => _destinoClienteSeleccionado = v),
        )
    );
  }

  Widget _buildSelectorProveedorDestino() {
    return Consumer<AcopioProvider>(
        builder: (ctx, prov, _) => DropdownButtonFormField<ProveedorModel>(
          decoration: const InputDecoration(labelText: 'Ubicación Destino'),
          items: prov.proveedores.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
          onChanged: (v) => setState(() => _destinoProveedorSeleccionado = v),
        )
    );
  }

  Future<void> _registrarTraspaso() async {
    if (_billeteraOrigenSeleccionada == null || _origenSubId == null ||
        _destinoClienteSeleccionado == null || _destinoProveedorSeleccionado == null) {
      return;
    }

    final cantidad = double.tryParse(_cantidadController.text) ?? 0;

    // Usamos el método genérico registrarTraspaso del provider
    final exito = await context.read<AcopioProvider>().registrarTraspaso(
      productoCodigo: _billeteraOrigenSeleccionada!.productoId,
      origenClienteCodigo: _billeteraOrigenSeleccionada!.clienteId,
      origenProveedorCodigo: _origenSubId!,
      destinoClienteCodigo: _destinoClienteSeleccionado!.codigo,
      destinoProveedorCodigo: _destinoProveedorSeleccionado!.id ?? _destinoProveedorSeleccionado!.codigo,
      cantidad: cantidad,
      motivo: _motivoController.text,
      referencia: _referenciaController.text,
    );

    if (exito && mounted) Navigator.pop(context, true);
  }
}