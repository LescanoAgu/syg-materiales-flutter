import 'package:flutter/material.dart';
import '../../data/models/cliente_model.dart';
import '../../data/repositories/cliente_repository.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteRepository _repository = ClienteRepository();

  List<ClienteModel> _clientes = [];
  bool _isLoading = false;
  // Variables de paginación simplificadas
  final bool _hayMasPaginas = false;
  int _totalClientes = 0;

  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  bool get hayMasPaginas => _hayMasPaginas;
  int get totalClientes => _totalClientes;

  // Cargar todos de una vez (Simplificación temporal)
  Future<void> cargarClientes({bool soloActivos = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _clientes = await _repository.obtenerTodos(soloActivos: soloActivos);
      _totalClientes = _clientes.length;
    } catch (e) {
      print('Error cargando clientes: $e');
      _clientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Placeholder para evitar error en UI
  Future<void> cargarMasClientes() async {
    // No hacer nada por ahora, o implementar paginación real más tarde
    print("Cargar más clientes no implementado en esta versión simplificada");
  }

  Future<void> buscarClientes(String termino) async {
    if (termino.isEmpty) {
      await cargarClientes();
      return;
    }
    // Filtro local
    _clientes = _clientes.where((c) =>
    c.razonSocial.toLowerCase().contains(termino.toLowerCase()) ||
        c.codigo.toLowerCase().contains(termino.toLowerCase())
    ).toList();
    notifyListeners();
  }

  // Métodos CRUD
  Future<bool> crearCliente(ClienteModel cliente) async {
    try {
      await _repository.crear(cliente);
      await cargarClientes();
      return true;
    } catch (e) { return false; }
  }
}