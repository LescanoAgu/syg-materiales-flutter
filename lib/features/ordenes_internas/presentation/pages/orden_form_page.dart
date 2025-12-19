import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/producto_search_delegate.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../obras/data/models/obra_model.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import '../../../stock/data/models/producto_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../data/models/orden_interna_model.dart';

class OrdenFormPage extends StatefulWidget {
  final OrdenInternaDetalle? ordenParaEditar;
  final String? preSelectedClienteId;
  final bool esRetiroAcopio;

  const OrdenFormPage({
    super.key,
    this.ordenParaEditar,
    this.preSelectedClienteId,
    this.esRetiroAcopio = false,
  });

  @override
  State<OrdenFormPage> createState() => _OrdenFormPageState();
}

class _OrdenFormPageState extends State<OrdenFormPage> {
  // Controladores
  final _tituloCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  // Estado
  bool _isLoading = false;
  late bool _esRetiroAcopio;
  ClienteModel? _clienteSel;
  ObraModel? _obraSel;
  String _prioridad = 'media';

  // Carrito: { productoId : cantidad }
  final Map<String, double> _carrito = {};
  // Cache de modelos para mostrar info: { productoId : ProductoModel }
  final Map<String, ProductoModel> _productosInfo = {};
  // Controladores para inputs manuales
  final Map<String, TextEditingController> _cantControllers = {};

  @override
  void initState() {
    super.initState();
    _esRetiroAcopio = widget.esRetiroAcopio;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ClienteProvider>().cargarClientes();
      if(mounted) await context.read<ObraProvider>().cargarObras();

      // Si viene pre-seleccionado (desde detalle cliente)
      if (widget.preSelectedClienteId != null) {
        final clientes = context.read<ClienteProvider>().clientes;
        try {
          final c = clientes.firstWhere((e) => e.codigo == widget.preSelectedClienteId);
          setState(() => _clienteSel = c);
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    for (var c in _cantControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_esRetiroAcopio ? 'Retiro de Acopio' : 'Nueva Solicitud'),
        backgroundColor: _esRetiroAcopio ? AppColors.success : AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. SECCIÓN DE CABECERA (Cliente/Obra)
          _buildHeaderSection(),

          const Divider(height: 1),

          // 2. LISTA DE MATERIALES (El cuerpo principal)
          Expanded(
            child: _carrito.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _carrito.length,
              itemBuilder: (ctx, i) {
                final id = _carrito.keys.elementAt(i);
                return _buildCartItem(id);
              },
            ),
          ),
        ],
      ),

      // BOTÓN FLOTANTE PARA AGREGAR
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirBuscador,
        label: const Text("AGREGAR PRODUCTO"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.secondary,
      ),

