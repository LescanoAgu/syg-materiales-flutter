import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/orden_interna_model.dart';
import '../../data/models/orden_item_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../../reportes/data/services/pdf_service.dart';

class OrdenDetallePage extends StatefulWidget {
  // Recibimos el resumen desde la lista
  final OrdenInternaDetalle ordenResumen;

  const OrdenDetallePage({
    super.key,
    required this.ordenResumen,
  });

  @override
  State<OrdenDetallePage> createState() => _OrdenDetallePageState();
}

class _OrdenDetallePageState extends State<OrdenDetallePage> {
  bool _cargandoItems = true;
  late OrdenInternaDetalle _ordenCompleta;

  @override
  void initState() {
    super.initState();
    // Inicializamos con lo que tenemos
    _ordenCompleta = widget.ordenResumen;

    // Buscamos los detalles completos (items)
    _cargarDetallesCompletos();
  }

  Future<void> _cargarDetallesCompletos() async {
    if (widget.ordenResumen.orden.id == null) {
      setState(() => _cargandoItems = false);
      return;
    }

    final detalle = await context.read<OrdenInternaProvider>()
        .cargarDetalleOrden(widget.ordenResumen.orden.id!);

    if (mounted && detalle != null) {
      setState(() {
        _ordenCompleta = detalle;
        _cargandoItems = false;
      });
    } else if (mounted) {
      setState(() => _cargandoItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orden = _ordenCompleta.orden;
    final estadoColor = _getEstadoColor(orden.estado);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Orden ${orden.numero}'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        actions: [
          // BOTÓN DE IMPRIMIR (Solo si ya cargaron los items)
          if (!_cargandoItems)
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Generar PDF',
              onPressed: () => _generarPdf(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER ESTADO
            _buildHeaderEstado(orden, estadoColor),
            const SizedBox(height: 20),

            // 2. INFO
            _buildSeccionInfo(orden),
            const SizedBox(height: 20),

            // 3. PRODUCTOS
            const Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 10),

            if (_cargandoItems)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_ordenCompleta.items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay items en esta orden.'),
                ),
              )
            else
              ..._ordenCompleta.items.map((item) => _buildProductoItem(item)),

            const SizedBox(height: 20),

            // 4. OBSERVACIONES
            if (orden.observacionesCliente != null && orden.observacionesCliente!.isNotEmpty)
              _buildObservacion('Observaciones', orden.observacionesCliente!),

            const SizedBox(height: 30),

            // 5. ACCIONES
            if (orden.estado == 'solicitado')
              _buildBotonesAccion(context, orden),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA PDF ---
  Future<void> _generarPdf(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando PDF...')),
      );

      final pdfService = PdfService();
      // Usamos _ordenCompleta que ya tiene los items cargados
      await pdfService.generarRemitoOrden(_ordenCompleta);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildHeaderEstado(OrdenInterna orden, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_getEstadoIcon(orden.estado), color: color, size: 30),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ESTADO', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(orden.estado.toUpperCase(), style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(ArgFormats.moneda(orden.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSeccionInfo(OrdenInterna orden) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _datoFila(Icons.business, 'Cliente', _ordenCompleta.clienteRazonSocial),
            const Divider(),
            _datoFila(Icons.location_city, 'Obra', _ordenCompleta.obraNombre ?? 'Sin Obra'),
            const Divider(),
            _datoFila(Icons.person, 'Solicitante', orden.solicitanteNombre),
            const Divider(),
            _datoFila(Icons.calendar_today, 'Fecha', ArgFormats.fechaHora(orden.fechaPedido)),
          ],
        ),
      ),
    );
  }

  Widget _datoFila(IconData icon, String label, String valor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildProductoItem(OrdenItemDetalle detalle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(detalle.cantidadFinal.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        title: Text(detalle.productoNombre),
        subtitle: Text(detalle.productoCodigo),
        trailing: Text(
          ArgFormats.moneda(detalle.item.subtotal),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildObservacion(String titulo, String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(texto),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion(BuildContext context, OrdenInterna orden) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente'))),
            icon: const Icon(Icons.cancel),
            label: const Text('RECHAZAR'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente'))),
            icon: const Icon(Icons.check_circle),
            label: const Text('APROBAR'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'solicitado': return Colors.orange;
      case 'aprobado': return Colors.green;
      case 'rechazado': return Colors.red;
      case 'despachado': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'solicitado': return Icons.hourglass_empty;
      case 'aprobado': return Icons.check_circle_outline;
      case 'rechazado': return Icons.highlight_off;
      case 'despachado': return Icons.local_shipping;
      default: return Icons.help_outline;
    }
  }
}