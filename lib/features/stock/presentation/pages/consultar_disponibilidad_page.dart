import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/producto_provider.dart';
import '../../../../core/widgets/app_drawer.dart';

class ConsultarDisponibilidadPage extends StatelessWidget {
  const ConsultarDisponibilidadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Consultar Disponibilidad')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Buscar producto', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => context.read<ProductoProvider>().buscarProductos(v),
            ),
          ),
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (ctx, prov, _) => ListView.builder(
                itemCount: prov.productos.length,
                itemBuilder: (c, i) {
                  final p = prov.productos[i];
                  return ListTile(
                    title: Text(p.nombre),
                    subtitle: Text('Stock físico: ${p.cantidadFormateada}'),
                    trailing: p.stockBajo ? const Icon(Icons.warning, color: Colors.orange) : const Icon(Icons.check, color: Colors.green),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}