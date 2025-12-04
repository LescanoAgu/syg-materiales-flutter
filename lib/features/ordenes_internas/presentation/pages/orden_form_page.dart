import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../obras/data/models/obra_model.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import '../../../stock/data/models/producto_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../providers/orden_interna_provider.dart';
import '../../data/models/orden_interna_model.dart';

class OrdenFormPage extends StatefulWidget {
  final OrdenInternaDetalle? ordenParaEditar;
  const OrdenFormPage({super.key, this.ordenParaEditar});

  @override
  State<OrdenFormPage> createState() => _OrdenFormPageState();
}

class _OrdenFormPageState extends State<OrdenFormPage> {
  // --- CONTROLADORES ---
  final _searchCtrl = TextEditingController();
  final _tituloCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  Timer? _debounce;

  // --- ESTADO ---
  int _step = 1; // 1: Selección Obra, 2: Catálogo/Carrito, 3: Confirmación
  bool _isLoading = false;

  // Datos de Cabecera
  ClienteModel? _clienteSel;
  ObraModel? _obraSel;
  String _prioridad = 'media';

  // Carrito: { productoCodigo : cantidad }
  final Map<String, double> _carrito = {};

  // Para mostrar info del producto en el carrito (nombre, unidad)
  final Map<String, ProductoModel> _productosCache = {};

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<ClienteProvider>().cargarClientes();
      context.read<ObraProvider>().cargarObras();
      // Cargamos productos para el catálogo
      context.read<ProductoProvider>().cargarProductos(recargar: true);

