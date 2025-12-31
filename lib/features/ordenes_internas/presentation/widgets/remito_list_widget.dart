import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/remito_model.dart';
import '../../data/models/orden_interna_model.dart';
import '../../../reportes/data/services/pdf_service.dart';

class RemitoListWidget extends StatelessWidget {
  final List<Remito> remitos;
  // ✅ NUEVO: Recibimos la orden padre para tener los datos de obra/cliente
  final OrdenInternaDetalle? ordenContexto;
  final bool mostrarCliente;

  const RemitoListWidget({
    super.key,
    required this.remitos,
    this.ordenContexto,
    this.mostrarCliente = true,
  });

  @override
  Widget build(BuildContext context) {
    if (remitos.isEmpty) {
      return const Center(child: Text("No hay remitos registrados", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: remitos.length,
      itemBuilder: (ctx, i) {
        final r = remitos[i];
        final esEntregaProveedor = r.proveedorId != null;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: esEntregaProveedor ? Colors.orange[100] : Colors.blue[100],
              child: Icon(
                esEntregaProveedor ? Icons.local_shipping : Icons.store,
                color: esEntregaProveedor ? Colors.orange : Colors.blue,
              ),
            ),
            title: Text("Remito: ${r.numeroRemito}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd/MM/yyyy HH:mm').format(r.fecha)),
                if (esEntregaProveedor)
                  Text("Entregó: ${r.proveedorNombre ?? 'Externo'}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.print, color: Colors.red),
              tooltip: "Reimprimir PDF",
              onPressed: () => _imprimirRemito(context, r),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: r.items.map((item) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.productoNombre, style: const TextStyle(fontSize: 12))),
                      Text("${item.cantidad} ${item.unidad}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  )).toList(),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _imprimirRemito(BuildContext context, Remito remito) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando PDF..."), duration: Duration(seconds: 1)));

    // ✅ USAMOS DATOS REALES SI EXISTEN
    OrdenInternaDetalle ordenParaPdf;

    if (ordenContexto != null) {
      ordenParaPdf = ordenContexto!;
    } else {
      // Fallback solo si se usa desde el reporte general sin contexto
      ordenParaPdf = OrdenInternaDetalle(
        orden: OrdenInterna(
          id: remito.ordenId,
          numero: 'REF',
          clienteId: remito.clienteId,
          obraId: remito.obraId ?? '',
          solicitanteId: '',
          solicitanteNombre: '',
          fechaCreacion: remito.fecha,
          estado: 'entregado',
          prioridad: 'N/A',
          items: const [],
        ),
        clienteRazonSocial: 'Cliente ID: ${remito.clienteId}', // Mejor que "Consultar"
        obraNombre: 'Obra ID: ${remito.obraId}',
      );
    }

    try {
      await PdfService().generarRemitoHistorico(remito, ordenParaPdf);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }
}