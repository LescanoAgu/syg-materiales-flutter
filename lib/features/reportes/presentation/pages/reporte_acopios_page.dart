import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../acopios/presentation/providers/acopio_provider.dart';
import '../../data/services/pdf_service.dart';

class ReporteAcopiosPage extends StatefulWidget {
  const ReporteAcopiosPage({super.key});

  @override
  State<ReporteAcopiosPage> createState() => _ReporteAcopiosPageState();
}

class _ReporteAcopiosPageState extends State<ReporteAcopiosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ CORREGIDO: Usamos cargarAcopios que sí existe
      context.read<AcopioProvider>().cargarAcopios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reporte General de Acopios"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              final acopios = context.read<AcopioProvider>().acopios;
              PdfService().generarPdfAcopios(acopios);
            },
          )
        ],
      ),
      body: Consumer<AcopioProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          if (provider.acopios.isEmpty) {
            return const Center(child: Text("No hay acopios registrados"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.acopios.length,
            itemBuilder: (ctx, i) {
              final acopio = provider.acopios[i];
              // Filtramos items con saldo positivo
              final itemsConSaldo = acopio.items.where((it) => it.cantidadDisponible > 0).toList();

              if (itemsConSaldo.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    // ✅ CORREGIDO: clienteRazonSocial
                      acopio.clienteRazonSocial,
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text("En: ${acopio.proveedorNombre} - Actualizado: ${DateFormat('dd/MM/yyyy').format(acopio.fechaUltimoMovimiento)}"), // ✅ CORREGIDO
                  children: itemsConSaldo.map((item) {
                    return ListTile(
                      dense: true,
                      title: Text(item.nombreProducto), // ✅ CORREGIDO: nombreProducto
                      trailing: Text("${item.cantidadDisponible} ${item.unidad}", style: const TextStyle(fontWeight: FontWeight.bold)), // ✅ CORREGIDO
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}