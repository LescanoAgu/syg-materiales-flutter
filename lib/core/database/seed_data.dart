import '../../features/stock/data/models/producto_model.dart';
import '../../features/stock/data/models/stock_model.dart';
import '../../features/stock/data/repositories/producto_repository.dart';
import '../../features/stock/data/repositories/categoria_repository.dart';
import '../../features/stock/data/repositories/stock_repository.dart';
import '../../features/clientes/data/models/cliente_model.dart';
import '../database/database_helper.dart';

/// Clase para cargar datos de prueba en la base de datos
///
/// Carga productos de ejemplo para cada categoría, basados
/// en los datos del diseño de referencia (modern_design_desktop.tsx)
class SeedData {
  final ProductoRepository _productoRepo = ProductoRepository();
  final CategoriaRepository _categoriaRepo = CategoriaRepository();
  final StockRepository _stockRepo = StockRepository();

  /// Carga todos los datos de prueba
  ///
  /// Solo carga si la base de datos está vacía (no hay productos)
  Future<void> cargarTodo() async {
    print('🌱 Verificando datos de prueba...');

    // Verificar si ya hay productos
    int totalProductos = await _productoRepo.contar(soloActivos: false);

    if (totalProductos > 0) {
      print('   ℹ️  Ya existen $totalProductos productos. Omitiendo carga de datos.');
      return;
    }

    print('   📦 Cargando productos de ejemplo...');

    try {
      // Cargar productos por categoría
      await _cargarProductosObraGeneral();
      await _cargarProductosHierros();
      await _cargarProductosPintura();
      await _cargarProductosSanitario();
      await _cargarProductosElectrico();
      await _cargarProductosMaderas();

      // Contar productos cargados
      int total = await _productoRepo.contar();
      print('   ✅ $total productos de ejemplo cargados exitosamente');

      // Cargar stock inicial
      await cargarStockInicial();
      await _cargarClientesPrueba();


    } catch (e) {
      print('   ❌ Error al cargar datos de prueba: $e\n');
    }
  }

  // ========================================
  // OBRA GENERAL
  // ========================================

  Future<void> _cargarProductosObraGeneral() async {
    // Obtener la categoría
    var categoria = await _categoriaRepo.obtenerPorCodigo('OG');
    if (categoria == null) return;

    List<ProductoModel> productos = [
      ProductoModel(
        codigo: 'OG-001',
        categoriaId: categoria.id!,
        nombre: 'Cemento Portland',
        descripcion: 'Cemento Portland tipo CPF-40',
        unidadBase: 'Bolsa',
        equivalencia: '25kg',
        precioSinIva: 12500.00,
      ),
      ProductoModel(
        codigo: 'OG-002',
        categoriaId: categoria.id!,
        nombre: 'Cal Hidráulica',
        descripcion: 'Cal hidráulica para construcción',
        unidadBase: 'Bolsa',
        equivalencia: '25kg',
        precioSinIva: 8900.00,
      ),
      ProductoModel(
        codigo: 'OG-003',
        categoriaId: categoria.id!,
        nombre: 'Arena Gruesa',
        descripcion: 'Arena gruesa para mezcla',
        unidadBase: 'm³',
        equivalencia: null,
        precioSinIva: 15000.00,
      ),
      ProductoModel(
        codigo: 'OG-004',
        categoriaId: categoria.id!,
        nombre: 'Piedra Partida',
        descripcion: 'Piedra partida 6-20mm',
        unidadBase: 'm³',
        equivalencia: null,
        precioSinIva: 18500.00,
      ),
    ];

    for (var producto in productos) {
      await _productoRepo.crear(producto);
    }

    print('      ✓ Obra General: ${productos.length} productos');
  }

  // ========================================
  // HIERROS
  // ========================================

