import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdenInternaProvider>().cargarOrdenes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📋 Órdenes Internas'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        // AGREGAMOS ESTO:
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Volvemos a la pantalla principal (StockPage o HomePage)
            // Usamos pushReplacement para no dejar basura en el stack
            Navigator.pushReplacementNamed(context, '/');
            // O si no usas rutas nombradas:
            // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StockPage()));
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdenFormPage()))
        // ✅ FIX: Recargar órdenes al volver del formulario
            .then((_) => context.read<OrdenInternaProvider>().cargarOrdenes()),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Orden'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<OrdenInternaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (!provider.hasData) return const Center(child: Text("No hay órdenes"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.ordenes.length,
            itemBuilder: (context, index) {
              final ordenDetalle = provider.ordenes[index];
              // CORRECCIÓN: Pasamos el objeto OrdenInternaDetalle, no un Map
              return _buildOrdenCard(ordenDetalle);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrdenCard(OrdenInternaDetalle ordenDetalle) {
    final orden = ordenDetalle.orden;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text("${orden.numero} - ${ordenDetalle.clienteRazonSocial}"),
        subtitle: Text("Estado: ${orden.estado.toUpperCase()}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // ✅ FIX 2 & 3: Corregido el nombre del parámetro a 'ordenResumen'
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => OrdenDetallePage(ordenResumen: ordenDetalle)
              ));},
      ),
    );
  }
}