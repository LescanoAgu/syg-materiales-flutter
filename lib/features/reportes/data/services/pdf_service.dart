import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../../core/utils/formatters.dart';

// Importaciones de Modelos
import '../../../ordenes_internas/data/models/orden_interna_model.dart';
import '../../../ordenes_internas/data/models/remito_model.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';

class PdfService {

  Future<Uint8List> _cargarLogo() async {
    try {
      final byteData = await rootBundle.load('assets/Logo_SYG.png');
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

  // ==========================================
  // 1. GENERACIÓN DE REMITO (CON FIRMAS)
  // ==========================================
  Future<void> generarRemitoEntrega({
    required Remito remito,
    required OrdenInternaDetalle ordenDetalle,
    Uint8List? firmaAutorizaBytes,
    Uint8List? firmaRecibeBytes,
  }) async {
    await initializeDateFormatting('es_AR', null);
    final pdf = pw.Document();
    final logoBytes = await _cargarLogo();
    final imageLogo = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

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
          _buildInfoDespacho(
              ordenDetalle,
              remito.usuarioDespachadorNombre
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              // ✅ SIN CONST AQUÍ
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.teal50),
                children: [
                  _th('MATERIAL / ITEM'),
                  _th('PEDIDO', align: pw.TextAlign.center),
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
                    _td(ArgFormats.decimal(total), align: pw.TextAlign.center),
                    pw.Container(
                      color: PdfColors.green50,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${ArgFormats.decimal(entrega)} ${item.unidad}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)), // ✅ Sin const
                    ),
                    _td(ArgFormats.decimal(saldo), align: pw.TextAlign.center),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildFirmaBox(firmaAutorizaBytes, "Autorizó (S&G)"),
              _buildFirmaBox(firmaRecibeBytes, "Recibió Conforme"),
            ],
          ),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Remito_${remito.numeroRemito}.pdf');
  }

  // ==========================================
  // 2. REPORTE DE MOVIMIENTOS DE STOCK
  // ==========================================
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
                  child: pw.Text('PRODUCTO ID: ${entry.key}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), // ✅ Sin const
                ),
                pw.SizedBox(height: 5),
                pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      // ✅ SIN CONST AQUÍ
                      pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            _th('FECHA'),
                            _th('TIPO'),
                            _th('CANT'),
                            _th('USUARIO'),
                          ]
                      ),
                      ...entry.value.map((m) {
                        final color = _getColorPorTipo(m.tipo);
                        final signo = (m.tipo == TipoMovimiento.entrada || m.tipo == TipoMovimiento.ajustePositivo) ? '+' : '-';
                        return pw.TableRow(
                            children: [
                              _td(ArgFormats.fechaHora(m.fecha)),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  // ✅ Sin const en estilo con color dinámico
                                  child: pw.Text(m.tipo.name.toUpperCase(), style: pw.TextStyle(fontSize: 9, color: color, fontWeight: pw.FontWeight.bold))
                              ),
                              _td('$signo${m.cantidad}', align: pw.TextAlign.right, isBold: true),
                              _td(m.usuarioNombre),
                            ]
                        );
                      }).toList()
                    ]
                ),
                pw.SizedBox(height: 15),
              ],
            );
          }).toList(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_Stock.pdf');
  }

  // ==========================================
  // 3. ORDEN INTERNA
  // ==========================================
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
          _buildFirmasGenericas(),
          pw.SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );

    final obraNombre = ordenDetalle.obraNombre ?? 'Sin Obra';
    final nombreArchivo = '${orden.numero} | ${ordenDetalle.clienteRazonSocial} - $obraNombre.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: nombreArchivo);
  }

  // ==========================================
  // 4. REMITO HISTÓRICO
  // ==========================================
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
          _buildHeader(titulo: 'REMITO DE ENTREGA (HISTÓRICO)', numero: remito.numeroRemito, fecha: remito.fecha, estado: 'ENTREGADO', logo: imageLogo),
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
            },
            children: [
              // ✅ SIN CONST AQUÍ
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.teal50),
                children: [
                  _th('ITEM / MATERIAL'),
                  _th('TOTAL PEDIDO', align: pw.TextAlign.center),
                  _th('ENTREGADO', align: pw.TextAlign.center),
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
                      child: pw.Text('${ArgFormats.decimal(entrega)} ${item.unidad}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)), // ✅ Sin const
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
              _buildFirmaBox(firmaAuthBytes, "Autorizó (S&G)"),
              _buildFirmaBox(firmaRecBytes, "Recibió Conforme"),
            ],
          ),
          pw.SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Remito_${remito.numeroRemito}.pdf');
  }

  // ==========================================
  // 5. REPORTE ACOPIOS
  // ==========================================
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
            final items = (acopio.items as List<dynamic>? ?? []);
            if (items.isEmpty) return pw.SizedBox();
            final itemsConSaldo = items.where((i) => i.cantidadDisponible > 0).toList();
            if (itemsConSaldo.isEmpty) return pw.SizedBox();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    color: PdfColors.teal50,
                    width: double.infinity,
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(acopio.clienteRazonSocial ?? 'Cliente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), // ✅ Sin const
                          pw.Text(acopio.proveedorNombre ?? '', style: const pw.TextStyle(fontSize: 10)),
                        ]
                    )
                ),
                pw.SizedBox(height: 5),
                pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(children: [_th('Producto'), _th('Comprado'), _th('Saldo')]),
                      ...itemsConSaldo.map((i) => pw.TableRow(children: [
                        _td(i.nombreProducto),
                        _td(i.cantidadTotalComprada.toString(), align: pw.TextAlign.center),
                        _td(i.cantidadDisponible.toString(), align: pw.TextAlign.center, isBold: true)
                      ])).toList()
                    ]
                ),
                pw.SizedBox(height: 15),
              ],
            );
          }).toList(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_Acopios.pdf');
  }

  // ==========================================
  // WIDGETS AUXILIARES (BLINDADOS SIN CONST)
  // ==========================================

  pw.Widget _buildHeaderGeneral(String titulo, DateTime? desde, DateTime? hasta, pw.ImageProvider? logo) {
    return pw.Column(
      children: [
        if (logo != null) pw.Image(logo, width: 60, height: 60),
        pw.Text(titulo, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)), // ✅ Sin const
        if (desde != null) pw.Text("Desde: ${ArgFormats.fecha(desde)} - Hasta: ${hasta != null ? ArgFormats.fecha(hasta) : 'Hoy'}"),
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
            pw.Text(titulo, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)), // ✅ Sin const
            pw.Text(numero, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)), // ✅ Sin const
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
                pw.Text("CLIENTE", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), // ✅ Sin const
                pw.Text(detalle.clienteRazonSocial, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)), // ✅ Sin const
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text("OBRA / DESTINO", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), // ✅ Sin const
                pw.Text(detalle.obraNombre ?? 'N/A', style: const pw.TextStyle(fontSize: 11)),
              ]),
            ]
        )
    );
  }

  pw.Widget _buildInfoDespacho(OrdenInternaDetalle detalle, String responsable) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(5)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("DESTINO / OBRA", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)), // ✅ Sin const
            pw.Text(detalle.obraNombre ?? 'Sin especificar', style: const pw.TextStyle(fontSize: 12)),
            pw.Text("Cliente: ${detalle.clienteRazonSocial}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text("RESPONSABLE ENTREGA", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)), // ✅ Sin const
            pw.Text(responsable.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)), // ✅ Sin const
          ]),
        ],
      ),
    );
  }

  pw.Widget _buildTablaProductos(List<OrdenItemDetalle> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // ✅ SIN CONST AQUÍ
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

  // ✅ CORREGIDO: Eliminados const
  pw.Widget _buildObservaciones(String? obs) => obs != null && obs.isNotEmpty
      ? pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Text("Notas: $obs", style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
  )
      : pw.SizedBox();

  // ✅ CORREGIDO: Eliminados const
  pw.Widget _buildFirmaBox(Uint8List? firmaBytes, String etiqueta) {
    return pw.Column(
      children: [
        pw.Container(
          width: 150,
          height: 80,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
          child: firmaBytes != null
              ? pw.Image(pw.MemoryImage(firmaBytes), fit: pw.BoxFit.contain)
              : pw.Center(child: pw.Text("Sin Firma", style: pw.TextStyle(color: PdfColors.grey))),
        ),
        pw.SizedBox(height: 5),
        pw.Text(etiqueta, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)), // ✅ Sin const
      ],
    );
  }

  pw.Widget _buildFirmasGenericas() => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildFirmaBox(null, "Autorizó"),
        _buildFirmaBox(null, "Solicitó")
      ]
  );

  // ✅ CORREGIDO: Eliminados const
  pw.Widget _buildFooter() => pw.Column(
      children: [
        pw.Divider(),
        pw.Text("Documento generado por Sistema S&G Materiales", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ]
  );

  pw.Widget _th(String t, {pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: align)); // ✅ Sin const
  pw.Widget _td(String t, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null, fontSize: 10), textAlign: align)); // ✅ Sin const

