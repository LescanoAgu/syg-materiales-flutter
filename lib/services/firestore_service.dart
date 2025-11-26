import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> inicializarBaseDatos() async {
    try {
      print('🔄 INICIANDO CARGA MASIVA DE DATOS...');

      // 1. Clientes
      await _crearSiNoExiste('clientes', 'CL-001', {
        'codigo': 'CL-001',
        'razonSocial': 'Constructora San Martín',
        'cuit': '30-12345678-9',
        'estado': 'activo',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. Obras (Vinculadas al CL-001)
      await _crearSiNoExiste('obras', 'OB-001', {
        'codigo': 'OB-001',
        'nombre': 'Torre del Sol',
        'clienteId': 'CL-001',
        'clienteRazonSocial': 'Constructora San Martín', // Desnormalizado clave!
        'clienteCodigo': 'CL-001',
        'direccion': 'Av. España 2500',
        'estado': 'activa',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 3. Productos (Tus 4 ejemplos + algunos extra)
      final productos = [
        {'codigo': 'LAD-H-12', 'nombre': 'Ladrillo Hueco 12x18x33', 'precioSinIva': 650.0, 'categoriaId': 'OG'},
        {'codigo': 'LAD-H-18', 'nombre': 'Ladrillo Hueco 18x18x33', 'precioSinIva': 920.0, 'categoriaId': 'OG'},
        {'codigo': 'CEM-AVE', 'nombre': 'Cemento Avellaneda 50kg', 'precioSinIva': 10500.0, 'categoriaId': 'OG'},
        {'codigo': 'HIE-06', 'nombre': 'Hierro del 6', 'precioSinIva': 4200.0, 'categoriaId': 'H'},
      ];

      for (var p in productos) {
        await _crearSiNoExiste('productos', p['codigo'] as String, {
          ...p,
          'unidadBase': 'u',
          'estado': 'activo',
          'cantidadDisponible': 100.0, // Stock inicial visual
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Crear documento espejo en stock
        await _firestore.collection('stock').doc(p['codigo'] as String).set({
          'productoId': p['codigo'],
          'cantidadDisponible': 100.0,
          'ultimaActualizacion': DateTime.now().toIso8601String(),
        });
      }

      print('✅ BASE DE DATOS INICIALIZADA CON ÉXITO');
    } catch (e) {
      print('❌ Error fatal en Seed Data: $e');
      rethrow;
    }
  }

  // Helper para no sobrescribir si ya existe (opcional, pero seguro)
  Future<void> _crearSiNoExiste(String coleccion, String docId, Map<String, dynamic> data) async {
    final docRef = _firestore.collection(coleccion).doc(docId);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set(data);
      print(' -> Creado: $coleccion/$docId');
    } else {
      print(' -> Ya existe: $coleccion/$docId');
    }
  }
}