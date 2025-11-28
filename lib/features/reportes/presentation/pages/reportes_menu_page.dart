import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../stock/presentation/pages/stock_page.dart'; // ✅ Importar Home
import 'reporte_stock_page.dart';
import 'reporte_acopios_page.dart';

class ReportesMenuPage extends StatelessWidget {
  const ReportesMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('📊 Reportes'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        // ✅ BOTÓN ATRÁS AGREGADO
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StockPage()),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ... (resto del código igual: Títulos y Cards)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Seleccioná el tipo de reporte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          // ... (Cards de reportes)
          _buildReporteCard(
            context,
            icono: Icons.inventory_2,
            color: AppColors.primary,
            titulo: 'Movimientos de Stock',
            descripcion: 'Entradas, salidas y ajustes de inventario',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReporteStockPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildReporteCard(
            context,
            icono: Icons.business,
            color: AppColors.secondary,
            titulo: 'Acopios por Cliente',
            descripcion: 'Estado de materiales por cliente y proveedor',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReporteAcopiosPage(),
                ),
              );
            },
          ),
          // ... (Resto de cards igual)
        ],
      ),
    );
  }

  // ... (método _buildReporteCard igual)
  Widget _buildReporteCard(
      BuildContext context, {
        required IconData icono,
        required Color color,
        required String titulo,
        required String descripcion,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(descripcion, style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}