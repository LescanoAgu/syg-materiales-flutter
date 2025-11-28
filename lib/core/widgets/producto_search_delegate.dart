import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/stock/data/models/producto_model.dart';
import '../../features/stock/presentation/providers/producto_provider.dart';

class ProductoSearchDelegate extends SearchDelegate<ProductoModel?> {

  // ✅ Ahora NO recibe una lista fija, sino que usa el Provider dinámicamente

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
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Escribí al menos 2 letras...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // ✅ Búsqueda Asíncrona Real contra la BD
    final provider = context.read<ProductoProvider>();

    return FutureBuilder<List<ProductoModel>>(
      future: provider.buscarParaDelegate(query), // Usamos el método nuevo
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final resultados = snapshot.data ?? [];

        if (resultados.isEmpty) {
          return const Center(child: Text("No se encontraron productos"));
        }

        return ListView.separated(
          itemCount: resultados.length,
          separatorBuilder: (_,__) => const Divider(),
          itemBuilder: (context, index) {
            final p = resultados[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(p.codigo.length > 2 ? p.codigo.substring(0, 2) : 'PR'),
              ),
              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${p.codigo} - ${p.categoriaNombre ?? "Gral"}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (p.precioSinIva != null) Text('\$${p.precioSinIva}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${p.cantidadFormateada} ${p.unidadBase}'),
                ],
              ),
              onTap: () => close(context, p),
            );
          },
        );
      },
    );
  }
}