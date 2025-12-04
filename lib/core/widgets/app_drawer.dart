import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_roles.dart';
import '../enums/app_section.dart'; // ✅ Importamos el Enum

// Features
import '../../features/stock/presentation/pages/catalogo_page.dart';
import '../../features/stock/presentation/pages/stock_page.dart';
import '../../features/stock/presentation/pages/movimiento_historial_page.dart';
import '../../features/acopios/presentation/pages/acopios_list_page.dart';
import '../../features/ordenes_internas/presentation/pages/ordenes_page.dart';
import '../../features/ordenes_internas/presentation/pages/despachos_list_page.dart';
import '../../features/ordenes_internas/presentation/pages/remitos_list_page.dart';
import '../../features/clientes/presentation/pages/clientes_list_page.dart';
import '../../features/obras/presentation/pages/obras_list_page.dart';
import '../../features/usuarios/presentation/pages/usuarios_list_page.dart';
import '../../features/reportes/presentation/pages/reportes_menu_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/acopios/presentation/pages/proveedores_list_page.dart';

class AppDrawer extends StatelessWidget {
  final AppSection currentSection;

  const AppDrawer({
    super.key,
    this.currentSection = AppSection.stock,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;

    // ✅ Ahora que UsuarioModel está arreglado, esto funcionará
    final bool esAdmin = usuario?.esAdmin ?? false;
    final bool puedeVerReportes = usuario?.tienePermiso(AppRoles.verReportes) ?? false;
    final bool puedeDespachar = usuario?.tienePermiso(AppRoles.gestionarStock) ?? false;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(usuario?.nombre ?? 'Usuario', usuario?.rol.toUpperCase() ?? 'S&G'),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (currentSection == AppSection.stock) ...[
                  _buildSectionHeader('STOCK & MATERIALES'),
                  _buildMenuItem(context, icon: Icons.inventory, title: 'Stock Actual', onTap: () => _navegar(context, const StockPage())),
                  _buildMenuItem(context, icon: Icons.search, title: 'Consultar Disp.', onTap: () => _navegar(context, const StockPage())), // Redirige a StockPage (Super Stock)
                  _buildMenuItem(context, icon: Icons.history, title: 'Movimientos', onTap: () => _navegar(context, const MovimientoHistorialPage())),
                  _buildMenuItem(context, icon: Icons.warehouse, title: 'Acopios', onTap: () => _navegar(context, const AcopiosListPage())),

                ] else if (currentSection == AppSection.ordenes) ...[
                  _buildSectionHeader('GESTIÓN DE PEDIDOS'),
                  _buildMenuItem(context, icon: Icons.list_alt, title: 'Órdenes Internas', onTap: () => _navegar(context, const OrdenesPage())),

                  if (puedeDespachar)
                    _buildMenuItem(context, icon: Icons.local_shipping, title: 'Área de Despacho', onTap: () => _navegar(context, const DespachosListPage())),

                  _buildMenuItem(context, icon: Icons.description, title: 'Remitos Históricos', onTap: () => _navegar(context, const RemitosListPage())),

                ] else if (currentSection == AppSection.admin) ...[
                  _buildSectionHeader('ADMINISTRACIÓN'),
                  _buildMenuItem(context, icon: Icons.people, title: 'Clientes', onTap: () => _navegar(context, const ClientesListPage())),
                  _buildMenuItem(context, icon: Icons.business, title: 'Obras', onTap: () => _navegar(context, const ObrasListPage())),
                  _buildMenuItem(context, icon: Icons.book, title: 'Catálogo Maestro', onTap: () => _navegar(context, const CatalogoPage())),

                  if (puedeVerReportes)
                    _buildMenuItem(context, icon: Icons.assessment, title: 'Reportes', onTap: () => _navegar(context, const ReportesMenuPage())),

                  _buildMenuItem(context, icon: Icons.store, title: 'Proveedores', onTap: () => _navegar(context, const ProveedoresListPage())),

                  if (esAdmin)
                    _buildMenuItem(context, icon: Icons.admin_panel_settings, title: 'Gestión de Equipo', onTap: () => _navegar(context, const UsuariosListPage())),
                ],

                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  subtitle: 'Salir de la cuenta',
                  onTap: () {
                    Navigator.pop(context);
                    context.read<AuthProvider>().logout();
                  },
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  void _navegar(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
    );
  }

  Widget _buildHeader(String nombre, String rol) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: AppColors.primary)),
              const SizedBox(height: 12),
              Text(nombre, style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 18)),
              Text(rol, style: AppTextStyles.body2.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text('v1.3.0 - S&G Materiales', style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}