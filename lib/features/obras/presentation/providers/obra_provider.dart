import 'package:flutter/material.dart';
import '../../data/models/obra_model.dart';
import '../../data/repositories/obra_repository.dart';

class ObraProvider extends ChangeNotifier {
  final ObraRepository _repository = ObraRepository();

  List<ObraModel> _obras = [];
  bool _isLoading = false;

  List<ObraModel> get obras => _obras;
  bool get isLoading => _isLoading;

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

  Future<bool> guardarObra(ObraModel obra) async {
    try {
      await _repository.guardar(obra);
      await cargarObras();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> eliminarObra(String id) async {
    try {
      await _repository.eliminar(id);
      await cargarObras();
      return true;
    } catch (e) { return false; }
  }
}