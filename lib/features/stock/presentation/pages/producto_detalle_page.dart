import 'package:flutter/material.dart';
import '../../data/models/producto_model.dart';

class ProductoDetallePage extends StatelessWidget {
  final ProductoConStock producto;
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
            Text('Código: ${producto.codigo}', style: const TextStyle(fontSize: 18)),
            Text('Stock: ${producto.cantidadFormateada} ${producto.unidadBase}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Historial (Próximamente)'),
          ],
        ),
      ),
    );
  }
}