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
  int get totalObras => _obras.length;

  Future<void> cargarObras({bool soloActivas = true}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _obras = await _repository.obtenerTodas(soloActivas: soloActivas);
    } catch (e) {
      _obras = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buscarObras(String t) async {
    if (t.isEmpty) return cargarObras();
    // Filtro local
    _obras = _obras.where((o) => o.nombre.toLowerCase().contains(t.toLowerCase())).toList();
    notifyListeners();
  }

  Future<bool> crearObra(ObraModel obra) async {
    try {
      await _repository.crear(obra);
      await cargarObras();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> actualizarObra(ObraModel obra) async {
    try {
      await _repository.actualizar(obra);
      await cargarObras();
      return true;
    } catch (e) { return false; }
  }

  // ✅ NUEVO: Eliminar
  Future<bool> eliminarObra(String id) async {
    try {
      await _repository.eliminar(id);
      _obras.removeWhere((o) => o.id == id || o.codigo == id);
      notifyListeners();
      return true;
    } catch (e) { return false; }
  }

  String generarNuevoCodigo() {
    if (_obras.isEmpty) return 'OB-001';
    try {
      int max = 0;
      for(var o in _obras) {
        final parts = o.codigo.split('-');
        if (parts.length>1) {
          final n = int.tryParse(parts[1]) ?? 0;
          if(n > max) max = n;
        }
      }
      return 'OB-${(max+1).toString().padLeft(3, '0')}';
    } catch (_) { return 'OB-${(_obras.length+1).toString().padLeft(3,'0')}'; }
  }
}