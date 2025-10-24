import 'package:flutter/material.dart';
import '../../data/models/obra_model.dart';
import '../../data/repositories/obra_repository.dart';

/// Provider de Obras
///
/// Gestiona el estado de las obras en la aplicación.
class ObraProvider extends ChangeNotifier {
  final ObraRepository _repository = ObraRepository();

  // Lista de obras cargadas
  List<ObraConCliente> _obras = [];

  // Estado de carga
  bool _isLoading = false;

  // Estado de carga de más datos
  bool _isLoadingMore = false;

  // Obra seleccionada actualmente
  ObraModel? _obraSeleccionada;

  // ========== NUEVAS VARIABLES PARA PAGINACIÓN ==========

  int _paginaActual = 0;
  static const int _registrosPorPagina = 20;
  bool _hayMasPaginas = true;
  int _totalObras = 0;

  // ========== GETTERS ==========

  List<ObraConCliente> get obras => _obras;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  ObraModel? get obraSeleccionada => _obraSeleccionada;
  int get totalObras => _totalObras;
  bool get hayMasPaginas => _hayMasPaginas;
  int get paginaActual => _paginaActual;

  // ========================================
  // CARGAR OBRAS
  // ========================================

  /// Carga todas las obras con información del cliente
  /// Carga la primera página de obras
  Future<void> cargarObras({bool soloActivas = true}) async {
    _isLoading = true;
    _paginaActual = 0;
    _hayMasPaginas = true;
    notifyListeners();

    try {
      // Contar total de obras
      _totalObras = await _repository.contarObras(soloActivas: soloActivas);

      // Cargar primera página
      _obras = await _repository.obtenerConPaginacion(
        limit: _registrosPorPagina,
        offset: 0,
        soloActivas: soloActivas,
      );

      // Verificar si hay más páginas
      _hayMasPaginas = _obras.length < _totalObras;

      print('✅ ${_obras.length} obras cargadas (total: $_totalObras)');
    } catch (e) {
      print('❌ Error al cargar obras en provider: $e');
      _obras = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga la siguiente página de obras
  Future<void> cargarMasObras({bool soloActivas = true}) async {
    if (_isLoadingMore || !_hayMasPaginas) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _paginaActual++;
      final int offset = _paginaActual * _registrosPorPagina;

      final List<ObraConCliente> nuevasObras = await _repository.obtenerConPaginacion(
        limit: _registrosPorPagina,
        offset: offset,
        soloActivas: soloActivas,
      );

      _obras.addAll(nuevasObras);
      _hayMasPaginas = _obras.length < _totalObras;

      print('✅ ${nuevasObras.length} obras más cargadas (total: ${_obras.length}/$_totalObras)');
    } catch (e) {
      print('❌ Error al cargar más obras: $e');
      _paginaActual--;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Carga obras de un cliente específico
  Future<void> cargarObrasPorCliente(int clienteId, {bool soloActivas = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final obrasCliente = await _repository.obtenerPorCliente(clienteId, soloActivas: soloActivas);
      // Convertir a ObraConCliente (simplificado sin JOIN)
      _obras = obrasCliente.map((obra) {
        return ObraConCliente(
          obra: obra,
          clienteCodigo: '',
          clienteRazonSocial: '',
        );
      }).toList();
    } catch (e) {
      print('❌ Error al cargar obras del cliente: $e');
      _obras = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca obras por término
  Future<void> buscarObras(String termino, {bool soloActivas = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (termino.isEmpty) {
        await cargarObras(soloActivas: soloActivas);
      } else {
        _obras = await _repository.buscar(termino, soloActivas: soloActivas);
      }
    } catch (e) {
      print('❌ Error al buscar obras: $e');
      _obras = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // OPERACIONES CRUD
  // ========================================

  /// Crea una nueva obra
  Future<bool> crearObra(ObraModel obra) async {
    try {
      final int id = await _repository.crear(obra);

      // Recargar la lista
      await cargarObras();

      return true;
    } catch (e) {
      print('❌ Error al crear obra en provider: $e');
      return false;
    }
  }

  /// Actualiza una obra existente
  Future<bool> actualizarObra(ObraModel obra) async {
    try {
      await _repository.actualizar(obra);

      // Recargar la lista
      await cargarObras();

      return true;
    } catch (e) {
      print('❌ Error al actualizar obra en provider: $e');
      return false;
    }
  }

  /// Cambia el estado de una obra
  Future<bool> cambiarEstado(int id, String nuevoEstado) async {
    try {
      await _repository.cambiarEstado(id, nuevoEstado);

      // Recargar la lista
      await cargarObras();

      return true;
    } catch (e) {
      print('❌ Error al cambiar estado de obra en provider: $e');
      return false;
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Selecciona una obra
  void seleccionarObra(ObraModel? obra) {
    _obraSeleccionada = obra;
    notifyListeners();
  }

  /// Genera el siguiente código disponible para un cliente
  Future<String> generarSiguienteCodigoParaCliente(int clienteId, String codigoCliente) async {
    return await _repository.generarSiguienteCodigoParaCliente(clienteId, codigoCliente);
  }

  /// Verifica si un código ya existe
  Future<bool> existeCodigo(String codigo) async {
    return await _repository.existeCodigo(codigo);
  }

  /// Cuenta obras por cliente
  Future<int> contarObrasPorCliente(int clienteId, {bool soloActivas = true}) async {
    return await _repository.contarPorCliente(clienteId, soloActivas: soloActivas);
  }
}