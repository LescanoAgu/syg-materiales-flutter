import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../data/repositories/acopio_repository.dart';

class AcopioHistorialPage extends StatefulWidget {
  final AcopioDetalle acopioDetalle;
  const AcopioHistorialPage({super.key, required this.acopioDetalle});

  @override
  State<AcopioHistorialPage> createState() => _AcopioHistorialPageState();
}

class _AcopioHistorialPageState extends State<AcopioHistorialPage> {
  final AcopioRepository _acopioRepo = AcopioRepository();
  List<MovimientoAcopioModel> _movimientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);
    final movs = await _acopioRepo.obtenerHistorialAcopio(
      productoId: widget.acopioDetalle.acopio.productoId,
      clienteId: widget.acopioDetalle.acopio.clienteId,
      proveedorId: widget.acopioDetalle.acopio.proveedorId,
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
      appBar: AppBar(title: const Text('Historial')),
      body: Column(
        children: [
          _buildHeaderAcopio(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _movimientos.length,
              itemBuilder: (ctx, i) {
                final m = _movimientos[i];
                return ListTile(
                  title: Text(m.tipo.name.toUpperCase()),
                  subtitle: Text(ArgFormats.fechaHora(m.createdAt)),
                  trailing: Text(
                    '${m.cantidad}',
                    style: TextStyle(
                        color: m.tipo == TipoMovimientoAcopio.entrada ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold
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
            Text(widget.acopioDetalle.productoNombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.acopioDetalle.clienteRazonSocial),
                Text('${widget.acopioDetalle.cantidadFormateada} ${widget.acopioDetalle.unidadBase}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}