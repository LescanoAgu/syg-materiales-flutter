import 'package:flutter/material.dart';
// ✅ CORRECCIÓN: Rutas ajustadas
import '../../../../../core/constants/app_colors.dart';
import '../../../../ordenes_internas/presentation/pages/ordenes_page.dart';
import '../../../../ordenes_internas/presentation/pages/despachos_list_page.dart';
import '../../../../ordenes_internas/presentation/pages/orden_form_page.dart';

class PedidosMenuPage extends StatelessWidget {
  const PedidosMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pedidos y Entregas"), backgroundColor: Colors.orange),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
              context,
              "Nuevo Pedido", "Solicitar materiales", Icons.add_shopping_cart,
              const OrdenFormPage()
          ),
          const Divider(),
          _tile(
              context,
              "Listado de Órdenes", "Ver estado de solicitudes", Icons.list_alt,
              const OrdenesPage()
          ),
          const Divider(),
          _tile(
              context,
              "Centro de Despacho", "Gestionar entregas y firmas", Icons.local_shipping,
              const DespachosListPage()
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String sub, IconData icon, Widget page) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.orange.withValues(alpha: 0.1), child: Icon(icon, color: Colors.orange)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}