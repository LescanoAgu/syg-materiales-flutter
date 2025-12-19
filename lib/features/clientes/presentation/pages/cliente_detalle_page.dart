import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/cliente_model.dart';
import '../../../acopios/presentation/providers/acopio_provider.dart';
import '../../../ordenes_internas/presentation/pages/orden_form_page.dart';

class ClienteDetallePage extends StatefulWidget {
  final ClienteModel cliente;
  const ClienteDetallePage({super.key, required this.cliente});

  @override
  State<ClienteDetallePage> createState() => _ClienteDetallePageState();
}

class _ClienteDetallePageState extends State<ClienteDetallePage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ Solución segura para String?
      final codigoSeguro = widget.cliente.codigo;
      context.read<AcopioProvider>().cargarAcopiosDeCliente(codigoSeguro);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.cliente.razonSocial),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ CORRECCIÓN: Quitamos 'const' porque AppTextStyles.h2 podría no ser constante
                Text("Billetera de Materiales", style: AppTextStyles.h2),

                Chip(
                  label: const Text("Saldo a Favor"),
                  backgroundColor: AppColors.success,
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
              ],
            ),
            const SizedBox(height: 12),

            _buildListaAcopio(),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4
                ),
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text("GENERAR RETIRO DE MATERIAL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrdenFormPage(
                        preSelectedClienteId: widget.cliente.codigo,
                        esRetiroAcopio: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    String inicial = "?";
    if (widget.cliente.razonSocial.isNotEmpty) {
      inicial = widget.cliente.razonSocial.substring(0, 1).toUpperCase();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary,
                  child: Text(inicial, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.cliente.razonSocial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("CUIT: ${widget.cliente.cuit ?? '-'}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.email, "Contacto", widget.cliente.email),
                _buildStatItem(Icons.phone, "Teléfono", widget.cliente.telefono),
                _buildStatItem(Icons.location_on, "Dirección", widget.cliente.direccion),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String? value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildListaAcopio() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        final items = provider.itemsDeCliente;

        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text("Este cliente no tiene materiales acopiados.", style: TextStyle(color: Colors.grey))),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            return Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: const Icon(Icons.inventory_2, color: AppColors.success, size: 20),
                ),
                title: Text(item.nombreProducto, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  "${item.cantidadDisponible} ${item.unidad}",
                  // ✅ CORRECCIÓN: Quitamos 'const' por seguridad si AppColors no es constante
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
            );
          },
        );
      },
    );
  }
}