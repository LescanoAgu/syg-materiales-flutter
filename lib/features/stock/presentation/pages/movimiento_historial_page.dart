import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../providers/movimiento_stock_provider.dart';
import 'stock_page.dart';

class MovimientoHistorialPage extends StatefulWidget {
  final String? productoId;
  const MovimientoHistorialPage({super.key, this.productoId});

  @override
  State<MovimientoHistorialPage> createState() => _MovimientoHistorialPageState();
}

class _MovimientoHistorialPageState extends State<MovimientoHistorialPage> {
  TipoMovimiento? _filtroTipo; // Null = Todos

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productoId != null) {
        context.read<MovimientoStockProvider>().cargarMovimientosDeProducto(
            widget.productoId!,
            tipo: _filtroTipo
        );
      } else {
        context.read<MovimientoStockProvider>().cargarMovimientos(
            tipo: _filtroTipo
        );
      }
    });
  }

  void _cambiarFiltro(TipoMovimiento? nuevoTipo) {
    setState(() {
      _filtroTipo = (_filtroTipo == nuevoTipo) ? null : nuevoTipo; // Toggle (si tocas el mismo, se desactiva)
    });
    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.productoId == null ? 'Historial General' : 'Historial: ${widget.productoId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const StockPage()),
              );
            }
          },
        ),
      ),
      body: Column(
        children: [
          // --- BARRA DE FILTROS ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterChip('Todos', null, Colors.grey),
                _buildFilterChip('Entradas', TipoMovimiento.entrada, Colors.green),
                _buildFilterChip('Salidas', TipoMovimiento.salida, Colors.red),
                _buildFilterChip('Ajustes', TipoMovimiento.ajuste, Colors.orange),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- LISTA ---
          Expanded(
            child: Consumer<MovimientoStockProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.errorMessage != null) return Center(child: Text('Error: ${provider.errorMessage}'));
                if (provider.movimientos.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No se encontraron movimientos', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.movimientos.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final m = provider.movimientos[i];

                    Color color = m.tipo == TipoMovimiento.entrada ? Colors.green :
                    (m.tipo == TipoMovimiento.salida ? Colors.red : Colors.orange);
                    IconData icon = m.tipo == TipoMovimiento.entrada ? Icons.arrow_circle_down :
                    (m.tipo == TipoMovimiento.salida ? Icons.arrow_circle_up : Icons.tune);

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
                          if(widget.productoId == null)
                            Text('Prod: ${m.productoId}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(m.createdAt.toString().split('.')[0]),
                          if (m.motivo != null && m.motivo!.isNotEmpty)
                            Text('"${m.motivo}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                      trailing: m.referencia != null
                          ? Chip(label: Text(m.referencia!, style: const TextStyle(fontSize: 10)))
                          : null,
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

  Widget _buildFilterChip(String label, TipoMovimiento? valor, Color color) {
    final bool isSelected = _filtroTipo == valor;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _cambiarFiltro(valor),
      backgroundColor: Colors.white,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
      checkmarkColor: color,
    );
  }
}