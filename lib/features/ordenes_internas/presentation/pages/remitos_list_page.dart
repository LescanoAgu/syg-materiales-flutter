import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/remito_model.dart';
// ✅ CORREGIDO: Import único
import '../../data/models/orden_interna_model.dart';
import '../../../reportes/data/services/pdf_service.dart';

class RemitosListPage extends StatelessWidget {
  const RemitosListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Remitos"), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('remitos').orderBy('fecha', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay remitos generados"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final remito = Remito.fromMap(data, docs[i].id);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.receipt_long, color: Colors.green),
                  ),
                  title: Text("Remito #${remito.numeroRemito}"),
                  subtitle: Text("${DateFormat('dd/MM/yyyy HH:mm').format(remito.fecha)}\nDespachó: ${remito.usuarioDespachadorNombre}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    onPressed: () {
                      // ✅ CORRECCIÓN: Dummy object actualizado
                      final ordenDummy = OrdenInternaDetalle(
                        orden: OrdenInterna(
                            id: remito.ordenId,
                            numero: 'REF',
                            clienteId: 'N/A',
                            obraId: 'N/A',
                            solicitanteId: 'N/A',
                            solicitanteNombre: 'N/A',
                            fechaCreacion: DateTime.now(),
                            estado: 'completado',
                            prioridad: 'baja',
                            items: const [] // Lista vacía
                        ),
                        clienteRazonSocial: 'Consultar Detalle',
                      );

                      PdfService().generarRemitoHistorico(remito, ordenDummy);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}