import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Gestor de Base de Datos SQLite
///
/// Esta clase maneja:
/// - Creación de la base de datos
/// - Creación de tablas
/// - Migraciones (actualizaciones de estructura)
/// - Acceso a la base de datos (patrón Singleton)
class DatabaseHelper {
  // ========================================
  // SINGLETON PATTERN
  // ========================================
  // Esto asegura que solo haya UNA instancia de la base de datos

  // Instancia privada única
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // Factory constructor que siempre devuelve la misma instancia
  factory DatabaseHelper() => _instance;

  // Constructor privado
  DatabaseHelper._internal();

  // ========================================
  // CONFIGURACIÓN
  // ========================================

  static const String _databaseName = 'syg_materiales.db';
  static const int _databaseVersion = 1;

  // La base de datos en sí
  static Database? _database;

  /// Obtiene la base de datos (la crea si no existe)
  Future<Database> get database async {
    // Si ya existe, la devuelve
    if (_database != null) return _database!;

    // Si no existe, la crea
    _database = await _initDatabase();
    return _database!;
  }

  // ========================================
  // INICIALIZACIÓN
  // ========================================

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    // Obtiene el path donde se guardan las bases de datos
    String path = join(await getDatabasesPath(), _databaseName);

    print('📁 Ruta de base de datos: $path');

    // Abre/crea la base de datos
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Se ejecuta cuando se crea la base de datos por primera vez
  Future<void> _onCreate(Database db, int version) async {
    print('🏗️  Creando base de datos versión $version...');

    // Ejecuta todas las tablas en orden
    await _createUsuariosTable(db);
    await _createClientesTable(db);
    await _createContactosClienteTable(db);
    await _createObrasTable(db);
    await _createCategoriasTable(db);
    await _createProductosTable(db);
    await _createStockTable(db);
    await _createMovimientosStockTable(db);

    // Carga datos iniciales
    await _seedCategorias(db);

    print('✅ Base de datos creada exitosamente');
  }

  /// Se ejecuta cuando se actualiza la versión de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Actualizando base de datos de v$oldVersion a v$newVersion...');

