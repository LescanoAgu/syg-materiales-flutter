import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import 'movimiento_registro_page.dart';
import 'producto_detalle_page.dart';

class StockPage extends StatefulWidget {
  final bool esNavegacionPrincipal;
  const StockPage({super.key, this.esNavegacionPrincipal = false});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final TextEditingController _searchController = TextEditingController();
  String _categoriaSeleccionada = 'TODAS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ProductoProvider>();
      prov.cargarProductos(recargar: true);
      prov.cargarCategorias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.esNavegacionPrincipal ? null : AppBar(
        title: const Text("Stock Físico"), // Nombre más claro
        backgroundColor: AppColors.primary,
        // ❌ SIN BOTÓN DE AGREGAR AQUÍ (Eso va en Admin)
      ),
      drawer: widget.esNavegacionPrincipal ? const AppDrawer() : null,
      body: Column(
        children: [
          // 1. BUSCADOR
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.primary,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Consultar disponibilidad...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                context.read<ProductoProvider>().buscarProductos(val);
              },
            ),
          ),

          // 2. FILTROS
          Consumer<ProductoProvider>(
            builder: (ctx, prov, _) {
              final categorias = ['TODAS', ...prov.categorias.map((c) => c.nombre)];
              return SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: categorias.length,
                  separatorBuilder: (_,__) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final cat = categorias[i];
                    final isSelected = _categoriaSeleccionada == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _categoriaSeleccionada = cat),
                      selectedColor: AppColors.secondary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    );
                  },
                ),
              );
            },
          ),

          // 3. LISTA
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());

                List<ProductoModel> lista = provider.productos;
                if (_categoriaSeleccionada != 'TODAS') {
                  lista = lista.where((p) => p.categoriaNombre == _categoriaSeleccionada).toList();
                }

                if (lista.isEmpty) return const Center(child: Text("Sin resultados"));

                return ListView.separated(
                  itemCount: lista.length,
                  separatorBuilder: (_,__) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _buildProductoItem(lista[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.swap_horiz),
        label: const Text("MOVER STOCK"),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MovimientoRegistroPage()));
        },
      ),
    );
  }

  Widget _buildProductoItem(ProductoModel p) {
    Color colorStock = Colors.green;
    if (p.cantidadDisponible <= 0) colorStock = Colors.red;
    else if (p.cantidadDisponible < 10) colorStock = Colors.orange;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorStock.withValues(alpha: 0.1),
        child: Text(
          p.unidadBase.isNotEmpty ? p.unidadBase.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(color: colorStock, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("${p.codigo} • ${p.categoriaNombre ?? ''}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            p.cantidadFormateada,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorStock),
          ),
          const SizedBox(width: 4),
          Text(p.unidadBase, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
      onTap: () {
        // Al tocar, vamos al detalle para ver historial, PERO NO A EDITAR
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductoDetallePage(producto: p)),
        );
      },
    );
  }
}