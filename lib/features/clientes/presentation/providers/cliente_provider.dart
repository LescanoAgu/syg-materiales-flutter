import 'package:flutter/material.dart';
import '../../data/models/cliente_model.dart';
import '../../data/repositories/cliente_repository.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteRepository _repository = ClienteRepository();

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

  // ✅ ESTE ES EL MÉTODO QUE FALTABA
  Future<bool> importarClientes(List<ClienteModel> lista) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.importarMasivos(lista);
      await cargarClientes(); // Recargamos la lista para ver los nuevos
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
}