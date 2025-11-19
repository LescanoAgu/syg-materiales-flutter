import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import 'movimiento_registro_page.dart';
import 'producto_detalle_page.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});
  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Stock & Inventario')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => context.read<ProductoProvider>().buscarProductos(val),
            ),
          ),
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.productos.isEmpty) return const Center(child: Text('Sin productos'));

                return ListView.builder(
                  itemCount: provider.productos.length,
                  itemBuilder: (ctx, i) => _buildCard(provider.productos[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MovimientoRegistroPage()))
            .then((_) => context.read<ProductoProvider>().cargarProductos()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCard(ProductoConStock p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: p.stockBajo ? AppColors.warning : AppColors.success,
          child: Text(p.cantidadFormateada, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: Text(p.nombre),
        subtitle: Text('${p.codigo} - ${p.categoriaNombre ?? ""}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _ajustarStock(p),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoDetallePage(producto: p))),
      ),
    );
  }

  void _ajustarStock(ProductoConStock p) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MovimientoRegistroPage(productoInicial: p)))
        .then((_) => context.read<ProductoProvider>().cargarProductos());
  }
}