import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../providers/producto_provider.dart';
import '../providers/movimiento_stock_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'movimiento_historial_page.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import '../../../obras/data/models/obra_model.dart';

class StockPage extends StatefulWidget {
  final bool esNavegacionPrincipal;
  const StockPage({super.key, this.esNavegacionPrincipal = false});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recargarTodo();
    });
  }

  void _recargarTodo() {
    context.read<ProductoProvider>().cargarProductos(recargar: true);
    context.read<ObraProvider>().cargarObras();
  }

  @override
  Widget build(BuildContext context) {
    final bool mostrarAppBar = !widget.esNavegacionPrincipal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: mostrarAppBar ? AppBar(title: const Text('Inventario Maestro')) : null,
      drawer: mostrarAppBar ? const AppDrawer() : null,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());

                List<ProductoModel> lista = provider.productos;
                if (_filtroEstado == 'bajo') {
                  lista = lista.where((p) => p.stockBajo).toList();
                } else if (_filtroEstado == 'sin_stock') {
                  lista = lista.where((p) => p.sinStock).toList();
                }

                if (lista.isEmpty) return _buildEmptyState();

                return RefreshIndicator(
                  onRefresh: () async => _recargarTodo(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: lista.length,
                    itemBuilder: (ctx, i) => _buildSmartStockCard(context, lista[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '🔍 Buscar material, código...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: AppColors.backgroundGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchController.clear();
                      context.read<ProductoProvider>().buscarProductos('');
                    })
                        : null,
                  ),
                  onChanged: (val) => context.read<ProductoProvider>().buscarProductos(val),
                ),
              ),
              const SizedBox(width: 8),
              // ✅ BOTÓN DE RECARGA
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  tooltip: "Actualizar Stock",
                  onPressed: _recargarTodo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', 'todos'),
                const SizedBox(width: 8),
                _buildFilterChip('⚠️ Reponer', 'bajo', color: AppColors.warning),
                const SizedBox(width: 8),
                _buildFilterChip('🚫 Agotados', 'sin_stock', color: AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... Resto de widgets (_buildFilterChip, _buildEmptyState, _buildSmartStockCard, _QuickActionSheet, _RegistroMovimientoDialog)
  // (Se mantienen idénticos al código anterior que ya funcionaba bien, solo cambiamos el build principal y el searchbar)

  Widget _buildFilterChip(String label, String value, {Color? color}) {
    final selected = _filtroEstado == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87)),
      selected: selected,
      onSelected: (_) => setState(() => _filtroEstado = value),
      backgroundColor: Colors.white,
      selectedColor: color ?? AppColors.primary,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: () async => _recargarTodo(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: const Center(child: Text('No se encontraron materiales', style: TextStyle(color: Colors.grey))),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartStockCard(BuildContext context, ProductoModel p) {
    Color color = AppColors.success;
    IconData icon = Icons.check_circle_outline;
    if (p.sinStock) { color = AppColors.error; icon = Icons.error_outline; }
    else if (p.stockBajo) { color = AppColors.warning; icon = Icons.warning_amber_rounded; }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarSheetRapido(context, p),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 6)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${p.codigo} • ${p.categoriaNombre ?? "Gral"}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(p.cantidadFormateada, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  Text(p.unidadBase, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarSheetRapido(BuildContext context, ProductoModel p) {
    final usuario = context.read<AuthProvider>().usuario;
    final puedeMoverStock = usuario?.tienePermiso(AppRoles.gestionarStock) ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _QuickActionSheet(producto: p, puedeEditar: puedeMoverStock),
    );
  }
}

class _QuickActionSheet extends StatefulWidget {
  final ProductoModel producto;
  final bool puedeEditar;

  const _QuickActionSheet({required this.producto, required this.puedeEditar});

  @override
  State<_QuickActionSheet> createState() => _QuickActionSheetState();
}

class _QuickActionSheetState extends State<_QuickActionSheet> {
  bool _cargando = true;
  List<MovimientoStock> _ultimos = [];

  @override
  void initState() {
    super.initState();
    _cargarMiniHistorial();
  }

  Future<void> _cargarMiniHistorial() async {
    try {
      await context.read<MovimientoStockProvider>().cargarMovimientosDeProducto(widget.producto.codigo);
      if (mounted) {
        setState(() {
          _ultimos = context.read<MovimientoStockProvider>().movimientos.take(3).toList();
          _cargando = false;
        });
      }
    } catch (_) { if(mounted) setState(() => _cargando = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Row(
            children: [
              Expanded(child: Text(widget.producto.nombre, style: AppTextStyles.h3)),
              Text('${widget.producto.cantidadFormateada} ${widget.producto.unidadBase}', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
            ],
          ),
          const Divider(height: 30),
          if (widget.puedeEditar)
            Row(
              children: [
                Expanded(child: _botonAccion(Icons.add, 'ENTRADA', Colors.green, () => _abrirDialogoRegistro(context, TipoMovimiento.entrada))),
                const SizedBox(width: 15),
                Expanded(child: _botonAccion(Icons.remove, 'SALIDA', Colors.red, () => _abrirDialogoRegistro(context, TipoMovimiento.salida))),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Últimos Movimientos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MovimientoHistorialPage(productoId: widget.producto.codigo)));
                },
                child: const Text('Ver Todo'),
              )
            ],
          ),
          if (_cargando) const LinearProgressIndicator()
          else ..._ultimos.map((m) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(m.tipo == TipoMovimiento.entrada ? Icons.arrow_downward : Icons.arrow_upward, color: m.tipo == TipoMovimiento.entrada ? Colors.green : Colors.red, size: 16),
            title: Text("${m.tipo.name.toUpperCase()} ${m.cantidad}"),
            subtitle: Text(m.obraNombre != null ? "Obra: ${m.obraNombre}" : (m.motivo ?? '-')),
            trailing: Text("${m.createdAt.day}/${m.createdAt.month}", style: const TextStyle(fontSize: 10)),
          ))
        ],
      ),
    );
  }

  Widget _botonAccion(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.1), foregroundColor: color, elevation: 0),
      icon: Icon(icon), label: Text(label),
    );
  }

  void _abrirDialogoRegistro(BuildContext sheetContext, TipoMovimiento tipo) {
    final stockProvider = sheetContext.read<MovimientoStockProvider>();
    final prodProvider = sheetContext.read<ProductoProvider>();
    final obraProvider = sheetContext.read<ObraProvider>();

    Navigator.pop(sheetContext);

    showDialog(
      context: sheetContext,
      builder: (dialogCtx) => _RegistroMovimientoDialog(
        tipo: tipo,
        producto: widget.producto,
        stockProvider: stockProvider,
        prodProvider: prodProvider,
        obraProvider: obraProvider,
      ),
    );
  }
}

