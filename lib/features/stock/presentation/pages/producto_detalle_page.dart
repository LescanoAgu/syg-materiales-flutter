import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/producto_model.dart';
import 'movimiento_historial_page.dart';
import 'producto_form_page.dart';

class ProductoDetallePage extends StatelessWidget {
  final ProductoModel producto;
  const ProductoDetallePage({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(producto.codigo),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ProductoFormPage(producto: producto))
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(producto.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Chip(label: Text(producto.categoriaNombre ?? 'Sin Categoría')),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statItem("Stock Actual", producto.cantidadFormateada, Colors.black),
                        const SizedBox(width: 40),
                        _statItem("Unidad", producto.unidadBase, Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text("VER HISTORIAL COMPLETO"),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MovimientoHistorialPage(productoId: producto.codigo))
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}