      // BARRA INFERIOR DE CONFIRMACIÓN
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.05))]
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${_carrito.length} Items", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_esRetiroAcopio ? "Descuenta saldo" : "Solicitud stock", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _carrito.isEmpty || _isLoading ? null : _confirmarPedido,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _esRetiroAcopio ? AppColors.success : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("ENVIAR PEDIDO", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS INTERNOS ---

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Consumer<ClienteProvider>(
                  builder: (ctx, prov, _) => DropdownButtonFormField<ClienteModel>(
                    value: _clienteSel,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(),
                    ),
                    items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: widget.preSelectedClienteId != null ? null : (v) => setState(() { _clienteSel = v; _obraSel = null; }),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer<ObraProvider>(
                  builder: (ctx, prov, _) {
                    final obrasFiltradas = _clienteSel == null
                        ? <ObraModel>[]
                        : prov.obras.where((o) =>
                    (o.clienteId == _clienteSel!.codigo || o.clienteId == _clienteSel!.id) &&
                        o.estado == 'activa' // ✅ Solo obras activas
                    ).toList();

                    return DropdownButtonFormField<ObraModel>(
                      value: _obraSel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Obra',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(),
                      ),
                      hint: Text(_clienteSel == null ? 'Elija Cliente' : (obrasFiltradas.isEmpty ? 'Sin obras activas' : 'Seleccione')),
                      items: obrasFiltradas.map((o) => DropdownMenuItem(value: o, child: Text(o.nombre, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _obraSel = v),
                    );
                  },
                ),
              ),
            ],
          ),

          if (!_esRetiroAcopio)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Text("Prioridad:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  _buildPriorityChip('media', Colors.blue),
                  const SizedBox(width: 8),
                  _buildPriorityChip('urgente', Colors.red),
                ],
              ),
            ),

          ExpansionTile(
            title: const Text("Observaciones / Notas", style: TextStyle(fontSize: 14)),
            children: [
              CustomTextField(label: "Escribir nota...", controller: _observacionesCtrl, maxLines: 2),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String valor, Color color) {
    final selected = _prioridad == valor;
    return InkWell(
      onTap: () => setState(() => _prioridad = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          valor.toUpperCase(),
          style: TextStyle(fontSize: 12, color: selected ? Colors.white : color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCartItem(String id) {
    final p = _productosInfo[id]!;

    // Inicializar controlador si no existe
    if (!_cantControllers.containsKey(id)) {
      _cantControllers[id] = TextEditingController(text: _carrito[id]!.toStringAsFixed(0));
    }
    final ctrl = _cantControllers[id]!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: Text(p.unidadBase, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(p.codigo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            // CONTROLES DE CANTIDAD MANUAL
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                  onPressed: () {
                    double actual = double.tryParse(ctrl.text) ?? 0;
                    if (actual > 1) {
                      double nuevo = actual - 1;
                      ctrl.text = nuevo.toStringAsFixed(0);
                      _carrito[id] = nuevo;
                    } else {
                      setState(() {
                        _carrito.remove(id);
                        _cantControllers.remove(id);
                      });
                    }
                  },
                ),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final num = double.tryParse(val);
                      if (num != null && num > 0) {
                        _carrito[id] = num;
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () {
                    double actual = double.tryParse(ctrl.text) ?? 0;
                    double nuevo = actual + 1;
                    ctrl.text = nuevo.toStringAsFixed(0);
                    _carrito[id] = nuevo;
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("El pedido está vacío", style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("Usa el botón + para agregar materiales", style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- LÓGICA ---

  Future<void> _abrirBuscador() async {
    final p = await showSearch(context: context, delegate: ProductoSearchDelegate());
    if (p != null) {
      setState(() {
        if (!_carrito.containsKey(p.codigo)) {
          _carrito[p.codigo] = 1;
          _productosInfo[p.codigo] = p;
        } else {
          _carrito[p.codigo] = (_carrito[p.codigo] ?? 0) + 1;
          if(_cantControllers.containsKey(p.codigo)) {
            _cantControllers[p.codigo]!.text = _carrito[p.codigo]!.toStringAsFixed(0);
          }
        }
      });
    }
  }

  Future<void> _confirmarPedido() async {
    if (_clienteSel == null || _obraSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Selecciona Cliente y Obra"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().usuario;

      // ✅ CORRECCIÓN CLAVE: Aplanamos el objeto. NO pasamos 'producto': p
      final itemsList = _carrito.entries.map((e) {
        final p = _productosInfo[e.key]!;
        return {
          'productoId': e.key,
          'productoNombre': p.nombre, // Guardamos los datos primitivos
          'productoCodigo': p.codigo,
          'unidad': p.unidadBase,
          'cantidad': e.value,
          'precio': p.precioSinIva ?? 0,
          'observaciones': ''
        };
      }).toList();

      final exito = await context.read<OrdenInternaProvider>().crearOrden(
        clienteId: _clienteSel!.codigo,
        obraId: _obraSel!.codigo,
        solicitanteNombre: user?.nombre ?? 'App User',
        titulo: _tituloCtrl.text.isNotEmpty ? _tituloCtrl.text : null,
        items: itemsList,
        observaciones: _observacionesCtrl.text,
        prioridad: _prioridad,
        esRetiroAcopio: _esRetiroAcopio,
        acopioId: _clienteSel!.codigo,
      );

      if (mounted) {
        if (exito) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Pedido enviado correctamente"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Error al enviar"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
}