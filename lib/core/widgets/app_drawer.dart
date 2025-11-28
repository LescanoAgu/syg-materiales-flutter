import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'main_layout.dart'; // Importante para el enum AppSection

// Features
import '../../features/stock/presentation/pages/catalogo_page.dart';
import '../../features/stock/presentation/pages/stock_page.dart';
import '../../features/stock/presentation/pages/consultar_disponibilidad_page.dart';
import '../../features/stock/presentation/pages/movimiento_historial_page.dart';
import '../../features/acopios/presentation/pages/acopios_list_page.dart';
import '../../features/ordenes_internas/presentation/pages/ordenes_page.dart';
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
    this.currentSection = AppSection.stock, // Por defecto Stock
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;
    final bool esAdmin = usuario?.rol == 'admin';

    return Drawer(
      child: Column(
        children: [
          _buildHeader(usuario?.nombre ?? 'Usuario', usuario?.organizationId ?? 'S&G'),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // MENÚ DINÁMICO SEGÚN LA SECCIÓN DEL FOOTER
                if (currentSection == AppSection.stock) ...[
                  _buildSectionHeader('STOCK & MATERIALES'),
                  _buildMenuItem(context, icon: Icons.inventory, title: 'Stock Actual', onTap: () => _navegar(context, const StockPage())),
                  _buildMenuItem(context, icon: Icons.search, title: 'Consultar Disp.', onTap: () => _navegar(context, const ConsultarDisponibilidadPage())),
                  _buildMenuItem(context, icon: Icons.history, title: 'Movimientos', onTap: () => _navegar(context, const MovimientoHistorialPage())),
                  _buildMenuItem(context, icon: Icons.warehouse, title: 'Acopios', onTap: () => _navegar(context, const AcopiosListPage())),

                ] else if (currentSection == AppSection.ordenes) ...[
                  _buildSectionHeader('GESTIÓN DE PEDIDOS'),
                  _buildMenuItem(context, icon: Icons.list_alt, title: 'Órdenes Internas', onTap: () => _navegar(context, const OrdenesPage())),
                  // Placeholder para futuras funciones
                  _buildMenuItem(context, icon: Icons.local_shipping, title: 'Despachos', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente')))),
                  _buildMenuItem(context, icon: Icons.description, title: 'Remitos', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente')))),

                ] else if (currentSection == AppSection.admin) ...[
                  _buildSectionHeader('ADMINISTRACIÓN'),
                  _buildMenuItem(context, icon: Icons.people, title: 'Clientes', onTap: () => _navegar(context, const ClientesListPage())),
                  _buildMenuItem(context, icon: Icons.business, title: 'Obras', onTap: () => _navegar(context, const ObrasListPage())),
                  _buildMenuItem(context, icon: Icons.book, title: 'Catálogo Maestro', onTap: () => _navegar(context, const CatalogoPage())),
                  _buildMenuItem(context, icon: Icons.assessment, title: 'Reportes', onTap: () => _navegar(context, const ReportesMenuPage())),
                  _buildMenuItem(context, icon: Icons.store, title: 'Proveedores', onTap: () => _navegar(context, const ProveedoresListPage()) // ✅ Ahora navega de verdad
                  ),
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

  Widget _buildHeader(String nombre, String org) {
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
              Text(org, style: AppTextStyles.body2.copyWith(color: Colors.white.withOpacity(0.9))),
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
      child: const Text('v1.2.0 - S&G Materiales', style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}