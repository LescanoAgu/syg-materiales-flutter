import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../../../features/stock/presentation/pages/stock_page.dart'; // Importar Home
import 'orden_form_page.dart';
import 'orden_detalle_page.dart';

class OrdenesPage extends StatefulWidget {
  const OrdenesPage({super.key});
  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrdenInternaProvider>().cargarOrdenes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📋 Órdenes Internas'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        // ✅ Botón atrás al Home
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StockPage())),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<OrdenInternaProvider>().cargarOrdenes())],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdenFormPage())).then((_) => context.read<OrdenInternaProvider>().cargarOrdenes()),
        icon: const Icon(Icons.add), label: const Text('Nueva Orden'),
      ),
      body: Consumer<OrdenInternaProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          if (!prov.hasData) return const Center(child: Text('Sin órdenes'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prov.ordenes.length,
            itemBuilder: (ctx, i) => _buildCard(prov.ordenes[i]),
          );
        },
      ),
    );
  }

  Widget _buildCard(OrdenInternaDetalle od) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Padding interno
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${od.orden.numero}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                child: Text(od.orden.estado.toUpperCase(), style: const TextStyle(fontSize: 10)),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // ✅ SNEAK PEAK
              Row(children: [const Icon(Icons.business, size: 14), const SizedBox(width: 4), Expanded(child: Text(od.clienteRazonSocial, overflow: TextOverflow.ellipsis))]),
              Row(children: [const Icon(Icons.location_city, size: 14), const SizedBox(width: 4), Expanded(child: Text(od.obraNombre ?? 'Sin obra', overflow: TextOverflow.ellipsis))]),
              Row(children: [const Icon(Icons.person, size: 14), const SizedBox(width: 4), Expanded(child: Text('Solicita: ${od.orden.solicitanteNombre}', overflow: TextOverflow.ellipsis))]),
            ],
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdenDetallePage(ordenResumen: od))),
        ),
      ),
    );
  }
  void _borrar(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Orden'),
        content: const Text('¿Estás seguro? Se borrarán los items asociados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              context.read<OrdenInternaProvider>().eliminarOrden(id);
              Navigator.pop(ctx);
            },
            child: const Text('BORRAR'),
          )
        ],
      ),
    );
  }
}