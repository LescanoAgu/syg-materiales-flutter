// UBICACIÓN: lib/core/constants/app_roles.dart

class AppRoles {
  // Constructor privado
  AppRoles._();

  // --- 1. IDENTIFICADORES ---
  static const String admin = 'admin';
  static const String jefeObra = 'jefe_obra';
  static const String panolero = 'panolero';
  static const String observador = 'observador';

  // --- 2. ETIQUETAS VISUALES ---
  static const Map<String, String> labels = {
    admin: '🛡️ Administrador',
    jefeObra: '👷 Jefe de Obra',
    panolero: '📦 Pañolero',
    observador: '👀 Observador',
  };

  // --- 3. PERMISOS (Keys) ---
  static const String verPrecios = 'ver_precios';
  static const String crearOrden = 'crear_orden';
  static const String aprobarOrden = 'aprobar_orden'; // 🔒 CRÍTICO: Solo Admin
  static const String gestionarStock = 'gestionar_stock';
  static const String gestionarUsuarios = 'gestionar_usuarios';
  static const String verReportes = 'ver_reportes';

  // --- 4. LÓGICA DE PERMISOS BASE ---
  static bool tienePermisoBase(String rol, String permiso) {
    switch (rol) {
      case admin:
        return true; // Admin hace todo

      case jefeObra:
      // El Jefe de Obra pide material, ve precios y reportes.
      // ❌ YA NO APRUEBA (se eliminó 'aprobarOrden')
        return [
          verPrecios,
          crearOrden, // Solicita
          verReportes,
        ].contains(permiso);

      case panolero:
      // El Pañolero mueve lo físico.
        return [
          crearOrden, // Puede pedir reposición
          gestionarStock, // Entradas/Salidas manuales
        ].contains(permiso);

      case observador:
      // Solo mira
        return [
          verReportes,
        ].contains(permiso);

      default:
        return false;
    }
  }
}