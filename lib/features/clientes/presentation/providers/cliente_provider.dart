// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firebase
import '../../data/models/cliente_model.dart';
import '../../data/repositories/cliente_repository.dart';

/// Provider de Clientes (Versión Firebase)
class ClienteProvider extends ChangeNotifier {
  // Asumimos que ClienteRepository ya fue migrado
  final ClienteRepository _repository = ClienteRepository();

  // Lista de clientes cargados
  List<ClienteModel> _clientes = [];

  // Estado de carga
  bool _isLoading = false;
  bool _isLoadingMore = false;

  // Cliente seleccionado actualmente
  ClienteModel? _clienteSeleccionado;

  // Total de clientes en la base de datos
  int _totalClientes = 0;

  // ========== ESTADO PARA PAGINACIÓN FIREBASE ==========

  // Cantidad de registros por página
  static const int _registrosPorPagina = 20;

  // ¿Hay más páginas por cargar?
  bool _hayMasPaginas = true;

  // Referencia al último documento cargado (para 'startAfterDocument')
  DocumentSnapshot? _ultimoDocumento;

  // ========================================
  // GETTERS
  // ========================================

  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  ClienteModel? get clienteSeleccionado => _clienteSeleccionado;
  int get totalClientes => _totalClientes;
  bool get hayMasPaginas => _hayMasPaginas;


  // ========================================
  // CARGAR CLIENTES
  // ========================================

  /// Carga la primera página de clientes (limpia la lista)
  Future<void> cargarClientes({bool soloActivos = true}) async {
    _isLoading = true;
    _hayMasPaginas = true;
    _ultimoDocumento = null; // Reiniciar
    notifyListeners();

    try {
      // Primero contar cuántos clientes hay en total
      _totalClientes = await _repository.contarClientes(soloActivos: soloActivos);

      // Cargar la primera página (sin documento de inicio)
      _clientes = await _repository.obtenerConPaginacion(
        limit: _registrosPorPagina,
        ultimoDocumento: null,
        soloActivos: soloActivos,
      );

      // Obtener el último documento de esta carga
      if (_clientes.length < _totalClientes) {
        _ultimoDocumento = await _repository.obtenerUltimoDocumentoDePagina(
          limit: _registrosPorPagina,
          soloActivos: soloActivos,
        );
      } else {
        _ultimoDocumento = null;
      }

      // Verificar si hay más páginas (si se cargaron menos de 20, ya no hay más)
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
    if (_isLoadingMore || !_hayMasPaginas || _ultimoDocumento == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Cargar la siguiente página, iniciando después del último documento
      final List<ClienteModel> nuevosClientes = await _repository.obtenerConPaginacion(
        limit: _registrosPorPagina,
        ultimoDocumento: _ultimoDocumento, // Pasar el último documento para el 'startAfter'
        soloActivos: soloActivos,
      );

      // Si no vinieron nuevos, no hay más páginas
      if (nuevosClientes.isEmpty) {
        _hayMasPaginas = false;
        _ultimoDocumento = null;
      } else {
        // Actualizamos el puntero al último documento
        _ultimoDocumento = await _repository.obtenerUltimoDocumentoDePagina(
          limit: _registrosPorPagina,
          soloActivos: soloActivos,
        );

        // Agregar los nuevos clientes a la lista existente
        _clientes.addAll(nuevosClientes);

        // Verificar si hay más páginas
        _hayMasPaginas = _clientes.length < _totalClientes;
      }

      print('✅ ${nuevosClientes.length} clientes más cargados (total cargado: ${_clientes.length}/$_totalClientes)');
    } catch (e) {
      print('❌ Error al cargar más clientes: $e');
      // No retrocedemos la página, simplemente no avanzamos el puntero
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Busca clientes por término
  Future<void> buscarClientes(String termino, {bool soloActivos = true}) async {
    _isLoading = true;
    _hayMasPaginas = false; // Desactivamos paginación en búsqueda
    notifyListeners();

    try {
      if (termino.isEmpty) {
        // Si borra la búsqueda, volvemos a la carga normal
        await cargarClientes(soloActivos: soloActivos);
      } else {
        // La búsqueda se hace sin paginación (menos óptimo pero simple)
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
      // El repositorio ya no devuelve un int id, sino que usa el código.
      await _repository.crear(cliente);

      // Recargar la lista completa para mantener la coherencia
      await cargarClientes();

      return true;
    } catch (e) {
      print('❌ Error al crear cliente en provider: $e');
      return false;
    }
  }

  /// Actualiza un cliente existente
  Future<bool> actualizarCliente(ClienteModel cliente) async {
    try {
      // El id en el modelo ClienteModel debe ser el código (String)
      await _repository.actualizar(cliente);

      // Recargar la lista completa para mantener la coherencia
      await cargarClientes();

      return true;
    } catch (e) {
      print('❌ Error al actualizar cliente en provider: $e');
      return false;
    }
  }

  /// Elimina un cliente (soft delete)
  /// CAMBIO: Ahora recibe el código (String)
  Future<bool> eliminarCliente(String codigo) async {
    try {
      await _repository.eliminar(codigo); // Llamada con String

      // Recargar la lista
      await cargarClientes();

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