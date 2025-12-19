import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../providers/movimiento_stock_provider.dart';

class MovimientoHistorialPage extends StatefulWidget {
  final String? productoId;
  const MovimientoHistorialPage({super.key, this.productoId});

  @override
  State<MovimientoHistorialPage> createState() => _MovimientoHistorialPageState();
}

class _MovimientoHistorialPageState extends State<MovimientoHistorialPage> {
  TipoMovimiento? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productoId != null) {
        context.read<MovimientoStockProvider>().cargarMovimientosDeProducto(widget.productoId!, tipo: _filtroTipo);
      } else {
        context.read<MovimientoStockProvider>().cargarMovimientos(tipo: _filtroTipo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Historial de Movimientos"),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ✅ NUEVOS FILTROS BONITOS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterBtn("Todos", null, Colors.grey),
                _buildFilterBtn("Entrada", TipoMovimiento.entrada, Colors.green),
                _buildFilterBtn("Salida", TipoMovimiento.salida, Colors.red),
                _buildFilterBtn("Ajuste", TipoMovimiento.ajuste, Colors.blue),
              ],
            ),
          ),

          Expanded(
            child: Consumer<MovimientoStockProvider>(
              builder: (ctx, prov, _) {
                if (prov.isLoading) return const Center(child: CircularProgressIndicator());

                if (prov.movimientos.isEmpty) {
                  return const Center(child: Text("No se encontraron movimientos", style: TextStyle(color: Colors.grey)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: prov.movimientos.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final m = prov.movimientos[i];
                    final esEntrada = m.tipo == TipoMovimiento.entrada;
                    final color = esEntrada ? Colors.green : (m.tipo == TipoMovimiento.salida ? Colors.red : Colors.blue);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(
                            esEntrada ? Icons.arrow_downward : (m.tipo == TipoMovimiento.salida ? Icons.arrow_upward : Icons.tune),
                            color: color,
                          ),
                        ),
                        title: Text(m.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("${DateFormat('dd/MM HH:mm').format(m.createdAt)} • ${m.usuarioNombre}"),
                            if (m.obraNombre != null)
                              Text("Obra: ${m.obraNombre}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black87)),
                            if (m.motivo != null && m.motivo!.isNotEmpty)
                              Text("\"${m.motivo}\"", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                          ],
                        ),
                        trailing: Text(
                          "${esEntrada ? '+' : '-'}${m.cantidad}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String label, TipoMovimiento? tipo, Color color) {
    final bool isSelected = _filtroTipo == tipo;
    return InkWell(
      onTap: () {
        setState(() => _filtroTipo = tipo);
        _cargar();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(
            label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12
            )
        ),
      ),
    );
  }
}