  Future<void> _cargarProductosHierros() async {
    var categoria = await _categoriaRepo.obtenerPorCodigo('H');
    if (categoria == null) return;

    List<ProductoModel> productos = [
      ProductoModel(
        codigo: 'H-001',
        categoriaId: categoria.id!,
        nombre: 'Hierro 8mm',
        descripcion: 'Hierro de construcción 8mm ADN 420',
        unidadBase: 'Unidad',
        equivalencia: '12m',
        precioSinIva: 15200.00,
      ),
      ProductoModel(
        codigo: 'H-002',
        categoriaId: categoria.id!,
        nombre: 'Hierro 10mm',
        descripcion: 'Hierro de construcción 10mm ADN 420',
        unidadBase: 'Unidad',
        equivalencia: '12m',
        precioSinIva: 18500.00,
      ),
      ProductoModel(
        codigo: 'H-003',
        categoriaId: categoria.id!,
        nombre: 'Hierro 12mm',
        descripcion: 'Hierro de construcción 12mm ADN 420',
        unidadBase: 'Unidad',
        equivalencia: '12m',
        precioSinIva: 24800.00,
      ),
      ProductoModel(
        codigo: 'H-004',
        categoriaId: categoria.id!,
        nombre: 'Malla Sima 15x15',
        descripcion: 'Malla electrosoldada 15x15cm',
        unidadBase: 'Rollo',
        equivalencia: '6x2.4m',
        precioSinIva: 32000.00,
      ),
    ];

    for (var producto in productos) {
      await _productoRepo.crear(producto);
    }

    print('      ✓ Hierros: ${productos.length} productos');
  }

  // ========================================
  // PINTURA
  // ========================================

  Future<void> _cargarProductosPintura() async {
    var categoria = await _categoriaRepo.obtenerPorCodigo('P');
    if (categoria == null) return;

    List<ProductoModel> productos = [
      ProductoModel(
        codigo: 'P-001',
        categoriaId: categoria.id!,
        nombre: 'Pintura Látex Blanca',
        descripcion: 'Pintura látex interior blanca',
        unidadBase: 'Litro',
        equivalencia: null,
        precioSinIva: 6800.00,
      ),
      ProductoModel(
        codigo: 'P-002',
        categoriaId: categoria.id!,
        nombre: 'Pintura Esmalte Negro',
        descripcion: 'Esmalte sintético negro brillante',
        unidadBase: 'Litro',
        equivalencia: null,
        precioSinIva: 9200.00,
      ),
      ProductoModel(
        codigo: 'P-003',
        categoriaId: categoria.id!,
        nombre: 'Pintura Latex Exterior',
        descripcion: 'Látex acrílico para exterior blanco',
        unidadBase: 'Litro',
        equivalencia: null,
        precioSinIva: 8500.00,
      ),
      ProductoModel(
        codigo: 'P-004',
        categoriaId: categoria.id!,
        nombre: 'Enduído Plástico',
        descripcion: 'Enduído plástico interior',
        unidadBase: 'Kg',
        equivalencia: null,
        precioSinIva: 1200.00,
      ),
    ];

    for (var producto in productos) {
      await _productoRepo.crear(producto);
    }

    print('      ✓ Pintura: ${productos.length} productos');
  }

  // ========================================
  // SANITARIO
  // ========================================

  Future<void> _cargarProductosSanitario() async {
    var categoria = await _categoriaRepo.obtenerPorCodigo('S');
    if (categoria == null) return;

    List<ProductoModel> productos = [
      ProductoModel(
        codigo: 'S-001',
        categoriaId: categoria.id!,
        nombre: 'Caño PVC 110mm',
        descripcion: 'Caño PVC desagüe cloacal 110mm',
        unidadBase: 'Caño',
        equivalencia: '4m',
        precioSinIva: 4500.00,
      ),
      ProductoModel(
        codigo: 'S-002',
        categoriaId: categoria.id!,
        nombre: 'Caño PVC 63mm',
        descripcion: 'Caño PVC desagüe pluvial 63mm',
        unidadBase: 'Caño',
        equivalencia: '4m',
        precioSinIva: 2800.00,
      ),
      ProductoModel(
        codigo: 'S-003',
        categoriaId: categoria.id!,
        nombre: 'Codo PVC 110mm 45°',
        descripcion: 'Codo PVC 110mm x 45 grados',
        unidadBase: 'Unidad',
        equivalencia: null,
        precioSinIva: 850.00,
      ),
      ProductoModel(
        codigo: 'S-004',
        categoriaId: categoria.id!,
        nombre: 'Inodoro Corto Blanco',
        descripcion: 'Inodoro corto deposito externo blanco',
        unidadBase: 'Unidad',
        equivalencia: null,
        precioSinIva: 45000.00,
      ),
    ];

    for (var producto in productos) {
      await _productoRepo.crear(producto);
    }

    print('      ✓ Sanitario: ${productos.length} productos');
  }

