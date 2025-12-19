import 'package:flutter/material.dart';
// ✅ CORRECCIÓN: Agregamos un "../" extra a todas las rutas
import '../../../../../core/constants/app_colors.dart';
import '../../../../acopios/presentation/pages/acopios_list_page.dart';
import '../../../../acopios/presentation/pages/acopio_form_page.dart';

class AcopiosMenuPage extends StatelessWidget {
  const AcopiosMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Acopios (Billeteras)"), backgroundColor: Colors.green),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
              context,
              "Billeteras de Clientes", "Ver saldos disponibles", Icons.account_balance_wallet,
              const AcopiosListPage()
          ),
          const Divider(),
          _tile(
              context,
              "Nuevo Ingreso", "Cargar factura de compra a cliente", Icons.note_add,
              const AcopioFormPage()
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String sub, IconData icon, Widget page) {
    return ListTile(
      // ✅ Fix deprecated
      leading: CircleAvatar(backgroundColor: Colors.green.withValues(alpha: 0.1), child: Icon(icon, color: Colors.green)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}