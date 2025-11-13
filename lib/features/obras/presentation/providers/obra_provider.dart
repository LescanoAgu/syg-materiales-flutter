// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firebase
import '../../data/models/obra_model.dart';
import '../../data/repositories/obra_repository.dart';

/// Provider de Obras (Versión Firebase)
class ObraProvider extends ChangeNotifier {
  final ObraRepository _repository = ObraRepository();

  // Lista de obras cargadas
  List<ObraConCliente> _obras = [];

  // Estado de carga
  bool _isLoading = false;
  bool _isLoadingMore = false;

  // Obra seleccionada actualmente
  ObraModel? _obraSeleccionada;

  // ========== NUEVAS VARIABLES PARA PAGINACIÓN FIREBASE ==========

  int _paginaActual = 0;
  static const int _registrosPorPagina = 20;
  bool _hayMasPaginas = true;
  int _totalObras = 0;
  DocumentSnapshot? _ultimoDocumento; // Referencia al último documento cargado


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
    _hayMasPaginas = true;
    _ultimoDocumento = null; // Reiniciar paginación
    notifyListeners();

    try {
      // Contar total de obras
      _totalObras = await _repository.contarObras(soloActivas: soloActivas);

      // Cargar primera página
      final obras = await _repository.obtenerConPaginacion(
        limit: _registrosPorPagina,
        soloActivas: soloActivas,
        ultimoDocumento: null,
      );

      _obras = obras;

      // Obtener el último documento de esta carga para la próxima iteración
      if (_obras.length < _totalObras) {
        _ultimoDocumento = await _repository.obtenerUltimoDocumentoDePagina(
          limit: _registrosPorPagina,
          soloActivas: soloActivas,
        );
      } else {
        _ultimoDocumento = null;
      }

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
    if (_isLoadingMore || !_hayMasPaginas || _ultimoDocumento == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Cargar la siguiente página
      final List<ObraConCliente> nuevasObras = await _repository.obtenerConPaginacion(
        limit: _registrosPorPagina,
        soloActivas: soloActivas,
        ultimoDocumento: _ultimoDocumento, // Usar el último documento como puntero
      );

      if (nuevasObras.isEmpty) {
        _hayMasPaginas = false;
        _ultimoDocumento = null;
      } else {
        // Obtener el último documento de la nueva carga
        _ultimoDocumento = await _repository.obtenerUltimoDocumentoDePagina(
          limit: _registrosPorPagina,
          soloActivas: soloActivas,
          ultimoDocumento: _ultimoDocumento,
        );

        _obras.addAll(nuevasObras);
        _hayMasPaginas = _obras.length < _totalObras;
      }

      print('✅ ${nuevasObras.length} obras más cargadas (total: ${_obras.length}/$_totalObras)');
    } catch (e) {
      print('❌ Error al cargar más obras: $e');
      // No retrocedemos la página
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Carga obras de un cliente específico
  /// CAMBIO: clienteCodigo es String
  Future<void> cargarObrasPorCliente(String clienteCodigo, {bool soloActivas = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // El repositorio ya no usa un ID int.
      final obrasCliente = await _repository.obtenerPorCliente(clienteCodigo, soloActivas: soloActivas);

      // El resultado ya es ObraConCliente
      _obras = obrasCliente;
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
    _hayMasPaginas = false; // Desactivar paginación en búsqueda
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
      // El repositorio ya no devuelve int id
      await _repository.crear(obra);

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
  /// CAMBIO: id ahora es el código (String)
  Future<bool> cambiarEstado(String codigo, String nuevoEstado) async {
    try {
      await _repository.cambiarEstado(codigo, nuevoEstado);

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
  Future<String> generarSiguienteCodigoParaCliente(String codigoCliente) async {
    // CAMBIO: clienteId ya no se usa aquí (se usa en el repo, que migré)
    return await _repository.generarSiguienteCodigoParaCliente(codigoCliente);
  }

  /// Verifica si un código ya existe
  Future<bool> existeCodigo(String codigo) async {
    return await _repository.existeCodigo(codigo);
  }

  /// Cuenta obras por cliente
  Future<int> contarObrasPorCliente(String clienteCodigo, {bool soloActivas = true}) async {
    // CAMBIO: clienteId ahora es clienteCodigo
    return await _repository.contarPorCliente(clienteCodigo, soloActivas: soloActivas);
  }
}