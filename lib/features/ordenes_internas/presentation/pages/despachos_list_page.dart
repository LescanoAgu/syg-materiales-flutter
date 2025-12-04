// UBICACIÓN: lib/features/ordenes_internas/presentation/pages/despachos_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
import 'orden_despacho_page.dart';

class DespachosListPage extends StatefulWidget {
  final bool esNavegacionPrincipal; // Para saber si mostrar AppBar/Drawer
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
    // Si está embebida en el Home del Pañolero, no usamos Scaffold completo
    final bool mostrarAppBar = !widget.esNavegacionPrincipal;

    Widget content = Consumer<OrdenInternaProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        // Filtramos lo que requiere acción logística
        final despachosPendientes = provider.ordenes.where((d) {
          final e = d.orden.estado;
          return e == 'aprobado' || e == 'en_curso';
        }).toList();

        if (despachosPendientes.isEmpty) return _buildEmptyState();

        return RefreshIndicator(
          onRefresh: () => context.read<OrdenInternaProvider>().cargarOrdenes(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: despachosPendientes.length,
            separatorBuilder: (_,__) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _buildDespachoCard(despachosPendientes[i]),
          ),
        );
      },
    );

    if (mostrarAppBar) {
      return Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Área de Despacho'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<OrdenInternaProvider>().cargarOrdenes(),
            )
          ],
        ),
        body: content,
      );
    } else {
      return Container(
        color: AppColors.background,
        child: content,
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("¡Todo despachado!", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("No hay órdenes pendientes de entrega.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDespachoCard(OrdenInternaDetalle resumen) {
    final orden = resumen.orden;
    final esUrgente = orden.prioridad == 'urgente';
    final esParcial = orden.estado == 'en_curso';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: esUrgente ? Colors.red.withOpacity(0.5) : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navegarADespacho(orden.id!),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Estado y Prioridad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: esParcial ? Colors.blue[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: esParcial ? Colors.blue : Colors.green),
                    ),
                    child: Text(
                      esParcial ? "PARCIAL / EN CURSO" : "NUEVO PARA ARMAR",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: esParcial ? Colors.blue[800] : Colors.green[800]
                      ),
                    ),
                  ),
                  if (esUrgente)
                    Row(
                      children: const [
                        Icon(Icons.warning, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Text("URGENTE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Título y Obra
              Text(
                resumen.obraNombre?.toUpperCase() ?? "SIN OBRA",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text("Cliente: ${resumen.clienteRazonSocial}"),

              const Divider(height: 20),

              // Footer: Resumen Items
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text("${resumen.cantidadProductos} items pedidos"),
                  const Spacer(),
                  const Text("Tocar para despachar", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navegarADespacho(String ordenId) async {
    // Feedback visual de carga
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator())
    );

    final provider = context.read<OrdenInternaProvider>();
    final detalleCompleto = await provider.cargarDetalleOrden(ordenId);

    if (mounted) {
      Navigator.pop(context); // Cerrar loading

      if (detalleCompleto != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrdenDespachoPage(ordenDetalle: detalleCompleto)),
        ).then((_) => provider.cargarOrdenes());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error cargando orden"), backgroundColor: Colors.red));
      }
    }
  }
}