  // ========================================
  // ELÉCTRICO
  // ========================================

  Future<void> _cargarProductosElectrico() async {
    var categoria = await _categoriaRepo.obtenerPorCodigo('E');
    if (categoria == null) return;

    List<ProductoModel> productos = [
      ProductoModel(
        codigo: 'E-001',
        categoriaId: categoria.id!,
        nombre: 'Cable 2.5mm',
        descripcion: 'Cable unipolar 2.5mm²',
        unidadBase: 'm',
        equivalencia: null,
        precioSinIva: 850.00,
      ),
      ProductoModel(
        codigo: 'E-002',
        categoriaId: categoria.id!,
        nombre: 'Cable 4mm',
        descripcion: 'Cable unipolar 4mm²',
        unidadBase: 'm',
        equivalencia: null,
        precioSinIva: 1200.00,
      ),
      ProductoModel(
        codigo: 'E-003',
        categoriaId: categoria.id!,
        nombre: 'Caño Corrugado 3/4',
        descripcion: 'Caño corrugado negro 3/4 pulgada',
        unidadBase: 'm',
        equivalencia: null,
        precioSinIva: 380.00,
      ),
      ProductoModel(
        codigo: 'E-004',
        categoriaId: categoria.id!,
        nombre: 'Toma 10A',
        descripcion: 'Toma corriente 10A con tierra',
        unidadBase: 'Unidad',
        equivalencia: null,
        precioSinIva: 1500.00,
      ),
    ];

    for (var producto in productos) {
      await _productoRepo.crear(producto);
    }

    print('      ✓ Eléctrico: ${productos.length} productos');
  }

  // ========================================
  // MADERAS
  // ========================================

  Future<void> _cargarProductosMaderas() async {
    var categoria = await _categoriaRepo.obtenerPorCodigo('M');
    if (categoria == null) return;

    List<ProductoModel> productos = [
      ProductoModel(
        codigo: 'M-001',
        categoriaId: categoria.id!,
        nombre: 'Tabla Pino 1x4',
        descripcion: 'Tabla de pino cepillada 1x4 pulgadas',
        unidadBase: 'Unidad',
        equivalencia: '3.60m',
        precioSinIva: 3200.00,
      ),
      ProductoModel(
        codigo: 'M-002',
        categoriaId: categoria.id!,
        nombre: 'Tabla Pino 1x6',
        descripcion: 'Tabla de pino cepillada 1x6 pulgadas',
        unidadBase: 'Unidad',
        equivalencia: '3.60m',
        precioSinIva: 4500.00,
      ),
      ProductoModel(
        codigo: 'M-003',
        categoriaId: categoria.id!,
        nombre: 'Tirante 2x4',
        descripcion: 'Tirante de pino 2x4 pulgadas',
        unidadBase: 'Unidad',
        equivalencia: '3.60m',
        precioSinIva: 5800.00,
      ),
      ProductoModel(
        codigo: 'M-004',
        categoriaId: categoria.id!,
        nombre: 'Placa MDF 18mm',
        descripcion: 'Placa MDF 18mm 1.83x2.75m',
        unidadBase: 'Placa',
        equivalencia: '1.83x2.75m',
        precioSinIva: 28000.00,
      ),
    ];

    for (var producto in productos) {
      await _productoRepo.crear(producto);
    }

    print('      ✓ Maderas: ${productos.length} productos');
  }

  // ========================================
  // CARGAR STOCK INICIAL
  // ========================================

