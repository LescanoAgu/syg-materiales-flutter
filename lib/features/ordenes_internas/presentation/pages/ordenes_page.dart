import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/orden_interna_provider.dart';
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
    // Carga inicial de datos
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
          // Encabezado simple
          if (widget.esNavegacionPrincipal)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.white,
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
                        ),
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
                                    Row(
                                      children: [
                                        Text(orden.numero, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (orden.prioridad == 'urgente')
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Icon(Icons.local_fire_department, color: Colors.red, size: 18),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(orden.solicitanteNombre, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text("${detalle.cantidadProductos} productos • ${orden.obraNombre ?? 'Sin obra'}",
                                        style: const TextStyle(fontSize: 12, color: Colors.black54)
                                    ),
                                  ],
                                ),
                              ),

                              // Badge de Estado
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
                                      fontSize: 11,
                                      color: _getColorEstado(orden.estado)
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
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

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'entregado': return Colors.green;
      case 'aprobado': return Colors.blue;
      case 'en_curso': return Colors.orange; // En camino
      case 'solicitado': return Colors.grey;
      default: return Colors.black;
    }
  }
}