    // Acá irán las migraciones futuras
    // Por ejemplo:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE productos ADD COLUMN nuevo_campo TEXT');
    // }
  }

  // ========================================
  // CREACIÓN DE TABLAS
  // ========================================

  /// Tabla USUARIOS
  Future<void> _createUsuariosTable(Database db) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        nombre_completo TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        rol TEXT NOT NULL,
        telefono TEXT,
        estado TEXT DEFAULT 'activo',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    // Crear índices para búsquedas más rápidas
    await db.execute('CREATE INDEX idx_usuarios_codigo ON usuarios(codigo)');
    await db.execute('CREATE INDEX idx_usuarios_email ON usuarios(email)');
    await db.execute('CREATE INDEX idx_usuarios_estado ON usuarios(estado)');

    print('  ✓ Tabla usuarios creada');
  }

  /// Tabla CLIENTES
  Future<void> _createClientesTable(Database db) async {
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        razon_social TEXT NOT NULL,
        cuit TEXT,
        condicion_iva TEXT,
        condicion_pago TEXT,
        email TEXT,
        estado TEXT DEFAULT 'activo',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_clientes_codigo ON clientes(codigo)');
    await db.execute('CREATE INDEX idx_clientes_estado ON clientes(estado)');
    await db.execute('CREATE INDEX idx_clientes_cuit ON clientes(cuit)');

    print('  ✓ Tabla clientes creada');
  }

  /// Tabla CONTACTOS_CLIENTE
  Future<void> _createContactosClienteTable(Database db) async {
    await db.execute('''
      CREATE TABLE contactos_cliente (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        tipo TEXT,
        es_principal INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_contactos_cliente_id ON contactos_cliente(cliente_id)',
    );

    print('  ✓ Tabla contactos_cliente creada');
  }

  /// Tabla OBRAS
  Future<void> _createObrasTable(Database db) async {
    await db.execute('''
      CREATE TABLE obras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        cliente_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        direccion TEXT NOT NULL,
        horarios_descarga TEXT,
        contacto_obra TEXT,
        telefono_obra TEXT,
        maestro_obra_nombre TEXT,
        maestro_obra_telefono TEXT,
        responsable_interno_id INTEGER,
        estado TEXT DEFAULT 'activa',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id),
        FOREIGN KEY (responsable_interno_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_obras_codigo ON obras(codigo)');
    await db.execute('CREATE INDEX idx_obras_cliente_id ON obras(cliente_id)');
    await db.execute('CREATE INDEX idx_obras_estado ON obras(estado)');

    print('  ✓ Tabla obras creada');
  }

  /// Tabla CATEGORIAS
  Future<void> _createCategoriasTable(Database db) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        nombre TEXT UNIQUE NOT NULL,
        descripcion TEXT,
        orden INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_categorias_codigo ON categorias(codigo)',
    );

    print('  ✓ Tabla categorias creada');
  }

  /// Tabla PRODUCTOS
  Future<void> _createProductosTable(Database db) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        categoria_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        unidad_base TEXT NOT NULL,
        equivalencia TEXT,
        precio_sin_iva REAL,
        estado TEXT DEFAULT 'activo',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_productos_codigo ON productos(codigo)');
    await db.execute(
      'CREATE INDEX idx_productos_categoria_id ON productos(categoria_id)',
    );
    await db.execute('CREATE INDEX idx_productos_estado ON productos(estado)');

    print('  ✓ Tabla productos creada');
  }

  /// Tabla STOCK
  Future<void> _createStockTable(Database db) async {
    await db.execute('''
      CREATE TABLE stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER UNIQUE NOT NULL,
        cantidad_disponible REAL NOT NULL DEFAULT 0,
        ultima_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_stock_producto_id ON stock(producto_id)',
    );

    print('  ✓ Tabla stock creada');
  }

  /// Tabla MOVIMIENTOS_STOCK
  Future<void> _createMovimientosStockTable(Database db) async {
    await db.execute('''
      CREATE TABLE movimientos_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        cantidad REAL NOT NULL,
        cantidad_anterior REAL NOT NULL,
        cantidad_posterior REAL NOT NULL,
        motivo TEXT,
        referencia TEXT,
        usuario_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (producto_id) REFERENCES productos(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_movimientos_producto_id ON movimientos_stock(producto_id)',
    );
    await db.execute(
      'CREATE INDEX idx_movimientos_tipo ON movimientos_stock(tipo)',
    );
    await db.execute(
      'CREATE INDEX idx_movimientos_created_at ON movimientos_stock(created_at)',
    );

    print('  ✓ Tabla movimientos_stock creada');
  }

  // ========================================
  // DATOS INICIALES (SEED)
  // ========================================

  /// Carga las categorías predefinidas
  Future<void> _seedCategorias(Database db) async {
    print('🌱 Cargando categorías iniciales...');

    final categorias = [
      {
        'codigo': 'A',
        'nombre': 'Agua',
        'descripcion': 'Materiales de agua potable',
        'orden': 1,
      },
      {
        'codigo': 'E',
        'nombre': 'Eléctrico',
        'descripcion': 'Materiales eléctricos',
        'orden': 2,
      },
      {
        'codigo': 'G',
        'nombre': 'Gas',
        'descripcion': 'Materiales de gas',
        'orden': 3,
      },
      {
        'codigo': 'H',
        'nombre': 'Hierros',
        'descripcion': 'Hierros y aceros',
        'orden': 4,
      },
      {
        'codigo': 'M',
        'nombre': 'Maderas',
        'descripcion': 'Maderas y derivados',
        'orden': 5,
      },
      {
        'codigo': 'OG',
        'nombre': 'Obra General',
        'descripcion': 'Cemento, cal, arena, etc.',
        'orden': 6,
      },
      {
        'codigo': 'P',
        'nombre': 'Pintura',
        'descripcion': 'Pinturas y revestimientos',
        'orden': 7,
      },
      {
        'codigo': 'S',
        'nombre': 'Sanitario',
        'descripcion': 'Materiales sanitarios',
        'orden': 8,
      },
    ];

    for (var categoria in categorias) {
      await db.insert('categorias', categoria);
    }

    print('  ✓ ${categorias.length} categorías cargadas');
  }

  // ========================================
  // MÉTODOS AUXILIARES
  // ========================================

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('🔒 Base de datos cerrada');
  }

  /// Elimina la base de datos (útil para testing)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('🗑️  Base de datos eliminada');
  }
}
