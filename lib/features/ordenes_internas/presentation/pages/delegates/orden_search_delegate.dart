import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ✅ RUTAS CORREGIDAS PARA TU UBICACIÓN ACTUAL:
import '../../../data/models/orden_interna_model.dart'; // Retrocede: delegates > pages > presentation > ordenes_internas -> entra a data
import '../orden_detalle_page.dart'; // Retrocede: delegates > pages -> archivo hermano

class OrdenSearchDelegate extends SearchDelegate {
  final List<OrdenInternaDetalle> ordenes;

  OrdenSearchDelegate(this.ordenes);

  @override
  String get searchFieldLabel => 'Buscar por Cliente, Obra, #Orden...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
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
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.toLowerCase();

    final resultados = ordenes.where((detalle) {
      final orden = detalle.orden;

      bool matchTexto = detalle.clienteRazonSocial.toLowerCase().contains(q) ||
          (detalle.obraNombre?.toLowerCase().contains(q) ?? false) ||
          orden.numero.toLowerCase().contains(q) ||
          orden.solicitanteNombre.toLowerCase().contains(q);

      String fechaStr = DateFormat('dd/MM/yyyy').format(orden.fechaCreacion);
      bool matchFecha = fechaStr.contains(q);

      return matchTexto || matchFecha;
    }).toList();

    if (resultados.isEmpty) {
      return const Center(child: Text("No se encontraron órdenes"));
    }

    return ListView.separated(
      itemCount: resultados.length,
      separatorBuilder: (_,__) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final d = resultados[index];
        // Limpiamos la nomenclatura para la vista rápida
        final numeroLimpio = d.orden.numero.replaceAll('OI-', '');

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: Text(numeroLimpio, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          title: Text(d.clienteRazonSocial, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${d.obraNombre ?? ''} • ${DateFormat('dd/MM').format(d.orden.fechaCreacion)}"),
          trailing: Text(d.orden.estado.toUpperCase(), style: const TextStyle(fontSize: 10)),
          onTap: () {
            close(context, null);
            Navigator.push(context, MaterialPageRoute(builder: (_) => OrdenDetallePage(orden: d.orden)));
          },
        );
      },
    );
  }
}