      if (widget.ordenParaEditar != null) {
        // MODO EDICIÓN: Pre-llenar datos
        _cargarOrdenExistente();
      }
    });
  }

  void _cargarOrdenExistente() {
    final orden = widget.ordenParaEditar!.orden;
    _step = 2; // Saltamos directo al catálogo
    _tituloCtrl.text = orden.titulo ?? '';
    _observacionesCtrl.text = orden.observacionesCliente ?? '';
    _prioridad = orden.prioridad;

    // Recuperar Cliente y Obra (lógica simplificada)
    final clienteProv = context.read<ClienteProvider>();
    final obraProv = context.read<ObraProvider>();

    // Intentamos buscar en las listas cargadas (esto asume que cargaron rápido,
    // en producción idealmente esperarías el Future)
    try {
      _clienteSel = clienteProv.clientes.firstWhere((c) => c.codigo == orden.clienteId);
      _obraSel = obraProv.obras.firstWhere((o) => o.codigo == orden.obraId);
    } catch (_) {}

    // Llenar carrito
    for (var item in widget.ordenParaEditar!.items) {
      _carrito[item.productoCodigo] = item.cantidadFinal;
      // Creamos un modelo temporal para la cache visual
      _productosCache[item.productoCodigo] = ProductoModel(
          id: item.productoCodigo,
          codigo: item.productoCodigo,
          categoriaId: 'UNK',
          nombre: item.productoNombre,
          unidadBase: item.unidadBase
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_step == 1 ? 'Nueva Solicitud' : (_step == 2 ? 'Seleccionar Materiales' : 'Confirmar Pedido')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Barra de Progreso
          LinearProgressIndicator(
            value: _step / 3,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),

          Expanded(
            child: _buildStepContent(),
          ),
        ],
      ),
      // Solo mostramos el FAB o Barra inferior en el paso 2
      bottomNavigationBar: _step == 2 ? _buildCarritoBar() : null,
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1: return _buildStep1Cabecera();
      case 2: return _buildStep2Catalogo();
      case 3: return _buildStep3Resumen();
      default: return const SizedBox();
    }
  }

  // ===========================================================================
  // PASO 1: SELECCIÓN DE OBRA Y DATOS GENERALES
  // ===========================================================================
  Widget _buildStep1Cabecera() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("¿Para dónde es el material?", style: AppTextStyles.h2),
          const SizedBox(height: 20),

          // Selector de Cliente
          Consumer<ClienteProvider>(builder: (ctx, prov, _) {
            return DropdownButtonFormField<ClienteModel>(
              value: _clienteSel,
              decoration: const InputDecoration(
                  labelText: 'Cliente',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.business)
              ),
              items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial))).toList(),
              onChanged: (v) => setState(() { _clienteSel = v; _obraSel = null; }),
            );
          }),
          const SizedBox(height: 20),

          // Selector de Obra (Filtrado)
          Consumer<ObraProvider>(builder: (ctx, prov, _) {
            final obras = _clienteSel == null ? <ObraModel>[] : prov.obras.where((o) => o.clienteId == _clienteSel!.codigo).toList();
            return DropdownButtonFormField<ObraModel>(
              value: _obraSel,
              decoration: const InputDecoration(
                  labelText: 'Obra de Destino',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.location_on)
              ),
              hint: const Text('Seleccione cliente primero'),
              items: obras.map((o) => DropdownMenuItem(value: o, child: Text(o.nombre))).toList(),
              onChanged: _clienteSel == null ? null : (v) => setState(() => _obraSel = v),
            );
          }),
          const SizedBox(height: 20),

          // Prioridad
          const Text("Prioridad del Pedido", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPrioridadChip('baja', 'Baja', Colors.green),
              const SizedBox(width: 8),
              _buildPrioridadChip('media', 'Normal', Colors.blue),
              const SizedBox(width: 8),
              _buildPrioridadChip('urgente', 'Urgente', Colors.red),
            ],
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_clienteSel != null && _obraSel != null)
                  ? () => setState(() => _step = 2)
                  : null,
              child: const Text("CONTINUAR AL CATÁLOGO"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPrioridadChip(String valor, String label, Color color) {
    final selected = _prioridad == valor;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
          color: selected ? color : Colors.black,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal
      ),
      onSelected: (v) => setState(() => _prioridad = valor),
      checkmarkColor: color,
    );
  }

  // ===========================================================================
  // PASO 2: CATÁLOGO TIPO "E-COMMERCE"
  // ===========================================================================
  Widget _buildStep2Catalogo() {
    return Column(
      children: [
        // Buscador
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
                hintText: 'Buscar material (ej: Cemento)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0)
            ),
            onChanged: (v) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                context.read<ProductoProvider>().buscarProductos(v);
              });
            },
          ),
        ),

        // Lista de Productos
        Expanded(
          child: Consumer<ProductoProvider>(
            builder: (ctx, prov, _) {
              if (prov.isLoading) return const Center(child: CircularProgressIndicator());
              if (prov.productos.isEmpty) return const Center(child: Text("No se encontraron materiales"));

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100), // Espacio para el carrito
                itemCount: prov.productos.length,
                itemBuilder: (ctx, i) {
                  final p = prov.productos[i];
                  _productosCache[p.codigo] = p; // Guardamos en cache para usar luego
                  return _buildProductoItem(p);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductoItem(ProductoModel p) {
    final cantidadEnCarrito = _carrito[p.codigo] ?? 0;
    final tieneEnCarrito = cantidadEnCarrito > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tieneEnCarrito ? AppColors.primary : Colors.transparent, width: 1.5)
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icono
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                  color: tieneEnCarrito ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Icon(Icons.construction, color: tieneEnCarrito ? AppColors.primary : Colors.grey),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${p.codigo} • ${p.unidadBase}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),

            // Controles +/-
            if (!tieneEnCarrito)
              ElevatedButton(
                onPressed: () => _modificarCantidad(p.codigo, 1),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundGray,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(60, 36)
                ),
                child: const Text("AGREGAR"),
              )
            else
              Container(
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18, color: AppColors.primary),
                      onPressed: () => _modificarCantidad(p.codigo, -1),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                    Text(
                      cantidadEnCarrito.toStringAsFixed(0),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                      onPressed: () => _modificarCantidad(p.codigo, 1),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  void _modificarCantidad(String id, double delta) {
    setState(() {
      final actual = _carrito[id] ?? 0;
      final nueva = actual + delta;
      if (nueva <= 0) {
        _carrito.remove(id);
      } else {
        _carrito[id] = nueva;
      }
    });
  }

  Widget _buildCarritoBar() {
    final itemsCount = _carrito.length;
    if (itemsCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$itemsCount Materiales", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text("en tu pedido", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() => _step = 3),
              icon: const Icon(Icons.check),
              label: const Text("VER RESUMEN"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              ),
            )
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PASO 3: CONFIRMACIÓN
  // ===========================================================================
  Widget _buildStep3Resumen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Resumen
          Card(
            color: AppColors.primary.withOpacity(0.05),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: AppColors.primary, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_obraSel?.nombre ?? "Obra", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_clienteSel?.razonSocial ?? "Cliente", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Campos opcionales
          CustomTextField(
            label: 'Título / Referencia (Opcional)',
            controller: _tituloCtrl,
            hint: 'Ej: Materiales para losa del 2do piso',
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Observaciones',
            controller: _observacionesCtrl,
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Lista de Items a confirmar
          const Align(alignment: Alignment.centerLeft, child: Text("Detalle del Pedido", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _carrito.length,
              separatorBuilder: (_,__) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final id = _carrito.keys.elementAt(i);
                final cant = _carrito[id]!;
                final p = _productosCache[id]!;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.nombre),
                  trailing: Text('${cant.toStringAsFixed(0)} ${p.unidadBase}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),

          // Botón Final
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enviarPedido,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("CONFIRMAR PEDIDO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _enviarPedido() async {
    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().usuario;
      final itemsList = _carrito.entries.map((e) {
        final p = _productosCache[e.key];
        return {
          'productoId': e.key,
          'producto': p, // Para guardar el nombre snapshot
          'cantidad': e.value,
          'precio': p?.precioSinIva ?? 0,
          'observaciones': ''
        };
      }).toList();

      final provider = context.read<OrdenInternaProvider>();

      bool exito;
      if (widget.ordenParaEditar != null) {
        // Editar
        exito = await provider.editarOrden(
          ordenId: widget.ordenParaEditar!.orden.id!,
          clienteId: _clienteSel!.codigo,
          obraId: _obraSel!.codigo,
          prioridad: _prioridad,
          titulo: _tituloCtrl.text,
          observaciones: _observacionesCtrl.text,
          items: itemsList,
        );
      } else {
        // Crear
        exito = await provider.crearOrden(
          clienteId: _clienteSel!.codigo,
          obraId: _obraSel!.codigo,
          solicitanteNombre: user?.nombre ?? 'App User',
          titulo: _tituloCtrl.text,
          items: itemsList,
          observaciones: _observacionesCtrl.text,
          prioridad: _prioridad,
        );
      }

      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Pedido enviado con éxito"), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al enviar pedido"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
}