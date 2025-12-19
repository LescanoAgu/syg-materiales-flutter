import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/remito_model.dart';
import '../../data/models/orden_interna_model.dart';
import '../../../reportes/data/services/pdf_service.dart';

class RemitoListWidget extends StatelessWidget {
  final List<Remito> remitos;
  final bool mostrarCliente;

  const RemitoListWidget({
    super.key,
    required this.remitos,
    this.mostrarCliente = true,
  });

  @override
  Widget build(BuildContext context) {
    if (remitos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text("No hay remitos registrados", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
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
            title: Text("Remito #${r.numeroRemito}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd/MM/yyyy HH:mm').format(r.fecha)),
                if (mostrarCliente)
                  Text("Cliente ID: ${r.clienteId}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (esEntregaProveedor)
                  Text("Entregó: ${r.proveedorNombre}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
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

  void _imprimirRemito(BuildContext context, Remito remito) {
    // Creamos el dummy para que el PDF funcione
    final ordenDummy = OrdenInternaDetalle(
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
      clienteRazonSocial: 'Consultar Detalle',
      obraNombre: 'Destino Obra',
    );

    PdfService().generarRemitoHistorico(remito, ordenDummy);
  }
}