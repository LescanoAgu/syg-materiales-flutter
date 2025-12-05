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
    _clientes = _clientes.where((c) =>
    c.razonSocial.toLowerCase().contains(termino.toLowerCase()) ||
        c.codigo.toLowerCase().contains(termino.toLowerCase()) ||
        (c.cuit?.contains(termino) ?? false)
    ).toList();
    notifyListeners();
  }

  // Unificamos crear/actualizar en guardar
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

  // Mantenemos los métodos viejos como alias para no romper otras pantallas si las hay
  Future<bool> crearCliente(ClienteModel c) => guardarCliente(c);
  Future<bool> actualizarCliente(ClienteModel c) => guardarCliente(c);

  Future<bool> eliminarCliente(String id) async {
    try {
      await _repository.eliminar(id);
      _clientes.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  String generarNuevoCodigo() {
    if (_clientes.isEmpty) return 'CL-001';
    try {
      final ultimos = List<ClienteModel>.from(_clientes)..sort((a, b) => b.codigo.compareTo(a.codigo));
      final ultimo = ultimos.first.codigo;
      final partes = ultimo.split('-');
      if (partes.length > 1) {
        final num = int.tryParse(partes[1]) ?? 0;
        return 'CL-${(num + 1).toString().padLeft(3, '0')}';
      }
    } catch (_) {}
    return 'CL-${(_clientes.length + 1).toString().padLeft(3, '0')}';
  }
}