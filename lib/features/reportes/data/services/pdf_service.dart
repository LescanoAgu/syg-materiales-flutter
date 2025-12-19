import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../../core/utils/formatters.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../../../ordenes_internas/data/models/orden_interna_model.dart';
import '../../../ordenes_internas/data/models/remito_model.dart';

class PdfService {

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
      return null;
    }
  }

  PdfColor _getColorPorTipo(TipoMovimiento tipo) {
    if (tipo == TipoMovimiento.entrada) return PdfColors.green700;
    if (tipo == TipoMovimiento.salida) return PdfColors.red700;
    return PdfColors.orange700;
  }

  // --- REPORTES DE STOCK ---
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

  // --- ORDEN INTERNA ---
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
          _buildHeader(titulo: 'ORDEN INTERNA', numero: orden.numero, fecha: orden.fechaCreacion, estado: orden.estado, logo: imageLogo),
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

    final obraNombre = ordenDetalle.obraNombre ?? 'Sin Obra';
    final nombreArchivo = '${orden.numero} | ${ordenDetalle.clienteRazonSocial} - $obraNombre.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: nombreArchivo);
  }

  // --- REMITO DE DESPACHO ---
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
          _buildHeader(titulo: 'REMITO DE ENTREGA', numero: 'REF-${orden.numero}', fecha: DateTime.now(), estado: 'ENVIADO', logo: imageLogo),
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

  // --- REMITO HISTÓRICO ---
  Future<void> generarRemitoHistorico(Remito remito, OrdenInternaDetalle ordenDetalle) async {
    await initializeDateFormatting('es_AR', null);
    final pdf = pw.Document();
    final logoBytes = await _cargarLogo();
    final imageLogo = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final firmaAuthBytes = await _descargarImagen(remito.firmaAutorizoUrl);
    final firmaRecBytes = await _descargarImagen(remito.firmaRecibioUrl);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader(titulo: 'REMITO DE ENTREGA', numero: remito.numeroRemito, fecha: remito.fecha, estado: 'ENTREGADO', logo: imageLogo),
          pw.SizedBox(height: 20),
          _buildInfoDespacho(ordenDetalle, remito.usuarioDespachadorNombre),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.teal50),
                children: [
                  _th('ITEM / MATERIAL'),
                  _th('TOTAL', align: pw.TextAlign.center),
                  _th('ENTREGA', align: pw.TextAlign.center),
                  _th('RESTANTE', align: pw.TextAlign.center),
                ],
              ),
              ...remito.items.map((item) {
                final total = item.cantidadSolicitadaTotal;
                final entrega = item.cantidad;
                final saldo = item.saldoPendienteAnterior - entrega;

                return pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    _td(item.productoNombre, isBold: true),
                    _td(total > 0 ? ArgFormats.decimal(total) : "-", align: pw.TextAlign.center),
                    pw.Container(
                      color: PdfColors.green50,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${ArgFormats.decimal(entrega)} ${item.unidad}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    _td(total > 0 ? ArgFormats.decimal(saldo) : "-", align: pw.TextAlign.center),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.Spacer(),
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

  // --- REPORTE ACOPIOS (AQUÍ ESTÁ EL MÉTODO QUE FALTABA) ---
  Future<void> generarPdfAcopios(List<dynamic> acopios) async {
    await initializeDateFormatting('es_AR', null);
    final pdf = pw.Document();
    final logoBytes = await _cargarLogo();
    final imageLogo = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          _buildHeaderGeneral('REPORTE DE ACOPIOS', null, null, imageLogo),
          pw.SizedBox(height: 20),
          ...acopios.map((acopio) {
            // Adaptar según tu modelo de acopios real, aquí asumo dynamic para flexibilidad
            final items = (acopio.items as List<dynamic>? ?? []);
            if (items.isEmpty) return pw.SizedBox();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  color: PdfColors.teal50,
                  width: double.infinity,
                  child: pw.Text(acopio.clienteNombre ?? 'Cliente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 5),
                pw.Text("${items.length} productos con saldo a favor."),
                pw.SizedBox(height: 15),
              ],
            );
          }).toList(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_Acopios.pdf');
  }

  // --- WIDGETS AUX ---
  pw.Widget _buildHeaderGeneral(String titulo, DateTime? desde, DateTime? hasta, pw.ImageProvider? logo) {
    return pw.Column(
      children: [
        pw.Text(titulo, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildHeader({required String titulo, required String numero, required DateTime fecha, required String estado, pw.MemoryImage? logo}) {
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
        ),
      ],
    );
  }

  pw.Widget _buildInfoCliente(OrdenInternaDetalle detalle) {
    return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(5)),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text("CLIENTE", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text(detalle.clienteRazonSocial, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text("OBRA / DESTINO", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text(detalle.obraNombre ?? 'N/A', style: const pw.TextStyle(fontSize: 11)),
              ]),
            ]
        )
    );
  }

  pw.Widget _buildInfoDespacho(OrdenInternaDetalle detalle, String responsable) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text("Destino: ${detalle.obraNombre}"),
        pw.Text("Responsable: $responsable"),
      ],
    );
  }

  pw.Widget _buildTablaProductos(List<OrdenItemDetalle> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.teal50),
          children: [_th('PRODUCTO'), _th('CANT', align: pw.TextAlign.center), _th('UNIDAD', align: pw.TextAlign.center)],
        ),
        ...items.map((item) {
          return pw.TableRow(
            children: [
              _td(item.nombreMaterial),
              _td(ArgFormats.decimal(item.cantidad.toDouble()), align: pw.TextAlign.center, isBold: true),
              _td(item.unidadBase, align: pw.TextAlign.center),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTablaRemitoDinamico(List<Map<String, dynamic>> items, OrdenInternaDetalle detalle) {
    return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          pw.TableRow(children: [_th('Producto'), _th('Cant. Entregada')]),
          ...items.map((i) => pw.TableRow(children: [_td(i['productoNombre']), _td(i['cantidad'].toString())])).toList()
        ]
    );
  }

  pw.Widget _buildTablaMovimientos(List<MovimientoStock> m) => pw.SizedBox();
  pw.Widget _buildObservaciones(String? obs) => obs != null ? pw.Text("Notas: $obs") : pw.SizedBox();
  pw.Widget _buildFirmas() => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [pw.Text("Firma Autoriza"), pw.Text("Firma Recibe")]);
  pw.Widget _buildFirmasRemito() => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [pw.Text("Firma Entrega"), pw.Text("Firma Recibe")]);
  pw.Widget _buildFirmaImagen(Uint8List? b, String l) => pw.SizedBox();
  pw.Widget _buildFooter() => pw.Text("Documento S&G Materiales", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey));
  pw.Widget _th(String t, {pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: align));
  pw.Widget _td(String t, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null), textAlign: align));
}