import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import 'movimiento_registro_page.dart';
import 'producto_detalle_page.dart';
// import 'movimiento_historial_page.dart'; // ✅ Comentado si no se usa, descomentar si hay botón

class StockPage extends StatefulWidget {
  final bool esNavegacionPrincipal;
  const StockPage({super.key, this.esNavegacionPrincipal = false});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _ocultarCeros = true;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _buildBody();
    if (widget.esNavegacionPrincipal) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Stock & Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductoProvider>().cargarProductos(recargar: true),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "stock_fab",
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MovimientoRegistroPage()))
            .then((_) => context.read<ProductoProvider>().cargarProductos()),
        child: const Icon(Icons.swap_horiz, color: Colors.white),
      ),
      body: content,
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: AppColors.primary,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Buscar material, código...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () {
                _searchController.clear();
                context.read<ProductoProvider>().buscarProductos('');
              })
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
            onChanged: (val) => context.read<ProductoProvider>().buscarProductos(val),
          ),
        ),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.background,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Todos', 'todos'),
              const SizedBox(width: 8),
              _buildFilterChip('⚠️ Bajo Stock', 'bajo'),
              const SizedBox(width: 8),
              _buildFilterChip('🚫 Sin Stock', 'sin_stock'),
            ],
          ),
        ),
        Expanded(
          child: Consumer<ProductoProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) return const Center(child: CircularProgressIndicator());
              List<ProductoModel> lista = provider.productos;
              if (_filtroEstado == 'bajo') {
                lista = lista.where((p) => p.stockBajo).toList();
              } else if (_filtroEstado == 'sin_stock') {
                lista = lista.where((p) => p.sinStock).toList();
              } else if (_ocultarCeros) {
                lista = lista.where((p) => p.cantidadDisponible != 0).toList();
              }

              if (lista.isEmpty) {
                return const Center(child: Text('No se encontraron productos', style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80, top: 8),
                itemCount: lista.length,
                itemBuilder: (ctx, i) => _buildStockCard(lista[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filtroEstado == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool v) => setState(() => _filtroEstado = value),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildStockCard(ProductoModel p) {
    Color colorBarra;
    if (p.sinStock) colorBarra = AppColors.error;
    else if (p.stockBajo) colorBarra = AppColors.warning;
    else colorBarra = AppColors.success;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoDetallePage(producto: p))),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: colorBarra, width: 6)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Colors.grey[100],
                child: Text(p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${p.codigo} • ${p.categoriaNombre ?? ""}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(p.cantidadFormateada, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(p.unidadBase, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}