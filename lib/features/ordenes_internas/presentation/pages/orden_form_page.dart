import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
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
  final _observacionesController = TextEditingController();
  final _solicitanteController = TextEditingController(text: 'Usuario App');

  // Variables de Selección
  ClienteModel? _clienteSeleccionado;
  ObraModel? _obraSeleccionada;
  DateTime _fechaSolicitud = DateTime.now();
  String _prioridad = 'normal';

  // Carrito de productos (Lista temporal)
  final List<Map<String, dynamic>> _itemsCarrito = [];

  @override
  void initState() {
    super.initState();
    // Cargamos todos los datos necesarios al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
      context.read<ObraProvider>().cargarObras();
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _solicitanteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Orden Interna')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. SECCIÓN DESTINO (Cliente -> Obra)
                  _buildCardDestino(),
                  const SizedBox(height: 16),

                  // 2. SECCIÓN DETALLES (Fecha, Prioridad, Quién pide)
                  _buildCardDetalles(),
                  const SizedBox(height: 16),

                  // 3. SECCIÓN PRODUCTOS (El "Carrito")
                  _buildCardProductos(),
                  const SizedBox(height: 16),

                  // 4. OBSERVACIONES
                  CustomTextField(
                    label: 'Observaciones Generales',
                    controller: _observacionesController,
                    maxLines: 3,
                    prefixIcon: Icons.comment,
                  ),
                ],
              ),
            ),

            // BOTÓN FLOTANTE DE ACCIÓN (Fijo abajo)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0,-2))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardarOrden,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('FINALIZAR Y CREAR ORDEN'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS INTERNOS ---

  Widget _buildCardDestino() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📍 Destino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),

            // Selector de CLIENTE
            Consumer<ClienteProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const LinearProgressIndicator();
                return DropdownButtonFormField<ClienteModel>(
                  value: _clienteSeleccionado,
                  decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                  isExpanded: true,
                  hint: const Text('Seleccione Cliente'),
                  items: provider.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _clienteSeleccionado = val;
                      _obraSeleccionada = null; // Reseteamos obra al cambiar cliente
                    });
                  },
                  validator: (v) => v == null ? 'Requerido' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Selector de OBRA (Filtrado)
            Consumer<ObraProvider>(
              builder: (context, provider, _) {
                // Filtramos las obras que coincidan con el ID o Código del cliente seleccionado
                final obrasFiltradas = _clienteSeleccionado == null
                    ? <ObraModel>[]
                    : provider.obras.where((o) =>
                o.clienteId == _clienteSeleccionado!.codigo ||
                    o.clienteId == _clienteSeleccionado!.id ||
                    o.clienteCodigo == _clienteSeleccionado!.codigo
                ).toList();

                return DropdownButtonFormField<ObraModel>(
                  value: _obraSeleccionada,
                  decoration: const InputDecoration(labelText: 'Obra', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                  isExpanded: true,
                  hint: _clienteSeleccionado == null
                      ? const Text('Primero seleccione un cliente')
                      : (obrasFiltradas.isEmpty ? const Text('Este cliente no tiene obras activas') : const Text('Seleccione Obra')),
                  // Si no hay cliente, deshabilitamos. Si hay, mostramos las filtradas.
                  items: obrasFiltradas.map((o) => DropdownMenuItem(value: o, child: Text(o.nombre, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: _clienteSeleccionado == null ? null : (val) => setState(() => _obraSeleccionada = val),
                  validator: (v) => v == null ? 'Requerido' : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetalles() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _solicitanteController,
            decoration: const InputDecoration(labelText: 'Solicitante', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
            validator: (v) => v!.isEmpty ? 'Requerido' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _prioridad,
            decoration: const InputDecoration(labelText: 'Prioridad', border: OutlineInputBorder()),
            items: ['baja', 'normal', 'alta', 'urgente'].map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _prioridad = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildCardProductos() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📦 Productos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                TextButton.icon(
                  onPressed: _mostrarDialogoAgregarProducto,
                  icon: const Icon(Icons.add),
                  label: const Text('AGREGAR'),
                ),
              ],
            ),
            const Divider(),

            if (_itemsCarrito.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay productos agregados.\nToca "AGREGAR" para empezar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _itemsCarrito.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = _itemsCarrito[i];
                  final producto = item['producto'] as ProductoConStock;
                  final subtotal = (item['precio'] as double) * (item['cantidad'] as double);

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item['cantidad']} ${producto.unidadBase} x \$${item['precio']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\$${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                          onPressed: () => setState(() => _itemsCarrito.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE NEGOCIO ---

  void _mostrarDialogoAgregarProducto() {
    ProductoConStock? prodSel;
    final cantCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<ProductoProvider>(
              builder: (context, provider, _) => DropdownButtonFormField<ProductoConStock>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Seleccionar Producto', border: OutlineInputBorder()),
                hint: const Text('Busca en el catálogo...'),
                items: provider.productos.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => prodSel = v,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cantCtrl,
              decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (prodSel != null && cantCtrl.text.isNotEmpty) {
                final cantidad = double.tryParse(cantCtrl.text);
                if (cantidad != null && cantidad > 0) {
                  setState(() {
                    _itemsCarrito.add({
                      'producto': prodSel, // Objeto completo para UI
                      'productoId': prodSel!.codigo, // ID para Backend
                      'cantidad': cantidad,
                      'precio': prodSel!.precioSinIva ?? 0.0,
                      'observaciones': '',
                    });
                  });
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarOrden() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteSeleccionado == null || _obraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Falta seleccionar Cliente u Obra')));
      return;
    }

    if (_itemsCarrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Agrega al menos un producto al pedido')));
      return;
    }

    // Feedback de carga
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    final exito = await context.read<OrdenInternaProvider>().crearOrden(
      clienteId: _clienteSeleccionado!.codigo,
      obraId: _obraSeleccionada!.codigo,
      solicitanteNombre: _solicitanteController.text,
      items: _itemsCarrito,
      observaciones: _observacionesController.text,
      fechaSolicitud: _fechaSolicitud,
      prioridad: _prioridad,
    );

    if (mounted) {
      Navigator.pop(context); // Cerrar loading
      if (exito) {
        Navigator.pop(context); // Cerrar formulario
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ ¡Orden Creada con Éxito!'), backgroundColor: AppColors.success)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Error al crear orden. Intenta nuevamente.'), backgroundColor: AppColors.error)
        );
      }
    }
  }
}