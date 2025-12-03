import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
import 'orden_despacho_page.dart';
import '../../../../core/widgets/main_layout.dart';

class DespachosListPage extends StatefulWidget {
  const DespachosListPage({super.key});
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
      drawer: const AppDrawer(currentSection: AppSection.ordenes),
      appBar: AppBar(
        title: const Text('Área de Despacho'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OrdenInternaProvider>().cargarOrdenes(),
          )
        ],
      ),
      body: Consumer<OrdenInternaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          final despachosPendientes = provider.ordenes.where((d) {
            final e = d.orden.estado;
            return e == 'aprobado' || e == 'en_curso';
          }).toList();

          if (despachosPendientes.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: despachosPendientes.length,
            itemBuilder: (ctx, i) => _buildDespachoCard(despachosPendientes[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No hay órdenes pendientes de despacho", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDespachoCard(OrdenInternaDetalle resumen) {
    final orden = resumen.orden;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navegarADespacho(resumen.orden.id!), // ✅ LLAMADA CORREGIDA
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TÍTULO (Si existe) o Cliente
              if (orden.titulo != null && orden.titulo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(orden.titulo!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resumen.clienteRazonSocial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(resumen.obraNombre ?? "Sin Obra", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(orden.numero, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Resp: ${orden.solicitanteNombre}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Row(children: [
                    Icon(Icons.touch_app, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text("Tocar para despachar", style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold))
                  ])
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navegarADespacho(String ordenId) async {
    // ✅ CLAVE: Cargar el detalle completo (items) antes de navegar
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error cargando detalles de la orden")));
      }
    }
  }
}