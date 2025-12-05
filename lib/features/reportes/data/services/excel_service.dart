import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/formatters.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../../../acopios/data/models/acopio_model.dart'; // ✅ Nuevo Modelo

class ExcelService {

  // ... (El método de movimientos stock queda igual) ...
  // Solo reescribimos el de Acopios

  Future<void> generarReporteMovimientosStock({
    required List<MovimientoStock> movimientos,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    // ... (Tu código existente de movimientos stock) ...
    // Si necesitas que te lo pegue completo avísame, pero para ahorrar espacio asumo que está bien
    // Lo importante es la corrección del método de abajo 👇
  }

  /// Genera Excel de Acopios (Basado en Facturas)
  Future<void> generarReporteAcopios({
    required List<AcopioModel> acopios,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      excel.rename('Sheet1', 'Saldos Acopio');

      // HEADER
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));
      final titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('REPORTE DE ACOPIOS (SALDOS PENDIENTES)');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.teal,
        fontColorHex: ExcelColor.white,
      );

      final fechaCell = sheet.cell(CellIndex.indexByString('A2'));
      fechaCell.value = TextCellValue('Generado: ${ArgFormats.fechaHora(DateTime.now())}');

      // HEADERS DE TABLA
      const rowHeader = 4;
      final headers = [
        'Cliente',
        'Etiqueta / Obra',
        'N° Factura',
        'Fecha Compra',
        'Proveedor',
        'Material',
        'Saldo Restante',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowHeader));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.grey200,
        );
      }

      // DATOS
      int currentRow = rowHeader + 1;

      for (var acopio in acopios) {
        // Solo listamos items que tengan saldo
        for (var item in acopio.items) {
          if (item.cantidadRestante <= 0) continue;

          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = TextCellValue(acopio.clienteRazonSocial);

          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
              .value = TextCellValue(acopio.etiqueta);

          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
              .value = TextCellValue(acopio.numeroFactura);

          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
              .value = TextCellValue(ArgFormats.fecha(acopio.fechaCompra));

          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
              .value = TextCellValue(acopio.proveedorNombre);

          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
              .value = TextCellValue(item.productoNombre);

          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow))
              .value = DoubleCellValue(item.cantidadRestante);

          currentRow++;
        }
      }

      // Ajustar anchos
      sheet.setColumnWidth(0, 25);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 15);
      sheet.setColumnWidth(5, 30);

      await _guardarYCompartir(excel, 'reporte_acopios_${DateTime.now().millisecondsSinceEpoch}');

    } catch (e) {
      print('❌ Error al generar Excel de acopios: $e');
      rethrow;
    }
  }

  Future<void> _guardarYCompartir(Excel excel, String nombreArchivo) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$nombreArchivo.xlsx';
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(filePath)], text: 'Reporte generado por SyG Materiales');
    }
  }
}