// ==========================================
  // 6. NUEVO: ORDEN DE PEDIDO (PARA CLIENTE)
  // ==========================================
  Future<void> generarOrdenDePedido(OrdenInternaDetalle ordenDetalle) async {
    await initializeDateFormatting('es_AR', null);
    final pdf = pw.Document();
    final logoBytes = await _cargarLogo();
    final imageLogo = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final orden = ordenDetalle.orden;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader(
              titulo: 'ORDEN DE PEDIDO', // Título cambiado
              numero: orden.numero,
              fecha: orden.fechaCreacion,
              estado: orden.estado,
              logo: imageLogo
          ),
          pw.SizedBox(height: 20),
          _buildInfoCliente(ordenDetalle), // Usamos info cliente, no despacho
          pw.SizedBox(height: 10),
          pw.Container(
              padding: const pw.EdgeInsets.all(5),
              color: PdfColors.grey200,
              child: pw.Row(children: [
                pw.Text("Prioridad: ${orden.prioridad.toUpperCase()}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Spacer(),
                pw.Text("Origen: ${orden.origen.name.toUpperCase()}", style: const pw.TextStyle(fontSize: 10)),
              ])
          ),
          pw.SizedBox(height: 20),
          // Tabla simplificada (Solo lo pedido)
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                children: [_th('PRODUCTO / MATERIAL'), _th('CANTIDAD', align: pw.TextAlign.center), _th('UNIDAD', align: pw.TextAlign.center)],
              ),
              ...ordenDetalle.items.map((item) {
                return pw.TableRow(
                  children: [
                    _td(item.nombreMaterial, isBold: true),
                    _td(ArgFormats.decimal(item.cantidad.toDouble()), align: pw.TextAlign.center, isBold: true),
                    _td(item.unidadBase, align: pw.TextAlign.center),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 20),
          _buildObservaciones(orden.observacionesCliente),
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Pedido_${orden.numero}.pdf');
  }

}