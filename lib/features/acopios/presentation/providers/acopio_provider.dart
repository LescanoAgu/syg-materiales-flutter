import 'package:flutter/material.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../data/repositories/acopio_repository.dart';
import '../../data/repositories/proveedor_repository.dart';
// Importamos para obtener datos completos al registrar movimiento
import '../../../stock/data/repositories/producto_repository.dart';
import '../../../clientes/data/repositories/cliente_repository.dart';

class AcopioProvider extends ChangeNotifier {
  final AcopioRepository _acopioRepo = AcopioRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();

  // Repos adicionales para buscar info al registrar movimiento
  final ProductoRepository _productoRepo = ProductoRepository();
  final ClienteRepository _clienteRepo = ClienteRepository();

  List<AcopioDetalle> _acopios = [];
  List<ProveedorModel> _proveedores = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<AcopioDetalle> get acopios => _acopios;
  List<ProveedorModel> get proveedores => _proveedores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters de UI
  int get totalAcopios => _acopios.length;
  int get totalClientes => _acopios.map((a) => a.clienteRazonSocial).toSet().length;
  int get totalProveedores => _acopios.map((a) => a.proveedorNombre).toSet().length;
  int get totalReservas => _acopios.where((a) => a.esDepositoSyg).length;
  List<AcopioDetalle> get acopiosEnDepositoSyg => _acopios.where((a) => a.esDepositoSyg).toList();
  bool get hasData => _acopios.isNotEmpty;
  bool get hasError => _errorMessage != null;

  Future<void> cargarTodo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([cargarAcopios(), cargarProveedores()]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refrescar() => cargarTodo();

  Future<void> cargarAcopios() async {
    try {
      _acopios = await _acopioRepo.obtenerTodosConDetalle();
      notifyListeners();
    } catch (e) {
      print("Error cargando acopios: $e");
    }
  }

  Future<void> cargarProveedores() async {
    try {
      _proveedores = await _proveedorRepo.obtenerTodos();
      notifyListeners();
    } catch (e) {
      print("Error cargando proveedores: $e");
    }
  }

  // Agrupadores para las vistas de la UI
  Map<String, List<AcopioDetalle>> obtenerAgrupadosPorCliente() {
    var map = <String, List<AcopioDetalle>>{};
    for (var a in _acopios) {
      map.putIfAbsent(a.clienteRazonSocial, () => []).add(a);
    }
    return map;
  }

  Map<String, List<AcopioDetalle>> obtenerAgrupadosPorProveedor() {
    var map = <String, List<AcopioDetalle>>{};
    for (var a in _acopios) {
      map.putIfAbsent(a.proveedorNombre, () => []).add(a);
    }
    return map;
  }

  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    String? productoCodigo, String? clienteCodigo, String? proveedorCodigo
  }) async {
    return await _acopioRepo.obtenerHistorialAcopio(
        productoId: productoCodigo,
        clienteId: clienteCodigo,
        proveedorId: proveedorCodigo
    );
  }

  // --- REGISTRO DE MOVIMIENTOS ---

  Future<bool> registrarMovimiento({
    required String productoId, // Código del producto
    required String clienteId,  // Código del cliente
    required String proveedorId,// Código del proveedor
    required TipoMovimientoAcopio tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
    bool valorizado = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Buscar datos completos para desnormalizar (evitar lecturas futuras)
      final producto = await _productoRepo.obtenerPorCodigo(productoId);
      final cliente = await _clienteRepo.obtenerPorId(clienteId);
      // Buscamos el proveedor en la lista local que ya tenemos cargada
      final proveedor = _proveedores.firstWhere(
              (p) => p.codigo == proveedorId || p.id == proveedorId,
          orElse: () => ProveedorModel(codigo: proveedorId, nombre: 'Desconocido', tipo: TipoProveedor.proveedor, createdAt: DateTime.now())
      );

      if (producto == null || cliente == null) {
        throw Exception("Datos de producto o cliente no encontrados");
      }

      // 2. Llamar al repositorio para ejecutar la transacción
      await _acopioRepo.registrarMovimiento(
        productoId: producto.codigo,
        clienteId: cliente.codigo,
        proveedorId: proveedor.codigo,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,

        // Datos desnormalizados
        productoNombre: producto.nombre,
        productoCodigo: producto.codigo,
        unidadBase: producto.unidadBase,
        categoriaNombre: producto.categoriaNombre ?? '',
        clienteNombre: cliente.razonSocial,
        proveedorNombre: proveedor.nombre,
      );

      // 3. Recargar todo para reflejar cambios
      await cargarTodo();
      return true;

    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filtros placeholders
  void buscarPorProducto(String t) {}
  void limpiarFiltros() {}
  Future<void> filtrarPorFactura(String f) async {}
  Future<List<Map<String, dynamic>>> obtenerFacturasUnicas() async => [];

  // Traspaso (Placeholder - Futura implementación)
  Future<bool> registrarTraspaso({
    required String productoCodigo,
    required String origenClienteCodigo,
    required String origenProveedorCodigo,
    required String destinoClienteCodigo,
    required String destinoProveedorCodigo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
  }) async {
    return true;
  }

  Future<bool> crearProveedor(ProveedorModel proveedor) async {
    _isLoading = true; notifyListeners();
    try {
      await _proveedorRepo.crear(proveedor);
      await cargarProveedores();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> actualizarProveedor(ProveedorModel proveedor) async {
    _isLoading = true; notifyListeners();
    try {
      await _proveedorRepo.actualizar(proveedor);
      await cargarProveedores();
      return true;
    } catch (e) { return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> eliminarProveedor(String id) async {
    try {
      await _proveedorRepo.eliminar(id);
      _proveedores.removeWhere((p) => p.id == id || p.codigo == id);
      notifyListeners();
      return true;
    } catch (e) { return false; }
  }

}