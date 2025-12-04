import 'package:flutter/material.dart';
import '../../data/models/cliente_model.dart';
import '../../../ordenes_internas/data/models/orden_interna_model.dart';
import '../../../ordenes_internas/presentation/pages/orden_detalle_page.dart';
import '../../../ordenes_internas/data/repositories/orden_interna_repository.dart'; // Necesario para instanciar repo o usa provider
import '../../../../core/utils/formatters.dart';

class ClienteDetallePage extends StatefulWidget {
  final ClienteModel cliente;
  const ClienteDetallePage({super.key, required this.cliente});

  @override
  State<ClienteDetallePage> createState() => _ClienteDetallePageState();
}

class _ClienteDetallePageState extends State<ClienteDetallePage> {
  late Future<List<OrdenInternaDetalle>> _historialFuture;

  @override
  void initState() {
    super.initState();
    // Opción rápida: Llamar al repo directamente.
    // Opción ideal: Crear un método en ClienteProvider o OrdenInternaProvider.
    _historialFuture = OrdenInternaRepository().getOrdenesPorCliente(widget.cliente.codigo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cliente.razonSocial)),
      body: Column(
        children: [
          ListTile(
            title: Text("Historial de Pedidos"),
            subtitle: Text("CUIT: ${widget.cliente.cuitFormateado}"),
            leading: const Icon(Icons.history),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<OrdenInternaDetalle>>(
              future: _historialFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error cargando historial"));
                }

                final lista = snapshot.data ?? [];
                if (lista.isEmpty) return const Center(child: Text("Sin pedidos registrados"));

                return ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (ctx, i) {
                    final d = lista[i];
                    return ListTile(
                      title: Text("${d.orden.numero} ${d.orden.titulo != null ? '- ${d.orden.titulo}' : ''}"),
                      subtitle: Text(ArgFormats.fecha(d.orden.fechaPedido)),
                      trailing: _buildEstadoBadge(d.orden.estado),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrdenDetallePage(ordenResumen: d)),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color = Colors.grey;
    if (estado == 'entregado') color = Colors.green;
    if (estado == 'aprobado') color = Colors.blue;
    if (estado == 'en_curso') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(estado.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}