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
    // Filtro local simple
    _obras = _obras.where((o) => o.nombre.toLowerCase().contains(t.toLowerCase())).toList();
    notifyListeners();
  }

  // ✅ Método unificado
  Future<bool> guardarObra(ObraModel obra) async {
    try {
      await _repository.guardar(obra);
      await cargarObras();
      return true;
    } catch (e) { return false; }
  }

  // Alias para mantener compatibilidad con pantallas no actualizadas (si las hubiera)
  Future<bool> crearObra(ObraModel o) => guardarObra(o);
  Future<bool> actualizarObra(ObraModel o) => guardarObra(o);

  Future<bool> eliminarObra(String id) async {
    try {
      await _repository.eliminar(id);
      _obras.removeWhere((o) => o.id == id);
      notifyListeners();
      return true;
    } catch (e) { return false; }
  }

  String generarNuevoCodigo() {
    // Generador simple basado en tiempo para evitar colisiones rápidas
    return 'OB-${(DateTime.now().millisecondsSinceEpoch % 10000).toString()}';
  }
}