import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/billetera_acopio_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../providers/acopio_provider.dart';

class AcopioHistorialPage extends StatefulWidget {
  final BilleteraAcopio billetera; // ✅ Usamos el nuevo modelo Billetera

  const AcopioHistorialPage({super.key, required this.billetera});

  @override
  State<AcopioHistorialPage> createState() => _AcopioHistorialPageState();
}

class _AcopioHistorialPageState extends State<AcopioHistorialPage> {
  List<MovimientoAcopioModel> _movimientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);

    // ✅ CORRECCIÓN: Llamamos al método sin 'proveedorId', usando el Provider
    final movs = await context.read<AcopioProvider>().obtenerHistorialAcopio(
      productoCodigo: widget.billetera.productoId,
      clienteCodigo: widget.billetera.clienteId,
    );

    if (mounted) {
      setState(() {
        _movimientos = movs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Movimientos')),
      body: Column(
        children: [
          _buildHeaderAcopio(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _movimientos.isEmpty
                ? const Center(child: Text("No hay movimientos registrados"))
                : ListView.separated(
              itemCount: _movimientos.length,
              separatorBuilder: (_,__) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final m = _movimientos[i];
                // Lógica visual simple: Entrada (positivo) en verde, Salida (negativo) en rojo
                final esPositivo = m.cantidad > 0;

                return ListTile(
                  title: Text(m.tipo.name.toUpperCase()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ArgFormats.fechaHora(m.createdAt)),
                      if (m.referencia != null) Text(m.referencia!, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: Text(
                    '${esPositivo ? '+' : ''}${m.cantidad}',
                    style: TextStyle(
                        color: esPositivo ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAcopio() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.billetera.productoNombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.billetera.clienteNombre),
                Text('Saldo: ${widget.billetera.saldoTotal}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}