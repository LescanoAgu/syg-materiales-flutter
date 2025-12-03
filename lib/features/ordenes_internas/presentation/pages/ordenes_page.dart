import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/orden_interna_provider.dart';
import '../../data/models/orden_interna_model.dart';
import 'orden_detalle_page.dart';
import 'orden_form_page.dart';

class OrdenesPage extends StatefulWidget {
  final bool esNavegacionPrincipal;
  const OrdenesPage({super.key, this.esNavegacionPrincipal = false});

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
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
      appBar: widget.esNavegacionPrincipal ? null : AppBar(title: const Text("Estado de Pedidos")),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("NUEVA SOLICITUD"),
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdenFormPage()))
            .then((_) => context.read<OrdenInternaProvider>().cargarOrdenes()),
      ),
      body: Column(
        children: [
          if (widget.esNavegacionPrincipal)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
              ),
              child: const Text(
                "Seguimiento de Órdenes",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),

          Expanded(
            child: Consumer<OrdenInternaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.ordenes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No hay órdenes registradas", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.ordenes.length,
                  itemBuilder: (ctx, i) {
                    final detalle = provider.ordenes[i];
                    return _buildOrdenCard(detalle);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenCard(OrdenInternaDetalle detalle) {
    final orden = detalle.orden;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrdenDetallePage(ordenResumen: detalle))
        ).then((_) => context.read<OrdenInternaProvider>().cargarOrdenes()),

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Información Principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO (Si existe)
                    if (orden.titulo != null && orden.titulo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(orden.titulo!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),

                    Row(
                      children: [
                        Text(orden.numero, style: TextStyle(fontWeight: FontWeight.bold, fontSize: orden.titulo == null ? 16 : 14)),
                        if (orden.prioridad == 'urgente')
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.local_fire_department, color: Colors.red, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(orden.solicitanteNombre, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text("${detalle.cantidadProductos} productos • ${orden.obraNombre ?? 'Sin obra'}",
                        style: const TextStyle(fontSize: 12, color: Colors.black54)
                    ),
                  ],
                ),
              ),

              // Estado y Acciones
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _getColorEstado(orden.estado).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getColorEstado(orden.estado))
                    ),
                    child: Text(
                      orden.estado.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: _getColorEstado(orden.estado)
                      ),
                    ),
                  ),

                  // BOTÓN EDITAR (Solo si está solicitada)
                  if (orden.estado == 'solicitado')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              side: BorderSide(color: Colors.grey.shade400)
                          ),
                          onPressed: () async {
                            // Cargar detalle completo antes de editar
                            final provider = context.read<OrdenInternaProvider>();
                            // Mostrar loading breve
                            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                            final detalleFull = await provider.cargarDetalleOrden(orden.id!);

                            if (context.mounted) {
                              Navigator.pop(context); // Cerrar loading
                              if (detalleFull != null) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => OrdenFormPage(ordenParaEditar: detalleFull))
                                ).then((_) => provider.cargarOrdenes());
                              }
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 12, color: Colors.grey),
                              SizedBox(width: 4),
                              Text("Editar", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'entregado': return Colors.green;
      case 'aprobado': return Colors.blue;
      case 'en_curso': return Colors.orange;
      case 'solicitado': return Colors.grey;
      default: return Colors.black;
    }
  }
}