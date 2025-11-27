import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart'; // Asegúrate que esta ruta sea correcta en tu proyecto
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import 'movimiento_registro_page.dart';
import 'producto_detalle_page.dart';
import 'movimiento_historial_page.dart'; // ✅ IMPORT QUE FALTABA

class StockPage extends StatefulWidget {
  const StockPage({super.key});
  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _ocultarCeros = true;

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
      appBar: AppBar(
        title: const Text('Stock & Inventario'),
        actions: [
          Row(
            children: [
              const Text('Ocultar 0', style: TextStyle(fontSize: 12)),
              Switch(
                value: _ocultarCeros,
                onChanged: (v) => setState(() => _ocultarCeros = v),
                activeColor: Colors.white,
              ),
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MovimientoRegistroPage()))
            .then((_) => context.read<ProductoProvider>().cargarProductos()),
        child: const Icon(Icons.swap_horiz),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Buscar...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (val) => context.read<ProductoProvider>().buscarProductos(val),
            ),
          ),
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());

                final lista = _ocultarCeros
                    ? provider.productos.where((p) => p.cantidadDisponible != 0).toList()
                    : provider.productos;

                if (lista.isEmpty) return const Center(child: Text('Sin productos en stock'));

                return ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (ctx, i) => _buildCard(lista[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ProductoModel p) {
    Color colorStock;
    if (p.cantidadDisponible <= 0) {
      colorStock = Colors.grey;
    } else if (p.cantidadDisponible < 10) {
      colorStock = Colors.orange;
    } else {
      colorStock = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorStock,
          child: Text(p.cantidadFormateada, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        title: Text(p.nombre),
        subtitle: Text(p.codigo),
        trailing: IconButton(
          icon: const Icon(Icons.history, color: Colors.blue),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovimientoHistorialPage(productoId: p.codigo))),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoDetallePage(producto: p))),
      ),
    );
  }
}