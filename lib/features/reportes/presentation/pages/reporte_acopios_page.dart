import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../acopios/presentation/providers/acopio_provider.dart';
import '../../data/services/excel_service.dart';

class ReporteAcopiosPage extends StatefulWidget {
  const ReporteAcopiosPage({super.key});

  @override
  State<ReporteAcopiosPage> createState() => _ReporteAcopiosPageState();
}

class _ReporteAcopiosPageState extends State<ReporteAcopiosPage> {
  final ExcelService _excelService = ExcelService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AcopioProvider>(
      builder: (context, provider, _) {
        final acopios = provider.acopios;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Reporte de Acopios (Facturas)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                // Conectamos el nuevo método de Excel
                onPressed: () => _excelService.generarReporteAcopios(acopios: acopios),
                tooltip: 'Exportar Excel',
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : acopios.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: acopios.length,
            itemBuilder: (context, index) {
              final a = acopios[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(a.etiqueta, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${a.clienteRazonSocial} • Fact: ${a.numeroFactura}"),
                  trailing: Text(ArgFormats.fecha(a.fechaCompra)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Materiales con saldo pendiente:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ...a.items.where((i) => i.cantidadRestante > 0).map((item) =>
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item.productoNombre),
                                    Text("${item.cantidadRestante.toStringAsFixed(1)} restantes", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No hay acopios registrados'));
  }
}