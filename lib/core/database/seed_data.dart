import '../../features/stock/data/models/producto_model.dart';
import '../../features/stock/data/models/categoria_model.dart';
import '../../features/clientes/data/models/cliente_model.dart';
import '../../features/stock/data/repositories/producto_repository.dart';
import '../../features/stock/data/repositories/categoria_repository.dart';
import '../../features/stock/data/repositories/stock_repository.dart';
import '../../features/clientes/data/repositories/cliente_repository.dart';

class SeedData {
  final ProductoRepository _productoRepo = ProductoRepository();
  final CategoriaRepository _categoriaRepo = CategoriaRepository();
  final StockRepository _stockRepo = StockRepository();
  final ClienteRepository _clienteRepo = ClienteRepository();

  Future<void> cargarTodo() async {
    print('🌱 Iniciando Seed Data (Firestore)...');

    // Verificación simple para no duplicar
    // Nota: En Firestore real, deberías chequear una colección 'metadata' o similar
    // Aquí intentamos leer categorías, si hay, asumimos que ya se corrió.
    final categorias = await _categoriaRepo.obtenerTodas();
    if (categorias.isNotEmpty) {
      print('ℹ️ Ya existen datos.');
      return;
    }

    await _cargarCategorias();
    await _cargarProductos();
    await _cargarClientes();
    print('✅ Seed Data completado.');
  }

  Future<void> _cargarCategorias() async {
    final categorias = [
      CategoriaModel(codigo: 'OG', nombre: 'Obra General', orden: 1),
      CategoriaModel(codigo: 'H', nombre: 'Hierros', orden: 2),
    ];
    for (var c in categorias) {
      await _categoriaRepo.crear(c);
    }
  }

  Future<void> _cargarProductos() async {
    final productos = [
      ProductoModel(
        codigo: 'OG-001',
        categoriaId: 'OG',
        nombre: 'Cemento Portland',
        unidadBase: 'Bolsa',
        precioSinIva: 12500,
      ),
    ];

    for (var p in productos) {
      await _productoRepo.crear(p);
      // CORRECCIÓN: Usar 'establecer' con parámetros nombrados
      await _stockRepo.establecer(
          productoId: p.codigo,
          cantidad: 100
      );
    }
  }

  Future<void> _cargarClientes() async {
    final cliente = ClienteModel(
      codigo: 'CL-001',
      razonSocial: 'Cliente Demo',
      cuit: '20-11223344-5',
    );
    await _clienteRepo.crear(cliente);
  }
}