import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
import 'orden_despacho_page.dart';

class DespachosListPage extends StatefulWidget {
  final bool esNavegacionPrincipal;
  const DespachosListPage({super.key, this.esNavegacionPrincipal = false});

  @override
  State<DespachosListPage> createState() => _DespachosListPageState();
}

class _DespachosListPageState extends State<DespachosListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdenInternaProvider>().cargarOrdenes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.esNavegacionPrincipal
          ? null
          : AppBar(title: const Text("Centro de Despacho"), backgroundColor: Colors.deepOrange),
      body: Consumer<OrdenInternaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtramos solo Aprobadas o En Proceso
          final ordenesDespachables = provider.ordenes.where((detalle) {
            final estado = detalle.orden.estado;
            return estado == 'aprobada' || estado == 'en_proceso';
          }).toList();

          if (ordenesDespachables.isEmpty) {
            return const Center(child: Text("No hay órdenes pendientes de despacho"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ordenesDespachables.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildOrdenCard(ordenesDespachables[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrdenCard(OrdenInternaDetalle detalle) {
    final orden = detalle.orden;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navegarADespacho(orden.id!),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      "Orden #${orden.numero}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("LISTO PARA DESPACHAR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(detalle.clienteRazonSocial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text("Obra: ${detalle.obraNombre ?? 'N/A'}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text("Tocar para gestionar entrega", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.deepOrange),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navegarADespacho(String ordenId) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator())
    );

    final provider = context.read<OrdenInternaProvider>();
    await provider.cargarDetalleOrden(ordenId);
    final detalle = provider.ordenSeleccionada;

    if (mounted) {
      Navigator.pop(context);
      if (detalle != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrdenDespachoPage(ordenDetalle: detalle)),
        ).then((res) {
          if (res == true) provider.cargarOrdenes();
        });
      }
    }
  }
}