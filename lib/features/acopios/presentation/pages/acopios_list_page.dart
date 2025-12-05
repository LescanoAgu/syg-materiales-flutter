import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/acopio_model.dart';
import '../providers/acopio_provider.dart';
import 'acopio_form_page.dart';

class AcopiosListPage extends StatefulWidget {
  const AcopiosListPage({super.key});

  @override
  State<AcopiosListPage> createState() => _AcopiosListPageState();
}

class _AcopiosListPageState extends State<AcopiosListPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Acopios Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AcopioProvider>().cargarDatos(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AcopioFormPage()),
        ).then((_) => context.read<AcopioProvider>().cargarDatos()),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('NUEVA FACTURA'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por Cliente, Obra o Factura...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() {}), // Refresca para aplicar el filtro del provider
            ),
          ),

          // Lista de Tarjetas
          Expanded(
            child: Consumer<AcopioProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());

                final lista = provider.buscar(_searchCtrl.text);

                if (lista.isEmpty) return const Center(child: Text("No hay acopios registrados"));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: lista.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildAcopioCard(lista[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcopioCard(AcopioModel acopio) {
    final progreso = acopio.porcentajeConsumido;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Etiqueta y Factura
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    acopio.etiqueta.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                  child: Text(acopio.numeroFactura, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Cliente y Proveedor
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text(acopio.clienteRazonSocial, style: const TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(acopio.proveedorNombre, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Spacer(),
                Text(ArgFormats.fecha(acopio.fechaCompra), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),

            const Divider(height: 24),

            // Resumen de Items
            ...acopio.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.productoNombre, style: const TextStyle(fontSize: 13)),
                  Text(
                    '${item.cantidadRestante.toStringAsFixed(1)} / ${item.cantidadOriginal.toStringAsFixed(1)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: item.cantidadRestante > 0 ? Colors.black : Colors.grey),
                  ),
                ],
              ),
            )),

            if (acopio.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("+ ${acopio.items.length - 3} materiales más...", style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ),

            const SizedBox(height: 12),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(progreso == 1.0 ? Colors.green : Colors.orange),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text("${(progreso * 100).toInt()}% Retirado", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}