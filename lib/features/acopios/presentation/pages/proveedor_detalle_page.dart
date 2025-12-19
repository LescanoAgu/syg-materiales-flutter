import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/proveedor_model.dart';
// Eliminamos import de acopio_model ya que no lo usaremos para filtrar por proveedor directamente en este modelo simplificado

class ProveedorDetallePage extends StatelessWidget {
  final ProveedorModel proveedor;

  const ProveedorDetallePage({super.key, required this.proveedor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(proveedor.nombre),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Información
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.business,
                        color: AppColors.primary,
                      ),
                      title: const Text("Razón Social"),
                      subtitle: Text(proveedor.nombre),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.phone,
                        color: AppColors.primary,
                      ),
                      title: const Text("Teléfono"),
                      subtitle: Text(
                        (proveedor.telefono?.isNotEmpty ?? false)
                            ? proveedor.telefono!
                            : "-",
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.email,
                        color: AppColors.primary,
                      ),
                      title: const Text("Email"),
                      subtitle: Text(
                        (proveedor.email?.isNotEmpty ?? false)
                            ? proveedor.email!
                            : "-",
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                      title: const Text("Dirección"),
                      subtitle: Text(
                        (proveedor.direccion?.isNotEmpty ?? false)
                            ? proveedor.direccion!
                            : "-",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sección temporal hasta implementar historial de ingresos detallado
            const Center(
              child: Text(
                "El historial de compras se implementará próximamente.",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
