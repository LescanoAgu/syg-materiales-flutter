import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../../../stock/data/repositories/movimiento_stock_repository.dart';
import '../../data/services/pdf_service.dart';
import '../../data/services/excel_service.dart';

class ReporteStockPage extends StatefulWidget {
  const ReporteStockPage({super.key});

  @override
  State<ReporteStockPage> createState() => _ReporteStockPageState();
}

class _ReporteStockPageState extends State<ReporteStockPage> {
  final MovimientoStockRepository _repo = MovimientoStockRepository();
  final PdfService _pdfService = PdfService();

  List<MovimientoStock> _movimientos = [];
  bool _isLoading = true;

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  TipoMovimiento? _tipoFiltro;

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);

    try {
      // CORRECCIÓN: Usar 'obtenerMovimientos' en lugar de 'getMovimientos'
      final movimientos = await _repo.obtenerMovimientos(
        desde: _fechaDesde,
        hasta: _fechaHasta,
        tipo: _tipoFiltro,
      );

      setState(() {
        _movimientos = movimientos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Manejo de error silencioso o mostrar snackbar
      print("Error cargando reporte: $e");
    }
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        if (esDesde) {
          _fechaDesde = fecha;
        } else {
          _fechaHasta = fecha;
        }
      });
      _cargarMovimientos();
    }
  }

  Future<void> _exportarPDF() async {
    try {
      await _pdfService.generarReporteMovimientosStock(
        movimientos: _movimientos,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ PDF generado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de Stock')),
      body: Column(
        children: [
          // Filtros básicos
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_fechaDesde == null ? 'Desde' : ArgFormats.fechaCorta(_fechaDesde!)),
                  onPressed: () => _seleccionarFecha(true),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_fechaHasta == null ? 'Hasta' : ArgFormats.fechaCorta(_fechaHasta!)),
                  onPressed: () => _seleccionarFecha(false),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportarPDF),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _movimientos.length,
              itemBuilder: (context, index) {
                final m = _movimientos[index];
                return ListTile(
                  title: Text('${m.tipo.name.toUpperCase()} - ${m.cantidad}'),
                  subtitle: Text(ArgFormats.fechaHora(m.createdAt)),
                  trailing: m.referencia != null ? Text(m.referencia!) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}