import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/main_layout.dart';
import '../../../../core/enums/app_section.dart';
// Pantallas de destino
import '../../../stock/presentation/pages/stock_page.dart';
import '../../../stock/presentation/pages/movimiento_historial_page.dart'; // ✅ Importado
import '../../../ordenes_internas/presentation/pages/ordenes_page.dart';
import '../../../ordenes_internas/presentation/pages/despachos_list_page.dart';
import '../../../usuarios/presentation/pages/usuarios_list_page.dart';
import '../../../reportes/presentation/pages/reportes_menu_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(title: const Text('Panel de Control')),
      drawer: const AppDrawer(currentSection: AppSection.admin),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KPI HEADER
            Text('Resumen del Día', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildKpiCard(context, 'Pendientes', '3', Colors.orange, Icons.assignment_late),
                const SizedBox(width: 10),
                _buildKpiCard(context, 'En Despacho', '5', Colors.blue, Icons.local_shipping),
              ],
            ),
            const SizedBox(height: 24),

            // 2. MÓDULO STOCK
            Text('Gestión de Stock', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            _buildActionGrid(context, [
              _ActionData(
                  'Stock Maestro',
                  Icons.inventory,
                  AppColors.primary,
                      () => _nav(context, const StockPage())
              ),
              _ActionData(
                  'Movimientos',
                  Icons.history,
                  AppColors.primary,
                  // ✅ CONECTADO
                      () => _nav(context, const MovimientoHistorialPage())
              ),
            ]),

            const SizedBox(height: 24),

            // 3. MÓDULO ÓRDENES
            Text('Centro de Órdenes', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            _buildActionGrid(context, [
              _ActionData(
                  'Gestionar Pedidos',
                  Icons.list_alt,
                  Colors.deepPurple,
                      () => _nav(context, const OrdenesPage())
              ),
              _ActionData(
                  'Área de Despacho',
                  Icons.local_shipping,
                  Colors.deepPurple,
                      () => _nav(context, const DespachosListPage())
              ),
            ]),

            const SizedBox(height: 24),

            // 4. ADMIN ZONE
            Text('Administración', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            Container(
              height: 80,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniBtn(context, Icons.people, 'Equipo', const UsuariosListPage()),
                  _buildMiniBtn(context, Icons.bar_chart, 'Reportes', const ReportesMenuPage()),
                  // Botón Configura: Por ahora placeholder o lista de usuarios también
                  _buildMiniBtn(context, Icons.settings, 'Config', const UsuariosListPage()),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildKpiCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, List<_ActionData> actions) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: actions.map((a) => InkWell(
        onTap: a.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: a.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(a.icon, color: a.color),
              const SizedBox(width: 8),
              Text(a.label, style: TextStyle(color: a.color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildMiniBtn(BuildContext context, IconData icon, String label, Widget page) {
    return InkWell(
      onTap: () => _nav(context, page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

class _ActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionData(this.label, this.icon, this.color, this.onTap);
}