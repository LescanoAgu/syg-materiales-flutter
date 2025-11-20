import 'package:flutter/material.dart';
import '../../data/models/obra_model.dart';
import '../../data/repositories/obra_repository.dart';

class ObraProvider extends ChangeNotifier {
  final ObraRepository _repository = ObraRepository();

  List<ObraModel> _obras = [];
  bool _isLoading = false;
  final bool _hayMasPaginas = false;
  int _totalObras = 0;

  List<ObraModel> get obras => _obras; // La UI espera ObraConCliente, pero ObraModel ya tiene los datos
  // Nota: Si la UI rompe aquí, es porque espera estrictamente el tipo 'ObraConCliente'.
  // Lo ideal es cambiar la UI para usar ObraModel, o mapear aquí.

  bool get isLoading => _isLoading;
  bool get hayMasPaginas => _hayMasPaginas;
  int get totalObras => _totalObras;

  Future<void> cargarObras({bool soloActivas = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _obras = await _repository.obtenerTodas(soloActivas: soloActivas);
      _totalObras = _obras.length;
    } catch (e) {
      print('Error cargando obras: $e');
      _obras = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMasObras() async { } // Placeholder

  Future<void> buscarObras(String termino) async {
    if (termino.isEmpty) {
      await cargarObras();
      return;
    }
    // Filtro local rápido
    _obras = _obras.where((o) => o.nombre.toLowerCase().contains(termino.toLowerCase())).toList();
    notifyListeners();
  }

  Future<bool> crearObra(ObraModel obra) async {
    try {
      await _repository.crear(obra);
      await cargarObras();
      return true;
    } catch (e) { return false; }
  }
}