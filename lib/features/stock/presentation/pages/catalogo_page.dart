import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/producto_provider.dart';
import '../../../../core/widgets/app_drawer.dart';
import 'producto_detalle_page.dart';

class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Cargar al iniciar (usando un FutureBuilder o PostFrameCallback en un StatefulWidget sería mejor, pero esto sirve)
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProductoProvider>().cargarProductos());

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Catálogo')),
      body: Consumer<ProductoProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: provider.productos.length,
            itemBuilder: (c, i) {
              final p = provider.productos[i];
              return Card(
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoDetallePage(producto: p))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${p.precioSinIva ?? '-'}'),
                      Text('Stock: ${p.cantidadFormateada}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}