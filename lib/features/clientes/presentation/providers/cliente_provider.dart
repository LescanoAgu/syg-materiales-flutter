import 'package:flutter/material.dart';
import '../../data/models/cliente_model.dart';
import '../../data/repositories/cliente_repository.dart';

/// Provider de Clientes
///
/// Gestiona el estado de los clientes en la aplicación.
/// Usa ChangeNotifier para notificar cambios a los widgets.
class ClienteProvider extends ChangeNotifier {
  final ClienteRepository _repository = ClienteRepository();

  // Lista de clientes cargados
  List<ClienteModel> _clientes = [];

  // Estado de carga
  bool _isLoading = false;

  // Estado de carga de más datos (scroll infinito)
  bool _isLoadingMore = false;  // ← AGREGAR ESTA LÍNEA

  // Cliente seleccionado actualmente
  ClienteModel? _clienteSeleccionado;

  // Página actual (empieza en 0)
  int _paginaActual = 0;

  // Cantidad de registros por página
  static const int _registrosPorPagina = 20;

  // ¿Hay más páginas por cargar?
  bool _hayMasPaginas = true;

  // Total de clientes en la base de datos
  int _totalClientes = 0;


  // Getters
  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;  // ← NUEVO
  ClienteModel? get clienteSeleccionado => _clienteSeleccionado;
  int get totalClientes => _totalClientes;    // ← MODIFICADO
  bool get hayMasPaginas => _hayMasPaginas;  // ← NUEVO
  int get paginaActual => _paginaActual;      // ← NUEVO

  // ========================================
  // CARGAR CLIENTES
  // ========================================

  /// Carga la primera página de clientes (limpia la lista)
  Future<void> cargarClientes({bool soloActivos = true}) async {
    _isLoading = true;
    _paginaActual = 0;  // ← Reiniciar paginación
    _hayMasPaginas = true;
    notifyListeners();

    try {
      // Primero contar cuántos clientes hay en total
      _totalClientes = await _repository.contarClientes(soloActivos: soloActivos);

      // Cargar la primera página
      _clientes = await _repository.obtenerConPaginacion(
        limit: _registrosPorPagina,
        offset: 0,
        soloActivos: soloActivos,
      );

      // Verificar si hay más páginas
      _hayMasPaginas = _clientes.length < _totalClientes;

      print('✅ ${_clientes.length} clientes cargados (total: $_totalClientes)');
    } catch (e) {
      print('❌ Error al cargar clientes en provider: $e');
      _clientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga la siguiente página de clientes (agrega a la lista existente)
  Future<void> cargarMasClientes({bool soloActivos = true}) async {
    // Si ya estamos cargando o no hay más páginas, no hacer nada
    if (_isLoadingMore || !_hayMasPaginas) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _paginaActual++;  // ← Avanzar a la siguiente página

      final int offset = _paginaActual * _registrosPorPagina;

      final List<ClienteModel> nuevosClientes = await _repository.obtenerConPaginacion(
        limit: _registrosPorPagina,
        offset: offset,
        soloActivos: soloActivos,
      );

      // Agregar los nuevos clientes a la lista existente
      _clientes.addAll(nuevosClientes);

      // Verificar si hay más páginas
      _hayMasPaginas = _clientes.length < _totalClientes;

      print('✅ ${nuevosClientes.length} clientes más cargados (total cargado: ${_clientes.length}/$_totalClientes)');
    } catch (e) {
      print('❌ Error al cargar más clientes: $e');
      _paginaActual--;  // ← Retroceder la página si hubo error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Busca clientes por término
  Future<void> buscarClientes(String termino, {bool soloActivos = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (termino.isEmpty) {
        await cargarClientes(soloActivos: soloActivos);
      } else {
        _clientes = await _repository.buscar(termino, soloActivos: soloActivos);
      }
    } catch (e) {
      print('❌ Error al buscar clientes: $e');
      _clientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // OPERACIONES CRUD
  // ========================================

  /// Crea un nuevo cliente
  Future<bool> crearCliente(ClienteModel cliente) async {
    try {
      final int id = await _repository.crear(cliente);

      // Agregar a la lista local
      _clientes.add(cliente.copyWith(id: id));
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Error al crear cliente en provider: $e');
      return false;
    }
  }

  /// Actualiza un cliente existente
  Future<bool> actualizarCliente(ClienteModel cliente) async {
    try {
      await _repository.actualizar(cliente);

      // Actualizar en la lista local
      final index = _clientes.indexWhere((c) => c.id == cliente.id);
      if (index != -1) {
        _clientes[index] = cliente;
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('❌ Error al actualizar cliente en provider: $e');
      return false;
    }
  }

  /// Elimina un cliente (soft delete)
  Future<bool> eliminarCliente(int id) async {
    try {
      await _repository.eliminar(id);

      // Remover de la lista local
      _clientes.removeWhere((c) => c.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Error al eliminar cliente en provider: $e');
      return false;
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Selecciona un cliente
  void seleccionarCliente(ClienteModel? cliente) {
    _clienteSeleccionado = cliente;
    notifyListeners();
  }

  /// Genera el siguiente código disponible
  Future<String> generarSiguienteCodigo() async {
    return await _repository.generarSiguienteCodigo();
  }

  /// Verifica si un código ya existe
  Future<bool> existeCodigo(String codigo) async {
    return await _repository.existeCodigo(codigo);
  }

  /// Verifica si un CUIT ya existe
  Future<bool> existeCuit(String cuit) async {
    return await _repository.existeCuit(cuit);
  }
}