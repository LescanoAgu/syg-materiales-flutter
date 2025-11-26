import 'package:flutter/material.dart';
import '../../data/models/obra_model.dart';
import '../../data/repositories/obra_repository.dart';

class ObraProvider extends ChangeNotifier {
  final ObraRepository _repository = ObraRepository();

  List<ObraModel> _obras = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ObraModel> get obras => _obras;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters auxiliares
  int get totalObras => _obras.length;
  bool get hayMasPaginas => false;

  Future<void> cargarObras({bool soloActivas = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _obras = await _repository.obtenerTodas(soloActivas: soloActivas);
    } catch (e) {
      print('Error cargando obras: $e');
      _errorMessage = e.toString();
      _obras = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMasObras() async {
    // Placeholder
  }

  Future<void> buscarObras(String termino) async {
    if (termino.isEmpty) {
      await cargarObras();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final todas = await _repository.obtenerTodas(soloActivas: false);
      _obras = todas.where((o) =>
      o.nombre.toLowerCase().contains(termino.toLowerCase()) ||
          o.direccion.toLowerCase().contains(termino.toLowerCase()) ||
          (o.clienteRazonSocial != null && o.clienteRazonSocial!.toLowerCase().contains(termino.toLowerCase()))
      ).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ABM ---

  Future<bool> crearObra(ObraModel obra) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.crear(obra);
      await cargarObras();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarObra(ObraModel obra) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.actualizar(obra);
      await cargarObras();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String generarNuevoCodigo() {
    if (_obras.isEmpty) return 'OB-001';
    try {
      int maxNum = 0;
      for (var o in _obras) {
        final partes = o.codigo.split('-');
        if (partes.length > 1) {
          final num = int.tryParse(partes[1]) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
      return 'OB-${(maxNum + 1).toString().padLeft(3, '0')}';
    } catch (e) {
      return 'OB-${(_obras.length + 1).toString().padLeft(3, '0')}';
    }
  }
}