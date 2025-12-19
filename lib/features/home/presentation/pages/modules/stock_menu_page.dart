import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../stock/presentation/pages/stock_page.dart';
import '../../../../stock/presentation/pages/movimiento_historial_page.dart';

class StockMenuPage extends StatelessWidget {
  const StockMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Stock"), backgroundColor: Colors.blue),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
              context,
              "Stock Físico", "Consultar disponibilidad", Icons.visibility,
              const StockPage()
          ),
          const Divider(),
          _tile(
              context,
              "Movimientos", "Historial de Entradas/Salidas", Icons.history,
              const MovimientoHistorialPage()
          ),
          // ❌ Aquí quitamos la opción de Importar Catálogo. Ahora es solo operativo.
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String sub, IconData icon, Widget page) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.blue.withValues(alpha: 0.1), child: Icon(icon, color: Colors.blue)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}