class _RegistroMovimientoDialog extends StatefulWidget {
  final TipoMovimiento tipo;
  final ProductoModel producto;
  final MovimientoStockProvider stockProvider;
  final ProductoProvider prodProvider;
  final ObraProvider obraProvider;

  const _RegistroMovimientoDialog({
    required this.tipo,
    required this.producto,
    required this.stockProvider,
    required this.prodProvider,
    required this.obraProvider,
  });

  @override
  State<_RegistroMovimientoDialog> createState() => _RegistroMovimientoDialogState();
}

class _RegistroMovimientoDialogState extends State<_RegistroMovimientoDialog> {
  final _cantCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  ObraModel? _obraSeleccionada;

  @override
  Widget build(BuildContext context) {
    final obras = widget.obraProvider.obras;

    return AlertDialog(
      title: Text('Registrar ${widget.tipo.name.toUpperCase()}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Material: ${widget.producto.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextField(
              controller: _cantCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<ObraModel>(
              value: _obraSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Asociar a Obra (Opcional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text("Ninguna / General")),
                ...obras.map((o) => DropdownMenuItem(value: o, child: Text(o.nombre, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => setState(() => _obraSeleccionada = v),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _motivoCtrl,
              decoration: const InputDecoration(labelText: 'Motivo / Comentario', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            final cant = double.tryParse(_cantCtrl.text);
            if (cant == null || cant <= 0) return;

            final exito = await widget.stockProvider.registrarMovimiento(
              productoId: widget.producto.codigo,
              productoNombre: widget.producto.nombre,
              tipo: widget.tipo,
              cantidad: cant,
              motivo: _motivoCtrl.text.isEmpty ? 'Ajuste rápido' : _motivoCtrl.text,
              obraId: _obraSeleccionada?.codigo,
              obraNombre: _obraSeleccionada?.nombre,
            );

            if (exito && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Movimiento registrado")));
              widget.prodProvider.cargarProductos();
            }
          },
          child: const Text('CONFIRMAR'),
        )
      ],
    );
  }
}