import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ IMPORT FALTANTE
import '../../../../core/constants/app_colors.dart';
import '../../../acopios/presentation/providers/acopio_provider.dart'; // ✅ IMPORT FALTANTE
import '../../data/services/excel_service.dart';

class ReporteAcopiosPage extends StatefulWidget {
  const ReporteAcopiosPage({super.key});

  @override
  State<ReporteAcopiosPage> createState() => _ReporteAcopiosPageState();
}

class _ReporteAcopiosPageState extends State<ReporteAcopiosPage> {
  final ExcelService _excelService = ExcelService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAcopios();
  }

  Future<void> _cargarAcopios() async {
    setState(() => _isLoading = true);
    // Usamos el provider para garantizar que la data esté cargada
    await context.read<AcopioProvider>().cargarTodo();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Usamos consumer para escuchar cambios
    return Consumer<AcopioProvider>(
      builder: (context, provider, _) {
        final acopios = provider.acopios; // Lista de BilleteraAcopio

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Reporte de Acopios'),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.table_chart),
                // Deshabilitado temporalmente hasta actualizar el ExcelService
                onPressed: null,
                tooltip: 'Exportar Excel (Próximamente)',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : acopios.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: acopios.length,
            itemBuilder: (context, index) {
              final b = acopios[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(b.clienteNombre),
                  subtitle: Text(b.productoNombre),
                  trailing: Text(
                    '${b.saldoTotal}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text('No hay acopios registrados'),
        ],
      ),
    );
  }
}