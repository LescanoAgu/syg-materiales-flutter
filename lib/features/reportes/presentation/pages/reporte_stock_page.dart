import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../../../stock/data/repositories/movimiento_stock_repository.dart';
import '../../data/services/excel_service.dart';

class ReporteStockPage extends StatefulWidget {
  const ReporteStockPage({super.key});

  @override
  State<ReporteStockPage> createState() => _ReporteStockPageState();
}

class _ReporteStockPageState extends State<ReporteStockPage> {
  final MovimientoStockRepository _repo = MovimientoStockRepository();
  final ExcelService _excelService = ExcelService();

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
      final movimientos = await _repo.obtenerMovimientos(
        desde: _fechaDesde,
        hasta: _fechaHasta,
        tipo: _tipoFiltro,
      );
      setState(() => _movimientos = movimientos);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportarExcel() async {
    if (_movimientos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay datos para exportar")));
      return;
    }
    await _excelService.generarReporteMovimientos(_movimientos);
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (esDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
      _cargarMovimientos(); // Recargar al cambiar filtro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reporte de Stock"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: "Exportar Excel",
            onPressed: _exportarExcel,
          )
        ],
      ),
      body: Column(
        children: [
          // FILTROS
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_fechaDesde == null ? 'Desde' : ArgFormats.fechaCorta(_fechaDesde!)),
                    onPressed: () => _seleccionarFecha(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_fechaHasta == null ? 'Hasta' : ArgFormats.fechaCorta(_fechaHasta!)),
                    onPressed: () => _seleccionarFecha(false),
                  ),
                ),
              ],
            ),
          ),

          // LISTA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _movimientos.isEmpty
                ? const Center(child: Text("No se encontraron movimientos"))
                : ListView.separated(
              itemCount: _movimientos.length,
              separatorBuilder: (_,__) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final m = _movimientos[index];
                final esEntrada = m.tipo == TipoMovimiento.entrada || m.tipo == TipoMovimiento.ajustePositivo;

                return ListTile(
                  leading: Icon(
                    esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                    color: esEntrada ? Colors.green : Colors.red,
                  ),
                  title: Text(m.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${ArgFormats.fechaHora(m.fecha)} - ${m.usuarioNombre}"),
                  trailing: Text(
                    "${esEntrada ? '+' : '-'}${m.cantidad}",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: esEntrada ? Colors.green : Colors.red
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
}