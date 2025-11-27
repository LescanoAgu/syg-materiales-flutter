import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

// Páginas del sistema
import '../../features/stock/presentation/pages/catalogo_page.dart';
import '../../features/clientes/presentation/pages/clientes_list_page.dart';
import '../../features/obras/presentation/pages/obras_list_page.dart';
import '../../features/stock/presentation/pages/movimiento_historial_page.dart';
import '../../features/acopios/presentation/pages/acopios_list_page.dart';
import '../../features/stock/presentation/pages/consultar_disponibilidad_page.dart';
import '../../features/reportes/presentation/pages/reportes_menu_page.dart';
import '../../features/ordenes_internas/presentation/pages/ordenes_page.dart';
import '../../features/stock/presentation/pages/stock_page.dart';

// Auth y Usuarios
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/usuarios/presentation/pages/usuarios_list_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Obtener usuario actual para verificar permisos
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;

    // Es admin si tiene el rol 'admin' O si tiene el permiso explícito 'aprobar_usuarios'
    final bool esAdmin = usuario?.rol == 'admin' || (usuario?.tienePermiso('aprobar_usuarios') ?? false);

    return Drawer(
      child: Column(
        children: [
          // HEADER
          _buildHeader(usuario?.nombre ?? 'Usuario', usuario?.organizationId ?? 'S&G'),

          // LISTA DE OPCIONES
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.book,
                  title: 'Catálogo',
                  subtitle: 'Productos disponibles',
                  onTap: () => _navegar(context, const CatalogoPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Stock',
                  subtitle: 'Inventario actual',
                  onTap: () => _navegar(context, const StockPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.warehouse,
                  title: 'Acopios',
                  subtitle: 'Materiales en proveedores',
                  onTap: () => _navegar(context, const AcopiosListPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.search,
                  title: 'Consultar Disponibilidad',
                  subtitle: 'Buscador rápido',
                  onTap: () => _navegar(context, const ConsultarDisponibilidadPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  title: 'Clientes',
                  subtitle: 'Gestión de clientes',
                  onTap: () => _navegar(context, const ClientesListPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.business,
                  title: 'Obras',
                  subtitle: 'Gestión de obras',
                  onTap: () => _navegar(context, const ObrasListPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.assessment,
                  title: 'Reportes',
                  subtitle: 'Informes y estadísticas',
                  onTap: () => _navegar(context, const ReportesMenuPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Órdenes Internas',
                  subtitle: 'Pedidos y despachos',
                  onTap: () => _navegar(context, const OrdenesPage()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.swap_horiz,
                  title: 'Movimientos',
                  subtitle: 'Historial completo',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MovimientoHistorialPage(),
                      ),
                    );
                  },
                ),

                // 🔐 SECCIÓN ADMINISTRADOR (Solo visible si esAdmin es true)
                if (esAdmin) ...[
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.admin_panel_settings,
                    title: 'Gestión de Equipo',
                    subtitle: 'Usuarios y Permisos',
                    onTap: () => _navegar(context, const UsuariosListPage()),
                  ),
                ],

                const Divider(),

                // 🚪 CERRAR SESIÓN
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  subtitle: 'Salir de la cuenta',
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    context.read<AuthProvider>().logout();
                  },
                ),
              ],
            ),
          ),

          // FOOTER
          _buildFooter(),
        ],
      ),
    );
  }

  // Helper para navegación limpia
  void _navegar(BuildContext context, Widget page) {
    Navigator.pop(context); // Cierra el drawer
    Navigator.pushReplacement( // Reemplaza la pantalla actual
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget _buildHeader(String nombre, String org) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 12),
              Text(nombre, style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 18)),
              Text(org, style: AppTextStyles.body2.copyWith(color: Colors.white.withOpacity(0.9))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 28),
      title: Text(title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.textMedium),
          const SizedBox(width: 8),
          Text('Versión 1.1.0', style: AppTextStyles.caption.copyWith(color: AppColors.textMedium)),
        ],
      ),
    );
  }
}