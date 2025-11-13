import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para manejar operaciones de Firestore
/// Este servicio inicializa la base de datos con datos de ejemplo
class FirestoreService {
  // 1️⃣ Instancia de Firestore (singleton)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicializa la base de datos con datos de ejemplo
  /// Solo debe ejecutarse UNA VEZ
  Future<void> inicializarBaseDatos() async {
    try {
      print('🔄 Iniciando creación de colecciones...');

      // Crear colecciones en orden
      await _crearClientes();
      await _crearObras();
      await _crearProductos();
      await _crearStock();
      await _crearAcopios();
      await _crearMovimientos();

      print('✅ Base de datos inicializada correctamente');
    } catch (e) {
      print('❌ Error al inicializar base de datos: $e');
      rethrow;
    }
  }

  // ========================================
  // 2️⃣ CLIENTES
  // ========================================
  Future<void> _crearClientes() async {
    print('📝 Creando colección: clientes');

    final clientes = [
      {
        'codigo': 'CL-001',
        'razonSocial': 'Constructora San Martín',
        'cuit': '30-12345678-9',
        'direccion': 'Av. San Martín 1234, Mendoza',
        'telefono': '+54 261 423-5678',
        'email': 'contacto@sanmartin.com',
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'CL-002',
        'razonSocial': 'Obras del Valle SA',
        'cuit': '30-98765432-1',
        'direccion': 'Calle Belgrano 567, Mendoza',
        'telefono': '+54 261 445-9876',
        'email': 'info@obrasdelvalle.com',
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'CL-003',
        'razonSocial': 'Constructora Andina',
        'cuit': '30-55566677-8',
        'direccion': 'Ruta 7 Km 10, Luján de Cuyo',
        'telefono': '+54 261 498-3344',
        'email': 'contacto@andina.com.ar',
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
    ];

    for (var cliente in clientes) {
      await _firestore
          .collection('clientes')
          .doc(cliente['codigo'] as String)
          .set(cliente);
    }
    print('✅ Clientes creados: ${clientes.length}');
  }

  // ========================================
  // 3️⃣ OBRAS
  // ========================================
  Future<void> _crearObras() async {
    print('📝 Creando colección: obras');

    final obras = [
      {
        'codigo': 'OB-001',
        'nombre': 'Edificio Torre del Sol',
        'clienteId': 'CL-001',
        'direccion': 'Av. España 2500, Mendoza',
        'responsableObra': 'Ing. Juan Pérez',
        'estado': 'activa', // activa, pausada, finalizada
        'fechaInicio': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'OB-002',
        'nombre': 'Complejo Residencial Las Heras',
        'clienteId': 'CL-002',
        'direccion': 'Calle Las Heras 890, Godoy Cruz',
        'responsableObra': 'Arq. María González',
        'estado': 'activa',
        'fechaInicio': Timestamp.fromDate(DateTime(2024, 3, 1)),
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'OB-003',
        'nombre': 'Centro Comercial Valle Grande',
        'clienteId': 'CL-003',
        'direccion': 'Av. Acceso Este 1200, Luján',
        'responsableObra': 'Ing. Carlos Rodríguez',
        'estado': 'pausada',
        'fechaInicio': Timestamp.fromDate(DateTime(2024, 2, 10)),
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
    ];

    for (var obra in obras) {
      await _firestore
          .collection('obras')
          .doc(obra['codigo'] as String)
          .set(obra);
    }
    print('✅ Obras creadas: ${obras.length}');
  }

  // ========================================
  // 4️⃣ PRODUCTOS
  // ========================================
  Future<void> _crearProductos() async {
    print('📝 Creando colección: productos');

    final productos = [
      {
        'codigo': 'PROD-001',
        'nombre': 'Cemento Portland',
        'descripcion': 'Cemento gris 50kg',
        'unidadMedida': 'BOLSA',
        'categoria': 'Cementicios',
        'precioSinIVA': 8500.0,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'PROD-002',
        'nombre': 'Arena Gruesa',
        'descripcion': 'Arena gruesa para construcción',
        'unidadMedida': 'M3',
        'categoria': 'Áridos',
        'precioSinIVA': 12000.0,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'PROD-003',
        'nombre': 'Ladrillo Hueco 12cm',
        'descripcion': 'Ladrillo hueco cerámico 12x18x33cm',
        'unidadMedida': 'UNIDAD',
        'categoria': 'Mampostería',
        'precioSinIVA': 450.0,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'PROD-004',
        'nombre': 'Hierro 8mm',
        'descripcion': 'Hierro redondo para construcción 8mm x 12m',
        'unidadMedida': 'BARRA',
        'categoria': 'Hierros',
        'precioSinIVA': 3800.0,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'PROD-005',
        'nombre': 'Cal Hidratada',
        'descripcion': 'Cal hidratada bolsa 25kg',
        'unidadMedida': 'BOLSA',
        'categoria': 'Cementicios',
        'precioSinIVA': 2200.0,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
    ];

    for (var producto in productos) {
      await _firestore
          .collection('productos')
          .doc(producto['codigo'] as String)
          .set(producto);
    }
    print('✅ Productos creados: ${productos.length}');
  }

  // ========================================
  // 5️⃣ STOCK
  // ========================================
  Future<void> _crearStock() async {
    print('📝 Creando colección: stock');

    final stocks = [
      {
        'productoId': 'PROD-001',
        'cantidad': 150.0,
        'cantidadMinima': 20.0,
        'ubicacion': 'Depósito Principal - Estante A3',
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      },
      {
        'productoId': 'PROD-002',
        'cantidad': 45.0,
        'cantidadMinima': 10.0,
        'ubicacion': 'Depósito Principal - Sector Áridos',
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      },
      {
        'productoId': 'PROD-003',
        'cantidad': 5000.0,
        'cantidadMinima': 500.0,
        'ubicacion': 'Depósito Principal - Estante B1-B2',
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      },
      {
        'productoId': 'PROD-004',
        'cantidad': 80.0,
        'cantidadMinima': 15.0,
        'ubicacion': 'Depósito Principal - Rack Hierros',
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      },
      {
        'productoId': 'PROD-005',
        'cantidad': 60.0,
        'cantidadMinima': 10.0,
        'ubicacion': 'Depósito Principal - Estante A5',
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      },
    ];

    for (var stock in stocks) {
      await _firestore
          .collection('stock')
          .doc(stock['productoId'] as String)
          .set(stock);
    }
    print('✅ Stock creado: ${stocks.length} productos');
  }

  // ========================================
  // 6️⃣ ACOPIOS
  // ========================================
  Future<void> _crearAcopios() async {
    print('📝 Creando colección: acopios');

    final acopios = [
      {
        'codigo': 'ACOP-001',
        'clienteId': 'CL-001',
        'obraId': 'OB-001',
        'productoId': 'PROD-001',
        'cantidad': 50.0,
        'ubicacion': 'Obra Torre del Sol - Depósito interno',
        'estado': 'activo',
        'responsable': 'Admin',
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'ACOP-002',
        'clienteId': 'CL-002',
        'obraId': 'OB-002',
        'productoId': 'PROD-003',
        'cantidad': 2000.0,
        'ubicacion': 'Obra Las Heras - Sector A',
        'estado': 'activo',
        'responsable': 'Admin',
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo': 'ACOP-003',
        'clienteId': 'CL-001',
        'obraId': 'OB-001',
        'productoId': 'PROD-004',
        'cantidad': 30.0,
        'ubicacion': 'Obra Torre del Sol - Depósito interno',
        'estado': 'activo',
        'responsable': 'Admin',
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
    ];

    for (var acopio in acopios) {
      await _firestore
          .collection('acopios')
          .doc(acopio['codigo'] as String)
          .set(acopio);
    }
    print('✅ Acopios creados: ${acopios.length}');
  }

  // ========================================
  // 7️⃣ MOVIMIENTOS
  // ========================================
  Future<void> _crearMovimientos() async {
    print('📝 Creando colección: movimientos');

    final movimientos = [
      {
        'codigo': 'MOV-2024-001',
        'tipo': 'ENTRADA',
        'productoId': 'PROD-001',
        'cantidad': 100.0,
        'origen': 'Proveedor Loma Negra',
        'destino': 'Stock',
        'obraId': null,
        'clienteId': null,
        'responsable': 'Admin',
        'observaciones': 'Compra mensual programada',
        'fecha': Timestamp.fromDate(DateTime(2024, 10, 15)),
      },
      {
        'codigo': 'MOV-2024-002',
        'tipo': 'SALIDA',
        'productoId': 'PROD-001',
        'cantidad': 50.0,
        'origen': 'Stock',
        'destino': 'Acopio',
        'obraId': 'OB-001',
        'clienteId': 'CL-001',
        'responsable': 'Admin',
        'observaciones': 'Remito para obra Torre del Sol',
        'fecha': Timestamp.fromDate(DateTime(2024, 10, 20)),
      },
      {
        'codigo': 'MOV-2024-003',
        'tipo': 'ENTRADA',
        'productoId': 'PROD-003',
        'cantidad': 3000.0,
        'origen': 'Proveedor Cerámica Andina',
        'destino': 'Stock',
        'obraId': null,
        'clienteId': null,
        'responsable': 'Admin',
        'observaciones': 'Compra para stock general',
        'fecha': Timestamp.fromDate(DateTime(2024, 10, 18)),
      },
      {
        'codigo': 'MOV-2024-004',
        'tipo': 'SALIDA',
        'productoId': 'PROD-003',
        'cantidad': 2000.0,
        'origen': 'Stock',
        'destino': 'Acopio',
        'obraId': 'OB-002',
        'clienteId': 'CL-002',
        'responsable': 'Admin',
        'observaciones': 'Envío a obra Las Heras',
        'fecha': Timestamp.fromDate(DateTime(2024, 10, 25)),
      },
    ];

    for (var movimiento in movimientos) {
      await _firestore
          .collection('movimientos')
          .doc(movimiento['codigo'] as String)
          .set(movimiento);
    }
    print('✅ Movimientos creados: ${movimientos.length}');
  }

  // ========================================
  // 8️⃣ MÉTODOS DE CONSULTA (para usar después)
  // ========================================

  /// Obtiene todos los clientes activos
  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    final snapshot = await _firestore
        .collection('clientes')
        .where('activo', isEqualTo: true)
        .orderBy('razonSocial')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Obtiene todos los productos
  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    final snapshot = await _firestore
        .collection('productos')
        .where('activo', isEqualTo: true)
        .orderBy('nombre')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Obtiene el stock completo
  Future<List<Map<String, dynamic>>> obtenerStock() async {
    final snapshot = await _firestore.collection('stock').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}