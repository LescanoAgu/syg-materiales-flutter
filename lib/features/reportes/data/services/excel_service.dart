import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// Imports de modelos
import '../../../acopios/data/models/acopio_model.dart';
import '../../../stock/data/models/movimiento_stock_model.dart'; // Asegúrate de tener este import

class ExcelService {

  // --- REPORTE DE STOCK (El que faltaba) ---
  Future<void> generarReporteMovimientos(List<MovimientoStock> movimientos) async {
    final excel = Excel.createExcel();
    final sheet = excel['Movimientos'];

    // Header
    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Tipo'),
      TextCellValue('Producto'),
      TextCellValue('Cantidad'),
      TextCellValue('Usuario'),
      TextCellValue('Motivo'),
    ]);

    for (var m in movimientos) {
      sheet.appendRow([
        // Asumiendo que tu modelo MovimientoStock tiene un campo 'fecha' o 'createdAt'
        // Ajusta 'm.fecha' según tu modelo real
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(m.fecha)),
        TextCellValue(m.tipo.toString().split('.').last.toUpperCase()),
        TextCellValue(m.productoNombre),
        DoubleCellValue(m.cantidad.toDouble()),
        TextCellValue(m.usuarioNombre),
        TextCellValue(m.motivo ?? ''),
      ]);
    }

    final fileBytes = excel.save();
    await _guardarYCompartir(fileBytes, 'Reporte_Stock.xlsx', 'Reporte de Stock');
  }

  // --- REPORTE DE ACOPIOS ---
  Future<void> generarReporteAcopios(List<AcopioModel> acopios) async {
    final excel = Excel.createExcel();
    final sheet = excel['Acopios'];

    // Header
    sheet.appendRow([
      TextCellValue('Cliente'),
      TextCellValue('Proveedor / Ubicación'),
      TextCellValue('Producto'),
      TextCellValue('Total Comprado'),
      TextCellValue('Saldo Disponible'),
      TextCellValue('Último Movimiento'),
    ]);

    for (var acopio in acopios) {
      for (var item in acopio.items) {
        if (item.cantidadDisponible > 0) {
          sheet.appendRow([
            TextCellValue(acopio.clienteRazonSocial),
            TextCellValue(acopio.proveedorNombre),
            TextCellValue(item.nombreProducto),
            DoubleCellValue(item.cantidadTotalComprada),
            DoubleCellValue(item.cantidadDisponible),
            TextCellValue(DateFormat('dd/MM/yyyy').format(acopio.fechaUltimoMovimiento)),
          ]);
        }
      }
    }

    final fileBytes = excel.save();
    await _guardarYCompartir(fileBytes, 'Reporte_Acopios.xlsx', 'Reporte de Acopios');
  }

  // --- HELPER PRIVADO ---
  Future<void> _guardarYCompartir(List<int>? bytes, String nombreArchivo, String texto) async {
    if (bytes == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$nombreArchivo');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: texto);
    } catch (e) {
      print("Error guardando/compartiendo Excel: $e");
    }
  }
}