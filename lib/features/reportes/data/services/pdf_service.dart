import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// 1. IMPORTANTE: Importar esto para arreglar el error de Locale
import 'package:intl/date_symbol_data_local.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../../../ordenes_internas/data/models/orden_interna_model.dart';
import '../../../ordenes_internas/data/models/orden_item_model.dart';

class PdfService {

  // --- REPORTE DE STOCK ---
  Future<void> generarReporteMovimientosStock({
    required List<MovimientoStock> movimientos,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    // 2. ARREGLO LOCALE: Inicializar datos de formato para español
    await initializeDateFormatting('es_AR', null);

    final pdf = pw.Document();

    // Agrupamos movimientos por Producto ID para que el reporte sea ordenado
    final Map<String, List<MovimientoStock>> movimientosPorProducto = {};
    for (var m in movimientos) {
      if (!movimientosPorProducto.containsKey(m.productoId)) {
        movimientosPorProducto[m.productoId] = [];
      }
      movimientosPorProducto[m.productoId]!.add(m);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeaderGeneral('REPORTE DE MOVIMIENTOS DE STOCK', fechaDesde, fechaHasta),
            pw.SizedBox(height: 20),

            // Generamos una sección por cada producto
            ...movimientosPorProducto.entries.map((entry) {
              final productoId = entry.key;
              final listaMovimientos = entry.value;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    width: double.infinity,
                    child: pw.Text(
                      'PRODUCTO: $productoId', // Si tuvieras el nombre, iría aquí
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  _buildTablaMovimientos(listaMovimientos),
                  pw.SizedBox(height: 15),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Stock.pdf',
    );
  }

  // --- REMITO DE ORDEN ---
  Future<void> generarRemitoOrden(OrdenInternaDetalle ordenDetalle) async {
    // También inicializamos aquí por si acaso
    await initializeDateFormatting('es_AR', null);

    final pdf = pw.Document();
    final orden = ordenDetalle.orden;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeaderOrden(orden),
            pw.SizedBox(height: 20),
            _buildInfoCliente(ordenDetalle),
            pw.SizedBox(height: 20),
            _buildTablaProductos(ordenDetalle.items),
            pw.SizedBox(height: 20),
            _buildFooterOrden(orden),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Orden_${orden.numero}.pdf',
    );
  }

  // ========================================
  // WIDGETS AUXILIARES
  // ========================================

  pw.Widget _buildHeaderGeneral(String titulo, DateTime? desde, DateTime? hasta) {
    String periodo = 'Histórico Completo';
    if (desde != null || hasta != null) {
      periodo = '${desde != null ? ArgFormats.fecha(desde) : "Inicio"} - ${hasta != null ? ArgFormats.fecha(hasta) : "Hoy"}';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('S&G MATERIALES', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(titulo, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
            pw.Text(periodo, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Divider(color: PdfColors.teal),
      ],
    );
  }

  pw.Widget _buildTablaMovimientos(List<MovimientoStock> movimientos) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Fecha
        1: const pw.FlexColumnWidth(2), // Tipo
        2: const pw.FlexColumnWidth(1.5), // Cantidad
        3: const pw.FlexColumnWidth(3), // Motivo
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.teal50),
          children: [
            _th('FECHA'),
            _th('TIPO'),
            _th('CANTIDAD', align: pw.TextAlign.center),
            _th('MOTIVO / REF'),
          ],
        ),
        ...movimientos.map((m) {
          final colorTipo = m.tipo == TipoMovimiento.entrada ? PdfColors.green700 :
          (m.tipo == TipoMovimiento.salida ? PdfColors.red700 : PdfColors.orange700);

          return pw.TableRow(
            children: [
              _td(ArgFormats.fechaHora(m.createdAt)),
              _td(m.tipo.name.toUpperCase(), color: colorTipo, isBold: true),
              _td(m.cantidad.toStringAsFixed(2), align: pw.TextAlign.center, isBold: true),
              _td('${m.motivo ?? "-"} ${m.referencia != null ? "(${m.referencia})" : ""}'),
            ],
          );
        }),
      ],
    );
  }

  // ... (Mantén los métodos _buildHeaderOrden, _buildInfoCliente, _buildTablaProductos, _buildFooterOrden, _th y _td iguales que antes)
  // Solo agrego una pequeña mejora al helper _td para soportar color y negrita:

  pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: align),
    );
  }

  pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor? color, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
          text,
          style: pw.TextStyle(
              fontSize: 9,
              color: color ?? PdfColors.black,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal
          ),
          textAlign: align
      ),
    );
  }

  // --- COPIA AQUÍ TUS MÉTODOS RESTANTES (_buildHeaderOrden, etc) DEL ARCHIVO ANTERIOR ---
  // ... (Si necesitas que te los pase de nuevo completos, avísame, pero con esto cubrimos el error y la nueva funcionalidad)

  pw.Widget _buildHeaderOrden(OrdenInterna orden) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('S&G MATERIALES', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
            pw.Text('Ingeniería y Construcción', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
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
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
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
}