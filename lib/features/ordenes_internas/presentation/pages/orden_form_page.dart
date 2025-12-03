import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/producto_search_delegate.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../obras/data/models/obra_model.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import '../../../stock/data/models/producto_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../providers/orden_interna_provider.dart';
import '../../data/models/orden_interna_model.dart'; // Importante para recibir el objeto
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class OrdenFormPage extends StatefulWidget {
  final OrdenInternaDetalle? ordenParaEditar; // Si es != null, es edición

  const OrdenFormPage({super.key, this.ordenParaEditar});

  @override
  State<OrdenFormPage> createState() => _OrdenFormPageState();
}

class _OrdenFormPageState extends State<OrdenFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _tituloCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  final _solicitanteCtrl = TextEditingController();

  // Estado
  ClienteModel? _clienteSel;
  ObraModel? _obraSel;
  String _prioridad = 'media';
  final List<Map<String, dynamic>> _carrito = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _observacionesCtrl.dispose();
    _solicitanteCtrl.dispose();
    super.dispose();
  }

  void _inicializarDatos() {
    // 1. Cargar providers y datos
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final clienteProv = context.read<ClienteProvider>();
      final obraProv = context.read<ObraProvider>();
      context.read<ProductoProvider>().cargarProductos();

      await clienteProv.cargarClientes();
      await obraProv.cargarObras();

      // 2. Si es edición, pre-cargar datos
      if (widget.ordenParaEditar != null) {
        final o = widget.ordenParaEditar!.orden;

        _tituloCtrl.text = o.titulo ?? '';
        _solicitanteCtrl.text = o.solicitanteNombre;
        _observacionesCtrl.text = o.observacionesCliente ?? '';
        _prioridad = o.prioridad;

        // Buscar objetos Cliente y Obra completos para los dropdowns
        try {
          if (clienteProv.clientes.isNotEmpty) {
            _clienteSel = clienteProv.clientes.firstWhere((c) => c.codigo == o.clienteId, orElse: () => clienteProv.clientes.first);
          }
          if (obraProv.obras.isNotEmpty) {
            _obraSel = obraProv.obras.firstWhere((ob) => ob.codigo == o.obraId, orElse: () => obraProv.obras.first);
          }
        } catch (_) {}

        // Mapear items existentes al formato del carrito
        for (var itemDetalle in widget.ordenParaEditar!.items) {
          _carrito.add({
            // Reconstruimos un ProductoModel mínimo para que la UI no se rompa
            'producto': ProductoModel(
                id: itemDetalle.productoCodigo,
                codigo: itemDetalle.productoCodigo,
                categoriaId: '',
                nombre: itemDetalle.productoNombre,
                unidadBase: itemDetalle.unidadBase
            ),
            'productoId': itemDetalle.productoCodigo,
            'cantidad': itemDetalle.cantidadFinal,
            'precio': 0.0, // Precio visual, no crítico en edición
            'observaciones': itemDetalle.item.observaciones
          });
        }

        setState(() {}); // Actualizar UI con datos cargados
      } else {
        // Modo Creación: Autocompletar usuario actual
        final usuario = context.read<AuthProvider>().usuario;
        if (usuario != null) {
          _solicitanteCtrl.text = usuario.nombre;
        } else {
          _solicitanteCtrl.text = "Usuario App";
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.ordenParaEditar != null;

    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Orden' : 'Nueva Orden')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // TÍTULO / REFERENCIA
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Título / Referencia (Opcional)',
                        hintText: 'Ej: Materiales para losa',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.white
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // ENCABEZADO (Solicitante y Prioridad)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _solicitanteCtrl,
                          decoration: const InputDecoration(labelText: 'Solicitante', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person), filled: true, fillColor: Colors.white),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _prioridad,
                          decoration: const InputDecoration(labelText: 'Prioridad', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag), filled: true, fillColor: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'baja', child: Text('🟢 Baja')),
                            DropdownMenuItem(value: 'media', child: Text('🔵 Normal')),
                            DropdownMenuItem(value: 'alta', child: Text('🟠 Alta')),
                            DropdownMenuItem(value: 'urgente', child: Text('🔴 URGENTE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                          ],
                          onChanged: (v) => setState(() => _prioridad = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSelectorCliente(),
                  const SizedBox(height: 12),
                  _buildSelectorObra(),
                  const SizedBox(height: 24),

                  _buildSeccionProductos(),

                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _observacionesCtrl,
                    decoration: const InputDecoration(labelText: 'Observaciones Generales', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // Botón de Acción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _guardando
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR ORDEN'),
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
      value: _clienteSel,
      decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
      items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) => setState(() { _clienteSel = v; _obraSel = null; }),
      validator: (v) => v == null ? 'Requerido' : null,
    ));
  }

  Widget _buildSelectorObra() {
    return Consumer<ObraProvider>(builder: (ctx, prov, _) {
      final obras = _clienteSel == null ? <ObraModel>[] : prov.obras.where((o) => o.clienteId == _clienteSel!.codigo).toList();
      return DropdownButtonFormField<ObraModel>(
        value: _obraSel,
        decoration: const InputDecoration(labelText: 'Obra', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
        items: obras.map((o) => DropdownMenuItem(value: o, child: Text(o.nombre, overflow: TextOverflow.ellipsis))).toList(),
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
            const Text('Productos Requeridos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            TextButton.icon(
              onPressed: _agregarProducto,
              icon: const Icon(Icons.search),
              label: const Text('AGREGAR'),
            ),
          ],
        ),
        const Divider(),
        if (_carrito.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: const [
                Icon(Icons.format_list_bulleted, size: 40, color: Colors.grey),
                SizedBox(height: 10),
                Text('Lista vacía. Agrega materiales.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ..._carrito.map((item) {
          final p = item['producto'] as ProductoModel;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${item['cantidad']} ${p.unidadBase}'),
              trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _carrito.remove(item))
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _agregarProducto() async {
    final p = await showSearch(
        context: context,
        delegate: ProductoSearchDelegate()
    );

    if (p != null && mounted) {
      final cantCtrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(p.nombre),
          content: TextField(
            controller: cantCtrl,
            decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () {
                  final c = double.tryParse(cantCtrl.text);
                  if (c != null && c > 0) {
                    setState(() => _carrito.add({
                      'producto': p,
                      'productoId': p.codigo,
                      'cantidad': c,
                      'precio': p.precioSinIva ?? 0,
                      'observaciones': ''
                    }));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('AGREGAR')
            )
          ],
        ),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Debes agregar al menos un producto")));
      return;
    }

    setState(() => _guardando = true);

    try {
      final provider = context.read<OrdenInternaProvider>();
      bool exito;

      if (widget.ordenParaEditar != null) {
        // MODO EDICIÓN
        exito = await provider.editarOrden(
          ordenId: widget.ordenParaEditar!.orden.id!,
          clienteId: _clienteSel!.codigo,
          obraId: _obraSel!.codigo,
          prioridad: _prioridad,
          titulo: _tituloCtrl.text.trim(),
          observaciones: _observacionesCtrl.text,
          items: _carrito,
        );
      } else {
        // MODO CREACIÓN
        exito = await provider.crearOrden(
          clienteId: _clienteSel!.codigo,
          obraId: _obraSel!.codigo,
          solicitanteNombre: _solicitanteCtrl.text,
          titulo: _tituloCtrl.text.trim(),
          items: _carrito,
          observaciones: _observacionesCtrl.text,
          prioridad: _prioridad,
        );
      }

      if (mounted) {
        if (exito) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Operación exitosa'), backgroundColor: Colors.green)
          );
        } else {
          setState(() => _guardando = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e'), backgroundColor: Colors.red));
      }
    }
  }
}