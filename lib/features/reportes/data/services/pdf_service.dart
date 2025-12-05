import 'dart:typed_data';
import 'package:flutter/services.dart'; // Incluye NetworkAssetBundle
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../../core/utils/formatters.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../../../ordenes_internas/data/models/orden_interna_model.dart';
import '../../../ordenes_internas/data/models/orden_item_model.dart';
import '../../../ordenes_internas/data/models/remito_model.dart';

class PdfService {

  // --- CARGA DE RECURSOS ---

  Future<Uint8List> _cargarLogo() async {
    try {
      final byteData = await rootBundle.load('web/icons/Logo_SYG.png');
      return byteData.buffer.asUint8List();
    } catch (e) {
      return Uint8List(0);
    }
  }

  Future<Uint8List?> _descargarImagen(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final bundle = NetworkAssetBundle(Uri.parse(url));
      final data = await bundle.load("");
      return data.buffer.asUint8List();
    } catch (e) {
      print("Error descargando imagen para PDF: $e");
      return null;
    }
  }

  PdfColor _getColorPorTipo(TipoMovimiento tipo) {
    if (tipo == TipoMovimiento.entrada) return PdfColors.green700;
    if (tipo == TipoMovimiento.salida) return PdfColors.red700;
    return PdfColors.orange700;
  }

  // ===========================================================================
  // 1. REPORTE DE STOCK
  // ===========================================================================
  Future<void> generarReporteMovimientosStock({
    required List<MovimientoStock> movimientos,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    await initializeDateFormatting('es_AR', null);
    final pdf = pw.Document();
    final logoBytes = await _cargarLogo();
    final imageLogo = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

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
        build: (pw.Context context) => [
          _buildHeaderGeneral('REPORTE DE MOVIMIENTOS', fechaDesde, fechaHasta, imageLogo),
          pw.SizedBox(height: 20),
          ...movimientosPorProducto.entries.map((entry) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  color: PdfColors.grey200,
                  width: double.infinity,
                  child: pw.Text('PRODUCTO: ${entry.key}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 5),
                _buildTablaMovimientos(entry.value),
                pw.SizedBox(height: 15),
              ],
            );
          }).toList(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_Stock.pdf');
  }

  // ===========================================================================
  // 2. ORDEN INTERNA
  // ===========================================================================
  Future<void> generarOrdenInterna(OrdenInternaDetalle ordenDetalle) async {
    await initializeDateFormatting('es_AR', null);
    final pdf = pw.Document();
    final logoBytes = await _cargarLogo();
    final imageLogo = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final orden = ordenDetalle.orden;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(
              titulo: 'ORDEN INTERNA',
              numero: orden.numero,
              fecha: orden.fechaPedido,
              estado: orden.estado,
              logo: imageLogo
          ),
          pw.SizedBox(height: 20),
          _buildInfoCliente(ordenDetalle),
          pw.SizedBox(height: 20),
          _buildTablaProductos(ordenDetalle.items),
          pw.SizedBox(height: 20),
          _buildObservaciones(orden.observacionesCliente),
          pw.Spacer(),
          _buildFirmas(),
          pw.SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );

    // ✅ CAMBIO APLICADO: Nombre dinámico (OI-001 | CLIENTE - OBRA.pdf)
    final obraNombre = ordenDetalle.obraNombre ?? 'Sin Obra';
    final nombreArchivo = '${orden.numero} | ${ordenDetalle.clienteRazonSocial} - $obraNombre.pdf';

    await Printing.sharePdf(bytes: await pdf.save(), filename: nombreArchivo);
  }

  // ===========================================================================
  // 3. REMITO DE DESPACHO (AL MOMENTO)
  // ===========================================================================
  Future<void> generarRemitoDespacho({
    required OrdenInternaDetalle ordenDetalle,
    required List<Map<String, dynamic>> itemsDespachados,
    required String nombreResponsable,
  }) async {
    await initializeDateFormatting('es_AR', null);
    final pdf = pw.Document();
    final logoBytes = await _cargarLogo();
    final imageLogo = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final orden = ordenDetalle.orden;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(
              titulo: 'REMITO DE ENTREGA',
              numero: 'REF-${orden.numero}',
              fecha: DateTime.now(),
              estado: 'ENVIADO',
              logo: imageLogo
          ),
          pw.SizedBox(height: 20),
          _buildInfoDespacho(ordenDetalle, nombreResponsable),
          pw.SizedBox(height: 20),
          _buildTablaRemitoDinamico(itemsDespachados, ordenDetalle),
          pw.Spacer(),
          _buildFirmasRemito(),
          pw.SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Remito_${orden.numero}.pdf');
  }

  // ===========================================================================
  // 4. REMITO HISTÓRICO (CON 5 COLUMNAS Y FIRMAS)
  // ===========================================================================
  Future<void> generarRemitoHistorico(Remito remito, OrdenInternaDetalle ordenDetalle) async {
    await initializeDateFormatting('es_AR', null);
    final pdf = pw.Document();

    final logoBytes = await _cargarLogo();
    final imageLogo = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

    // Descargar firmas
    final firmaAuthBytes = await _descargarImagen(remito.firmaAutorizoUrl);
    final firmaRecBytes = await _descargarImagen(remito.firmaRecibioUrl);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader(
              titulo: 'REMITO DE ENTREGA',
              numero: remito.numeroRemito,
              fecha: remito.fecha,
              estado: 'ENTREGADO',
              logo: imageLogo
          ),
          pw.SizedBox(height: 20),
          _buildInfoDespacho(ordenDetalle, remito.usuarioDespachadorNombre),
          pw.SizedBox(height: 20),

          // TABLA DE 5 COLUMNAS
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3), // Item
              1: const pw.FlexColumnWidth(1), // Total Pedido
              2: const pw.FlexColumnWidth(1), // Faltaba
              3: const pw.FlexColumnWidth(1), // Entrego (Negrita)
              4: const pw.FlexColumnWidth(1), // Queda
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.teal50), // SIN CONST
                children: [
                  _th('ITEM / MATERIAL'),
                  _th('TOTAL\nPEDIDO', align: pw.TextAlign.center),
                  _th('FALTABA\nENTREGAR', align: pw.TextAlign.center),
                  _th('ENTREGO\nAHORA', align: pw.TextAlign.center),
                  _th('SALDO\nRESTANTE', align: pw.TextAlign.center),
                ],
              ),
              ...remito.items.map((item) {
                final total = item.cantidadSolicitadaTotal;
                final anterior = item.saldoPendienteAnterior;
                final entrega = item.cantidad;
                final saldo = anterior - entrega;

                return pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    _td(item.productoNombre, isBold: true),
                    _td(total > 0 ? ArgFormats.decimal(total) : "-", align: pw.TextAlign.center),
                    _td(total > 0 ? ArgFormats.decimal(anterior) : "-", align: pw.TextAlign.center),

                    // Columna Entrega
                    pw.Container(
                        color: PdfColors.green50,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            '${ArgFormats.decimal(entrega)} ${item.unidad}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)
                        )
                    ),

                    _td(total > 0 ? ArgFormats.decimal(saldo) : "-", align: pw.TextAlign.center, color: saldo <= 0 ? PdfColors.green700 : PdfColors.red700),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.Spacer(),

          // Firmas reales
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildFirmaImagen(firmaAuthBytes, "Autorizó (S&G)"),
              _buildFirmaImagen(firmaRecBytes, "Recibió Conforme"),
            ],
          ),
          pw.SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Remito_${remito.numeroRemito}.pdf');
  }

  // ===========================================================================
  // WIDGETS AUXILIARES (Privados)
  // ===========================================================================

  pw.Widget _buildHeaderGeneral(String titulo, DateTime? desde, DateTime? hasta, pw.ImageProvider? logo) {
    String periodo = 'Histórico Completo';
    if (desde != null || hasta != null) {
      periodo = '${desde != null ? ArgFormats.fecha(desde) : "Inicio"} - ${hasta != null ? ArgFormats.fecha(hasta) : "Hoy"}';
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logo != null) pw.Image(logo, width: 40, height: 40),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('S&G MATERIALES', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  pw.Text(ArgFormats.fechaHora(DateTime.now()), style: const pw.TextStyle(fontSize: 8)),
                ],
              )
            ]
        ),
        pw.SizedBox(height: 10),
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

  pw.Widget _buildHeader({
    required String titulo,
    required String numero,
    required DateTime fecha,
    required String estado,
    pw.MemoryImage? logo,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (logo != null) pw.Image(logo, width: 60, height: 60),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(titulo, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
            pw.Text(numero, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
            pw.Text('Fecha: ${ArgFormats.fecha(fecha)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Estado: ${estado.toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
          ],
        )
      ],
    );
  }

  pw.Widget _buildInfoCliente(OrdenInternaDetalle detalle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(5),
        color: PdfColors.grey50, // SIN CONST
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("CLIENTE / DESTINATARIO", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                pw.Text(detalle.clienteRazonSocial, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text("Solicitante: ${detalle.orden.solicitanteNombre}", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("LUGAR DE ENTREGA", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                pw.Text(detalle.obraNombre ?? "A coordinar", style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoDespacho(OrdenInternaDetalle detalle, String responsable) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.teal, width: 1), borderRadius: pw.BorderRadius.circular(5)),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("DESTINO: ${detalle.obraNombre ?? 'A coordinar'}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("CLIENTE: ${detalle.clienteRazonSocial}"),
                if (detalle.orden.titulo != null) pw.Text("REF: ${detalle.orden.titulo}", style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("RESPONSABLE DESPACHO", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text(responsable.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.teal50), // SIN CONST
          children: [
            _th('DESCRIPCIÓN'),
            _th('CANTIDAD', align: pw.TextAlign.center),
            _th('UNIDAD', align: pw.TextAlign.center),
          ],
        ),
        ...items.map((item) {
          return pw.TableRow(
            children: [
              _td(item.productoNombre),
              _td(ArgFormats.decimal(item.cantidadFinal), align: pw.TextAlign.center, isBold: true),
              _td(item.unidadBase, align: pw.TextAlign.center),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTablaRemitoDinamico(List<Map<String, dynamic>> itemsDespachados, OrdenInternaDetalle detalle) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.teal50), // SIN CONST
          children: [
            _th('ITEM / MATERIAL'),
            _th('CANTIDAD ENTREGADA', align: pw.TextAlign.center),
          ],
        ),
        ...itemsDespachados.map((d) {
          final itemOriginal = detalle.items.firstWhere(
                (i) => i.item.id == d['itemId'],
            orElse: () => detalle.items.first,
          );
          final cantidad = (d['cantidad'] as num).toDouble();
          return pw.TableRow(
            children: [
              _td(itemOriginal.productoNombre, isBold: true),
              _td('${ArgFormats.decimal(cantidad)} ${itemOriginal.unidadBase}', align: pw.TextAlign.center, isBold: true),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTablaMovimientos(List<MovimientoStock> movimientos) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.teal50), // SIN CONST
          children: [
            _th('FECHA'),
            _th('TIPO'),
            _th('CANT', align: pw.TextAlign.center),
            _th('DETALLE'),
          ],
        ),
        ...movimientos.map((m) {
          final color = _getColorPorTipo(m.tipo);
          return pw.TableRow(
            children: [
              _td(ArgFormats.fechaHora(m.createdAt)),
              _td(m.tipo.name.toUpperCase(), color: color, isBold: true),
              _td(m.cantidad.toStringAsFixed(2), align: pw.TextAlign.center, isBold: true),
              _td('${m.productoNombre}\n${m.motivo ?? "-"}', isBold: false),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildObservaciones(String? obs) {
    if (obs == null || obs.trim().isEmpty) {
      // Si no hay observaciones, no mostramos nada
      return pw.SizedBox();
    }

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        color: PdfColors.yellow50,
      ),
      child: pw.Text(
        'Observaciones: $obs',
        style: pw.TextStyle(
          fontSize: 10,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  pw.Widget _buildFirmas() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildFirmaBox('Autorizó (S&G)'),
        _buildFirmaBox('Recibí Conforme (Cliente)'),
      ],
    );
  }

  pw.Widget _buildFirmasRemito() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildFirmaBox('Entregué (Chofer/Pañol)'),
        _buildFirmaBox('Recibí Conforme (Obra)'),
      ],
    );
  }

  pw.Widget _buildFirmaBox(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 120, height: 40,
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black))), // SIN CONST
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  pw.Widget _buildFirmaImagen(Uint8List? bytes, String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 140, height: 70,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)), // SIN CONST
          child: bytes != null && bytes.isNotEmpty
              ? pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain)
              : pw.Center(child: pw.Text("[Firma No Disponible]", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Documento generado por el sistema de gestión de materiales S&G',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }

  pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: align),
    );
  }

  pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor? color, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: color, fontWeight: isBold ? pw.FontWeight.bold : null), textAlign: align),
    );
  }
}