import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ FALTABA ESTE
import 'package:file_picker/file_picker.dart';         // ✅ FALTABA ESTE
import 'package:csv/csv.dart';                         // ✅ FALTABA ESTE
import '../../data/models/cliente_model.dart';
import '../../data/repositories/cliente_repository.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteRepository _repository = ClienteRepository();
  // ✅ Agregamos la instancia de Firestore para el batch
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ClienteModel> _clientes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarClientes({bool soloActivos = true}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _clientes = await _repository.obtenerTodos(soloActivos: soloActivos);
    } catch (e) {
      _errorMessage = e.toString();
      _clientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buscarClientes(String termino) async {
    if (termino.isEmpty) return cargarClientes();

    final term = termino.toLowerCase();
    _clientes = _clientes.where((c) =>
    c.razonSocial.toLowerCase().contains(term) ||
        c.codigo.toLowerCase().contains(term) ||
        (c.cuit?.contains(term) ?? false)
    ).toList();
    notifyListeners();
  }

  Future<bool> guardarCliente(ClienteModel cliente) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.guardar(cliente);
      await cargarClientes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarCliente(String id) async {
    try {
      await _repository.eliminar(id);
      await cargarClientes();
      return true;
    } catch (e) { return false; }
  }

  // ✅ MÉTODO DE IMPORTACIÓN CORREGIDO (Usa FilePicker)
  Future<String> importarClientesDesdeCSV() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Seleccionar archivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return "Cancelado";

      // 2. Leer y Decodificar CSV
      // Detectamos si estamos en web o móvil para leer el archivo
      final PlatformFile pFile = result.files.single;
      String csvString;

      if (pFile.bytes != null) {
        // Web o bytes cargados en memoria
        csvString = utf8.decode(pFile.bytes!);
      } else {
        // Móvil (Path)
        final file = File(pFile.path!);
        csvString = await file.readAsString();
      }

      // Convertir CSV a Lista
      List<List<dynamic>> fields = const CsvToListConverter().convert(csvString);

      // 3. Procesar Datos
      Map<String, Map<String, dynamic>> clientesMap = {};

      // Iteramos desde 1 para saltar cabecera si existe, o 0 si no
      // Asumiremos que la fila 0 son títulos si contiene texto como "Nombre"
      int startRow = 0;
      if (fields.isNotEmpty && fields[0][0].toString().toLowerCase().contains('nombre')) {
        startRow = 1;
      }

      for (var i = startRow; i < fields.length; i++) {
        final fila = fields[i];
        if (fila.isEmpty) continue;

        // Estructura esperada:
        // 0: Razón Social, 1: CUIT, 2: Tel, 3: Estado (Activo), 4: Obra, 5: Dir Obra

        // Evitamos error de índice
        String getCol(int idx) => fila.length > idx ? fila[idx].toString().trim() : '';

        String razon = getCol(0);
        if (razon.isEmpty) continue; // Nombre obligatorio

        String cuit = getCol(1);
        // Si no hay CUIT, usamos el nombre como clave para agrupar
        String key = cuit.isNotEmpty ? cuit : razon;

        String estadoStr = getCol(3).toLowerCase();
        bool esActivo = estadoStr.isEmpty || estadoStr.contains('activo') || estadoStr == 'true' || estadoStr == 'si' || estadoStr == '1';

        String obraNombre = getCol(4);
        String obraDir = getCol(5);

        if (!clientesMap.containsKey(key)) {
          // Generamos código temporal o dejamos que el backend lo maneje
          // Aquí generamos ID automáticos de Firestore
          clientesMap[key] = {
            'razonSocial': razon,
            'cuit': cuit,
            'telefono': getCol(2),
            'activo': esActivo,
            'obras': <Map<String, String>>[]
          };
        }

        if (obraNombre.isNotEmpty) {
          clientesMap[key]!['obras'].add({
            'nombre': obraNombre,
            'direccion': obraDir
          });
        }
      }

      // 4. Escribir en Firestore (Batch)
      final batch = _firestore.batch();
      int contadorOps = 0;

      for (var entry in clientesMap.values) {
        // Crear Cliente
        final clienteRef = _firestore.collection('clientes').doc();
        // Generar un código simple CL-XXXX (opcional, o dejar vacío)
        String codigoSimulado = "CL-${clienteRef.id.substring(0, 4).toUpperCase()}";

        batch.set(clienteRef, {
          'id': clienteRef.id,
          'codigo': codigoSimulado,
          'razonSocial': entry['razonSocial'],
          'cuit': entry['cuit'],
          'telefono': entry['telefono'],
          'activo': entry['activo'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        contadorOps++;

        // Crear Obras
        List<Map<String, String>> obras = entry['obras'];
        for (var obra in obras) {
          final obraRef = _firestore.collection('obras').doc();
          batch.set(obraRef, {
            'id': obraRef.id,
            'clienteId': clienteRef.id,
            'nombre': obra['nombre'],
            'direccion': obra['direccion'],
            'activo': true,
          });
          contadorOps++;
        }

        // Firestore limita batches a 500 ops. Si tienes muchos, habría que dividir.
        if (contadorOps > 450) {
          await batch.commit();
          contadorOps = 0; // Reiniciar batch nuevo (simplificado para este ejemplo)
        }
      }

      if (contadorOps > 0) await batch.commit();

      // Recargar la lista local
      await cargarClientes();
      return "Éxito: ${clientesMap.length} clientes procesados.";

    } catch (e) {
      print("Error importando: $e");
      return "Error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}