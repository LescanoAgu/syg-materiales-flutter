import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/producto_search_delegate.dart'; // Importar Buscador
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../obras/data/models/obra_model.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import '../../../stock/data/models/producto_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../providers/orden_interna_provider.dart';

class OrdenFormPage extends StatefulWidget {
  const OrdenFormPage({super.key});
  @override
  State<OrdenFormPage> createState() => _OrdenFormPageState();
}

class _OrdenFormPageState extends State<OrdenFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesCtrl = TextEditingController();
  final _solicitanteCtrl = TextEditingController(text: 'Usuario App');

  ClienteModel? _clienteSel;
  ObraModel? _obraSel;
  final List<Map<String, dynamic>> _carrito = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
      context.read<ObraProvider>().cargarObras();
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Orden')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSelectorCliente(),
                  const SizedBox(height: 12),
                  _buildSelectorObra(),
                  const SizedBox(height: 20),
                  _buildSeccionProductos(),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _observacionesCtrl,
                    decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('CREAR ORDEN'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCliente() {
    return Consumer<ClienteProvider>(builder: (ctx, prov, _) => DropdownButtonFormField<ClienteModel>(
      decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
      items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial))).toList(),
      onChanged: (v) => setState(() { _clienteSel = v; _obraSel = null; }),
      validator: (v) => v == null ? 'Requerido' : null,
    ));
  }

  Widget _buildSelectorObra() {
    return Consumer<ObraProvider>(builder: (ctx, prov, _) {
      final obras = _clienteSel == null ? <ObraModel>[] : prov.obras.where((o) => o.clienteId == _clienteSel!.codigo).toList();
      return DropdownButtonFormField<ObraModel>(
        decoration: const InputDecoration(labelText: 'Obra', border: OutlineInputBorder()),
        items: obras.map((o) => DropdownMenuItem(value: o, child: Text(o.nombre))).toList(),
        onChanged: _clienteSel == null ? null : (v) => setState(() => _obraSel = v),
        validator: (v) => v == null ? 'Requerido' : null,
        hint: Text(_clienteSel == null ? 'Seleccione cliente primero' : 'Seleccione Obra'),
      );
    });
  }

  Widget _buildSeccionProductos() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _agregarProducto,
              icon: const Icon(Icons.search),
              label: const Text('BUSCAR'),
            ),
          ],
        ),
        const Divider(),
        if (_carrito.isEmpty) const Text('Sin productos', style: TextStyle(color: Colors.grey)),
        ..._carrito.map((item) {
          final p = item['producto'] as ProductoModel;
          return ListTile(
            title: Text(p.nombre),
            subtitle: Text('${item['cantidad']} ${p.unidadBase}'), // SIN PRECIO
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _carrito.remove(item))),
          );
        }),
      ],
    );
  }

  Future<void> _agregarProducto() async {
    final prods = context.read<ProductoProvider>().productos;
    final p = await showSearch(context: context, delegate: ProductoSearchDelegate(prods));

    if (p != null && mounted) {
      final cantCtrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(p.nombre),
          content: TextField(
            controller: cantCtrl,
            decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          actions: [
            ElevatedButton(onPressed: () {
              final c = double.tryParse(cantCtrl.text);
              if (c != null && c > 0) {
                setState(() => _carrito.add({
                  'producto': p,
                  'productoId': p.codigo,
                  'cantidad': c,
                  'precio': p.precioSinIva ?? 0
                }));
                Navigator.pop(ctx);
              }
            }, child: const Text('AGREGAR'))
          ],
        ),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _carrito.isEmpty) return;

    await context.read<OrdenInternaProvider>().crearOrden(
      clienteId: _clienteSel!.codigo,
      obraId: _obraSel!.codigo,
      solicitanteNombre: _solicitanteController.text, // Usar controlador correcto
      items: _carrito,
      observaciones: _observacionesCtrl.text,
    );
    if (mounted) Navigator.pop(context);
  }
  // Corrección: Variable faltante
  final _solicitanteController = TextEditingController(text: "Usuario App");
}