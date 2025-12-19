import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'reporte_stock_page.dart';
import 'reporte_acopios_page.dart';

class ReportesMenuPage extends StatelessWidget {
  const ReportesMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Central de Reportes'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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

          _buildReportCard(
            context: context,
            titulo: "Movimientos de Stock",
            descripcion: "Historial de entradas, salidas y ajustes por fecha.",
            icono: Icons.history_edu,
            color: Colors.blue,
            destino: const ReporteStockPage(),
          ),

          const SizedBox(height: 16),

          _buildReportCard(
            context: context,
            titulo: "Estado de Acopios",
            descripcion: "Saldos a favor de clientes (Billeteras).",
            icono: Icons.account_balance_wallet,
            color: Colors.green,
            destino: const ReporteAcopiosPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
    required Widget destino,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // ✅ Fix deprecated
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(descripcion, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}