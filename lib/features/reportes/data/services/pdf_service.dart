import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart'; // Para usar colores si hace falta (aunque PDF usa PdfColors)
import '../../../../core/utils/formatters.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
// Importamos los modelos de Orden
import '../../../ordenes_internas/data/models/orden_interna_model.dart';
import '../../../ordenes_internas/data/models/orden_item_model.dart';

class PdfService {

  // --- REPORTE DE STOCK (Ya lo tenías) ---
  Future<void> generarReporteMovimientosStock({
    required List<MovimientoStock> movimientos,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    final pdf = pw.Document();

    // ... (Tu lógica anterior de stock, resumida aquí para no ocupar espacio innecesario) ...
    // Si quieres mantener el reporte de stock, asegúrate de no borrar su lógica interna.
    // Para este ejemplo, me enfoco en el nuevo método.
  }

  // --- NUEVO: REMITO DE ORDEN ---
  Future<void> generarRemitoOrden(OrdenInternaDetalle ordenDetalle) async {
    final pdf = pw.Document();
    final orden = ordenDetalle.orden;

    // Agregamos página
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // 1. CABECERA
            _buildHeaderOrden(orden),
            pw.SizedBox(height: 20),

            // 2. DATOS CLIENTE Y OBRA
            _buildInfoCliente(ordenDetalle),
            pw.SizedBox(height: 20),

            // 3. TABLA DE PRODUCTOS
            _buildTablaProductos(ordenDetalle.items),
            pw.SizedBox(height: 20),

            // 4. TOTALES Y FIRMA
            _buildFooterOrden(orden),
          ];
        },
      ),
    );

    // Abrir vista previa
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Orden_${orden.numero}.pdf',
    );
  }

  // --- WIDGETS PDF ---

  pw.Widget _buildHeaderOrden(OrdenInterna orden) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Logo / Empresa
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('S&G MATERIALES', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
            pw.Text('Ingeniería y Construcción', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
        // Datos Orden
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('ORDEN INTERNA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(orden.numero, style: pw.TextStyle(fontSize: 14, color: PdfColors.red700, fontWeight: pw.FontWeight.bold)),
            pw.Text('Fecha: ${ArgFormats.fecha(orden.fechaPedido)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Estado: ${orden.estado.toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInfoCliente(OrdenInternaDetalle detalle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CLIENTE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.Text(detalle.clienteRazonSocial, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Solicitante: ${detalle.orden.solicitanteNombre}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.Container(width: 1, height: 30, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(horizontal: 10)),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('OBRA / DESTINO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.Text(detalle.obraNombre ?? 'Sin especificar', style: const pw.TextStyle(fontSize: 12)),
                if (detalle.orden.fechaEntregaEstimada != null)
                  pw.Text('Entrega est.: ${ArgFormats.fecha(detalle.orden.fechaEntregaEstimada)}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTablaProductos(List<OrdenItemDetalle> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Producto
        1: const pw.FlexColumnWidth(1), // Cant
        2: const pw.FlexColumnWidth(1), // Unidad
        3: const pw.FlexColumnWidth(1.5), // Precio
        4: const pw.FlexColumnWidth(1.5), // Subtotal
      },
      children: [
        // Header Tabla
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.teal50),
          children: [
            _th('DESCRIPCIÓN'),
            _th('CANT', align: pw.TextAlign.center),
            _th('UNID', align: pw.TextAlign.center),
            _th('PRECIO', align: pw.TextAlign.right),
            _th('SUBTOTAL', align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...items.map((e) => pw.TableRow(
          children: [
            _td(e.productoNombre),
            _td(ArgFormats.decimal(e.cantidadFinal), align: pw.TextAlign.center),
            _td(e.unidadBase, align: pw.TextAlign.center),
            _td(ArgFormats.monedaSinSimbolo(e.item.precioUnitario), align: pw.TextAlign.right),
            _td(ArgFormats.monedaSinSimbolo(e.item.subtotal), align: pw.TextAlign.right),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildFooterOrden(OrdenInterna orden) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Observaciones
        pw.Expanded(
          child: orden.observacionesCliente != null && orden.observacionesCliente!.isNotEmpty
              ? pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('OBSERVACIONES:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text(orden.observacionesCliente!, style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          )
              : pw.Container(),
        ),
        pw.SizedBox(width: 20),
        // Total
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.teal,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              pw.Text('TOTAL: ', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              pw.Text(ArgFormats.moneda(orden.total), style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  // Helpers de celda
  pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: align),
    );
  }

  pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: align),
    );
  }
}