  /// Carga stock inicial para los productos
  Future<void> cargarStockInicial() async {
    print('   📦 Cargando stock inicial...');

    try {
      // Verificar si ya hay stock
      var stockBajo = await _stockRepo.contarStockBajo();
      if (stockBajo > 0) {
        print('      ℹ️  Ya existe stock cargado. Omitiendo.');
        return;
      }

      // Stock para cada producto (código → cantidad)
      final Map<String, double> stockInicial = {
        // Obra General
        'OG-001': 50,   // Cemento - stock normal
        'OG-002': 35,   // Cal - stock normal
        'OG-003': 120,  // Arena - alto stock
        'OG-004': 95,   // Piedra - alto stock

        // Hierros
        'H-001': 120,   // Hierro 8mm - alto stock
        'H-002': 95,    // Hierro 10mm - alto stock
        'H-003': 60,    // Hierro 12mm - stock normal
        'H-004': 25,    // Malla - stock normal

        // Pintura
        'P-001': 8,     // Látex Blanca - STOCK BAJO ⚠️
        'P-002': 18,    // Esmalte Negro - stock normal
        'P-003': 22,    // Látex Exterior - stock normal
        'P-004': 45,    // Enduído - stock normal

        // Sanitario
        'S-001': 25,    // Caño 110mm - stock normal
        'S-002': 42,    // Caño 63mm - stock normal
        'S-003': 85,    // Codo - alto stock
        'S-004': 12,    // Inodoro - stock normal

        // Eléctrico
        'E-001': 80,    // Cable 2.5mm - alto stock
        'E-002': 4,     // Cable 4mm - STOCK BAJO ⚠️
        'E-003': 150,   // Caño corrugado - alto stock
        'E-004': 32,    // Toma - stock normal

        // Maderas
        'M-001': 5,     // Tabla 1x4 - STOCK BAJO ⚠️
        'M-002': 18,    // Tabla 1x6 - stock normal
        'M-003': 28,    // Tirante - stock normal
        'M-004': 15,    // Placa MDF - stock normal
      };

      int cargados = 0;

      for (var entry in stockInicial.entries) {
        String codigo = entry.key;
        double cantidad = entry.value;

        // Obtener el producto por código
        ProductoModel? producto = await _productoRepo.obtenerPorCodigo(codigo);

        if (producto != null) {
          // Crear registro de stock
          await _stockRepo.establecer(
            productoId: producto.id!,
            cantidad: cantidad,
          );
          cargados++;
        }
      }

      print('      ✅ Stock inicial cargado: $cargados productos');

      // Mostrar alertas de stock bajo
      int stockBajoCount = await _stockRepo.contarStockBajo();
      if (stockBajoCount > 0) {
        print('      ⚠️  Hay $stockBajoCount productos con stock bajo\n');
      } else {
        print('');
      }

    } catch (e) {
      print('      ❌ Error al cargar stock inicial: $e\n');
    }
  }

  // ========================================
// CLIENTES DE PRUEBA
// ========================================

  Future<void> _cargarClientesPrueba() async {
    print('   👥 Cargando clientes de prueba...');

    try {
      final db = await DatabaseHelper().database;

      final clientes = [
        {
          'codigo': 'CL-001',
          'razon_social': 'Constructora del Sur S.A.',
          'cuit': '30712345678',
          'condicion_iva': 'Responsable Inscripto',
          'condicion_pago': '30 días',
          'email': 'ventas@constructoradelsur.com',
        },
        {
          'codigo': 'CL-002',
          'razon_social': 'Obras Mendocinas S.R.L.',
          'cuit': '30798765432',
          'condicion_iva': 'Responsable Inscripto',
          'condicion_pago': '60 días',
          'email': 'info@obrasmendocinas.com.ar',
        },
        {
          'codigo': 'CL-003',
          'razon_social': 'Juan Pérez',
          'cuit': '20345678901',
          'condicion_iva': 'Monotributista',
          'condicion_pago': 'Contado',
          'email': 'juanperez@gmail.com',
        },
        {
          'codigo': 'CL-004',
          'razon_social': 'Desarrollos Urbanos S.A.',
          'cuit': '30887654321',
          'condicion_iva': 'Responsable Inscripto',
          'condicion_pago': '90 días',
          'email': 'proyectos@desarrollosurbanos.com',
        },
        {
          'codigo': 'CL-005',
          'razon_social': 'María Rodríguez',
          'cuit': '27234567890',
          'condicion_iva': 'Monotributista',
          'condicion_pago': 'Contado',
          'email': 'mrodriguez@hotmail.com',
        },
      ];

      for (var cliente in clientes) {
        await db.insert('clientes', cliente);
      }

      print('      ✅ ${clientes.length} clientes de prueba cargados\n');
    } catch (e) {
      print('      ❌ Error al cargar clientes: $e\n');
    }
  }

}