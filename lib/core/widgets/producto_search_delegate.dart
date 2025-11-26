import 'package:flutter/material.dart';
import '../../features/stock/data/models/producto_model.dart';

class ProductoSearchDelegate extends SearchDelegate<ProductoModel?> {
  final List<ProductoModel> productos;

  ProductoSearchDelegate(this.productos);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
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
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    // Lógica de filtrado potente: Nombre, Código o Categoría
    final resultados = query.isEmpty
        ? productos
        : productos.where((p) {
      final q = query.toLowerCase();
      return p.nombre.toLowerCase().contains(q) ||
          p.codigo.toLowerCase().contains(q) ||
          (p.categoriaNombre?.toLowerCase().contains(q) ?? false);
    }).toList();

    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (context, index) {
        final p = resultados[index];
        return ListTile(
          leading: CircleAvatar(child: Text(p.codigo.split('-').last)),
          title: Text(p.nombre),
          subtitle: Text('${p.codigo} - ${p.categoriaNombre ?? "Gral"}'),
          trailing: Text('${p.cantidadFormateada} ${p.unidadBase}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => close(context, p),
        );
      },
    );
  }
}