import 'package:flutter/material.dart';
import '../../data/models/producto_model.dart';
import 'movimiento_historial_page.dart'; // ✅ Importamos la página de historial

class ProductoDetallePage extends StatelessWidget {
  final ProductoModel producto; // Usamos el alias o el nombre directo
  const ProductoDetallePage({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(producto.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Info Principal
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(producto.unidadBase[0].toUpperCase()),
                ),
                title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(producto.codigo),
              ),
            ),
            const SizedBox(height: 20),

            // Info de Stock
            const Text("Estado Actual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildInfoBox("Stock Físico", "${producto.cantidadDisponible}", Colors.blue),
                const SizedBox(width: 10),
                _buildInfoBox("Unidad", producto.unidadBase, Colors.grey),
              ],
            ),

            const Spacer(),

            // Botón de Historial Conectado
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text("VER HISTORIAL DE MOVIMIENTOS"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MovimientoHistorialPage(productoId: producto.codigo)
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}