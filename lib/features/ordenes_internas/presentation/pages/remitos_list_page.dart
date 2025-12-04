import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart'; // Asegúrate de tener este utils o usa DateFormat directo
import '../../../../core/widgets/app_drawer.dart';
import '../providers/orden_interna_provider.dart';
import '../../../reportes/data/services/pdf_service.dart';

class RemitosListPage extends StatefulWidget {
  const RemitosListPage({super.key});

  @override
  State<RemitosListPage> createState() => _RemitosListPageState();
}

class _RemitosListPageState extends State<RemitosListPage> {
  @override
  void initState() {
    super.initState();
    // Cargamos las órdenes para extraer los remitos de ellas
    // (En una versión futura, el provider podría tener cargarSoloRemitos())
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdenInternaProvider>().cargarOrdenes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Historial de Entregas")),
      drawer: const AppDrawer(), // Menú lateral disponible
      body: Consumer<OrdenInternaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          // Filtramos solo las órdenes que tienen movimiento (En curso o Entregado)
          // Idealmente, aquí iteraríamos sobre los 'remitos' reales si tuviéramos una colección plana
          final ordenesConRemito = provider.ordenes.where((o) =>
          o.orden.estado == 'en_curso' || o.orden.estado == 'entregado'
          ).toList();

          if (ordenesConRemito.isEmpty) {
            return const Center(
              child: Text("No hay remitos generados aún", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordenesConRemito.length,
            itemBuilder: (ctx, i) {
              final detalle = ordenesConRemito[i];
              final orden = detalle.orden;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.description, color: Colors.white),
                  ),
                  title: Text(
                      "Remito Ref: ${orden.numero}",
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(
                      "${detalle.clienteRazonSocial}\n${detalle.obraNombre ?? 'Sin obra'}",
                      style: const TextStyle(fontSize: 12)
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.print, color: AppColors.primary),
                    tooltip: "Reimprimir",
                    onPressed: () {
                      // Acción rápida: Generar PDF de la orden como constancia
                      // (Si quisieras el remito específico, habría que abrir el diálogo de historial)
                      PdfService().generarOrdenInterna(detalle);
                    },
                  ),
                  onTap: () {
                    // Al tocar, podríamos ir al detalle de la orden
                    /* Navigator.push(context, MaterialPageRoute(
                      builder: (_) => OrdenDetallePage(ordenResumen: detalle))
                    ); */
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}