import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/billetera_acopio_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../providers/acopio_provider.dart';

class AcopioDetallePage extends StatefulWidget {
  final BilleteraAcopio billetera; // ✅ Usamos el modelo nuevo

  const AcopioDetallePage({super.key, required this.billetera});

  @override
  State<AcopioDetallePage> createState() => _AcopioDetallePageState();
}

class _AcopioDetallePageState extends State<AcopioDetallePage> {
  List<MovimientoAcopioModel> _movimientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);
    final movs = await context.read<AcopioProvider>().obtenerHistorialAcopio(
      productoCodigo: widget.billetera.productoId,
      clienteCodigo: widget.billetera.clienteId,
    );
    setState(() {
      _movimientos = movs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.billetera.productoNombre)),
      body: Column(
        children: [
          // Header con Saldos
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Saldo Total: ${widget.billetera.saldoTotal}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(),
                  _rowSaldo("En Depósito S&G", widget.billetera.cantidadEnDepositoPropio),
                  ...widget.billetera.cantidadEnProveedores.entries.map((e) => _rowSaldo("Prov: ${e.key}", e.value)),
                ],
              ),
            ),
          ),

          // Lista Movimientos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _movimientos.length,
              itemBuilder: (ctx, i) {
                final m = _movimientos[i];
                return ListTile(
                  title: Text(m.tipo.toString().split('.').last.toUpperCase()),
                  subtitle: Text("Fecha: ${m.createdAt.toLocal()}"),
                  trailing: Text("${m.cantidad > 0 ? '+' : ''}${m.cantidad}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: m.cantidad > 0 ? Colors.green : Colors.red)
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Navegar a agregar movimiento pre-llenado
          // Navigator.push(...)
        },
      ),
    );
  }

  Widget _rowSaldo(String label, double cant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(cant.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}