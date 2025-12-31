import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/stock/data/models/producto_model.dart';
import '../../features/stock/presentation/providers/producto_provider.dart';
import '../../features/stock/presentation/pages/producto_form_page.dart'; // Si lo usas para editar al tocar

class ProductoSearchDelegate extends SearchDelegate<ProductoModel?> {

  @override
  String get searchFieldLabel => 'Buscar producto...';

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
    // Reutilizamos la misma vista de sugerencias para los resultados
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // 1. Obtenemos el provider (usamos watch para que si cambia la lista de fondo, se actualice)
    final provider = context.watch<ProductoProvider>();

    // 2. Accedemos a la lista completa (asegúrate que tu provider devuelva la lista llena si no hay query en el provider)
    // Como no llamamos a 'buscarProductos' del provider, el provider tiene _searchQuery vacío,
    // por lo tanto provider.productos debería devolver TODO.
    final listaCompleta = provider.productos;

    // 3. Filtramos LOCALMENTE (Esto evita el error de setState durante build)
    final filtro = query.isEmpty
        ? <ProductoModel>[] // O listaCompleta si quieres mostrar todo al inicio
        : listaCompleta.where((p) {
      final q = query.toLowerCase();
      return p.nombre.toLowerCase().contains(q) ||
          p.codigo.toLowerCase().contains(q) ||
          (p.categoriaNombre != null && p.categoriaNombre!.toLowerCase().contains(q));
    }).toList();

    if (filtro.isEmpty && query.isNotEmpty) {
      return const Center(child: Text("No se encontraron productos"));
    }

    return ListView.separated(
      itemCount: filtro.length,
      separatorBuilder: (_,__) => const Divider(),
      itemBuilder: (context, index) {
        final producto = filtro[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(producto.codigo.isNotEmpty ? producto.codigo[0] : '?',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          title: Text(producto.nombre),
          subtitle: Text("${producto.codigo} - ${producto.categoriaNombre ?? 'Gral'}"),
          trailing: Text("\$${producto.precioSinIva ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {
            // Devolvemos el producto seleccionado
            close(context, producto);
          },
        );
      },
    );
  }
}