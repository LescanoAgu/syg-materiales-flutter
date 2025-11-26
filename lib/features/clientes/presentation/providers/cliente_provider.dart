import 'package:flutter/material.dart';
import '../../data/models/cliente_model.dart';
import '../../data/repositories/cliente_repository.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteRepository _repository = ClienteRepository();

  List<ClienteModel> _clientes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Variables de paginación simplificadas
  final bool _hayMasPaginas = false;
  int _totalClientes = 0;

  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  bool get hayMasPaginas => _hayMasPaginas;
  int get totalClientes => _totalClientes;
  String? get errorMessage => _errorMessage;

  // Cargar todos de una vez
  Future<void> cargarClientes({bool soloActivos = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clientes = await _repository.obtenerTodos(soloActivos: soloActivos);
      _totalClientes = _clientes.length;
    } catch (e) {
      print('Error cargando clientes: $e');
      _errorMessage = e.toString();
      _clientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMasClientes() async {
    // Placeholder para paginación futura
    print("Cargar más clientes no implementado en esta versión simplificada");
  }

  Future<void> buscarClientes(String termino) async {
    if (termino.isEmpty) {
      await cargarClientes();
      return;
    }
    // Filtro local (idealmente debería ser en backend para grandes volúmenes)
    _clientes = _clientes.where((c) =>
    c.razonSocial.toLowerCase().contains(termino.toLowerCase()) ||
        c.codigo.toLowerCase().contains(termino.toLowerCase()) ||
        (c.cuit != null && c.cuit!.contains(termino))
    ).toList();
    notifyListeners();
  }

  // --- MÉTODOS CRUD ---

  Future<bool> crearCliente(ClienteModel cliente) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.crear(cliente);
      await cargarClientes(); // Recargar la lista
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarCliente(ClienteModel cliente) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.actualizar(cliente);
      await cargarClientes(); // Recargar la lista para ver los cambios
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método auxiliar para generar códigos automáticos (simple)
  String generarNuevoCodigo() {
    if (_clientes.isEmpty) return 'CL-001';
    // Lógica simple: buscar el último número y sumar 1.
    // En producción idealmente esto se hace en el backend o con una lógica más robusta.
    try {
      // Ordenar por código descendente para tomar el último
      final ultimos = List<ClienteModel>.from(_clientes)
        ..sort((a, b) => b.codigo.compareTo(a.codigo));

      final ultimoCodigo = ultimos.first.codigo; // Ej: CL-005
      final partes = ultimoCodigo.split('-');
      if (partes.length > 1) {
        final numero = int.tryParse(partes[1]) ?? 0;
        return 'CL-${(numero + 1).toString().padLeft(3, '0')}';
      }
    } catch (e) {
      // Fallback si falla el parseo
    }
    return 'CL-${(_clientes.length + 1).toString().padLeft(3, '0')}';
  }
}