import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart'; // Importamos colores para que quede lindo
import '../../data/models/movimiento_stock_model.dart'; // Importamos el modelo
import '../providers/movimiento_stock_provider.dart';
import 'stock_page.dart'; // ✅ FIX: Import directo (están en la misma carpeta)

class MovimientoHistorialPage extends StatefulWidget {
  final String? productoId;
  const MovimientoHistorialPage({super.key, this.productoId});

  @override
  State<MovimientoHistorialPage> createState() => _MovimientoHistorialPageState();
}

class _MovimientoHistorialPageState extends State<MovimientoHistorialPage> {
  @override
  void initState() {
    super.initState();
    // Carga inicial de datos
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
      backgroundColor: AppColors.background, // Usamos el color de fondo de la app
      appBar: AppBar(
        title: const Text('Historial de Movimientos'),
        // ✅ FIX NAVEGACIÓN: Botón "Atrás" inteligente
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 1. Si hay historial (vinimos de otra pantalla con push), volvemos normal
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // 2. Si NO hay historial (vinimos del Drawer con pushReplacement),
            // forzamos ir al Stock (Home)
            else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const StockPage()),
              );
            }
          },
        ),
      ),

      // ✅ FIX ESTRUCTURA: Restauramos el 'body' que faltaba
      body: Consumer<MovimientoStockProvider>(
        builder: (context, provider, _) {
          // 1. Cargando
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error
          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          // 3. Lista vacía
          if (provider.movimientos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay movimientos registrados', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 4. Lista de movimientos
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.movimientos.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final m = provider.movimientos[i];
              final esEntrada = m.tipo == TipoMovimiento.entrada;
              final esSalida = m.tipo == TipoMovimiento.salida;

              // Color e icono según tipo
              Color color = esEntrada ? Colors.green : (esSalida ? Colors.red : Colors.orange);
              IconData icon = esEntrada ? Icons.arrow_circle_down : (esSalida ? Icons.arrow_circle_up : Icons.tune);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  '${m.tipo.name.toUpperCase()} (${m.cantidad})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fecha: ${m.createdAt.day}/${m.createdAt.month}/${m.createdAt.year}'),
                    if (m.motivo != null && m.motivo!.isNotEmpty)
                      Text('Motivo: ${m.motivo}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}