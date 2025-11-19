import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movimiento_stock_provider.dart';

class MovimientoHistorialPage extends StatefulWidget {
  final String? productoId; // String
  const MovimientoHistorialPage({super.key, this.productoId});

  @override
  State<MovimientoHistorialPage> createState() => _MovimientoHistorialPageState();
}

class _MovimientoHistorialPageState extends State<MovimientoHistorialPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productoId != null) {
        context.read<MovimientoStockProvider>().cargarMovimientosDeProducto(widget.productoId!);
      } else {
        context.read<MovimientoStockProvider>().cargarMovimientos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: Consumer<MovimientoStockProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: provider.movimientos.length,
            itemBuilder: (ctx, i) {
              final m = provider.movimientos[i];
              return ListTile(
                title: Text('${m.tipo.name.toUpperCase()} - ${m.cantidad}'),
                subtitle: Text(m.createdAt.toString()),
              );
            },
          );
        },
      ),
    );
  }
}