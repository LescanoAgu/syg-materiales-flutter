import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/stock/data/models/producto_model.dart';
import '../../features/stock/presentation/providers/producto_provider.dart';
import '../../core/constants/app_colors.dart';

class ProductoSearchDelegate extends SearchDelegate<ProductoModel?> {

  @override
  String get searchFieldLabel => 'Buscar material...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _realizarBusqueda(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text("Escribe al menos 2 letras", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return _realizarBusqueda(context);
  }

  Widget _realizarBusqueda(BuildContext context) {
    final provider = context.read<ProductoProvider>();

    // ✅ SOLUCIÓN: Usamos FutureBuilder para manejar el Future<void>
    return FutureBuilder(
      future: provider.buscarProductos(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Consumer<ProductoProvider>(
          builder: (ctx, prov, _) {
            final resultados = prov.productos;

            if (resultados.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text('No se encontró "$query"', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: resultados.length,
              separatorBuilder: (_,__) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = resultados[index];
                Color colorStock = p.cantidadDisponible > 0 ? Colors.green : Colors.red;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorStock.withValues(alpha: 0.1),
                    child: Text(
                      p.unidadBase.isNotEmpty ? p.unidadBase.substring(0, 1).toUpperCase() : 'U',
                      style: TextStyle(color: colorStock, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${p.codigo} • ${p.categoriaNombre ?? "Gral"}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          p.cantidadFormateada,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorStock)
                      ),
                      Text(p.unidadBase, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  onTap: () => close(context, p),
                );
              },
            );
          },
        );
      },
    );
  }
}