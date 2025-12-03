import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/remito_model.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../../reportes/data/services/pdf_service.dart';

class RemitosHistoricosDialog extends StatefulWidget {
  final String ordenId;
  final OrdenInternaDetalle ordenDetalle; // Para pasarlo al PDF

  const RemitosHistoricosDialog({super.key, required this.ordenId, required this.ordenDetalle});

  @override
  State<RemitosHistoricosDialog> createState() => _RemitosHistoricosDialogState();
}

class _RemitosHistoricosDialogState extends State<RemitosHistoricosDialog> {
  late Future<List<Remito>> _remitosFuture;

  @override
  void initState() {
    super.initState();
    _remitosFuture = context.read<OrdenInternaProvider>().cargarRemitos(widget.ordenId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Historial de Remitos'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: FutureBuilder<List<Remito>>(
          future: _remitosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return const Center(child: Text("Error al cargar"));

            final remitos = snapshot.data ?? [];
            if (remitos.isEmpty) return const Center(child: Text("No hay remitos generados aún."));

            return ListView.separated(
              itemCount: remitos.length,
              separatorBuilder: (_,__) => const Divider(),
              itemBuilder: (ctx, i) {
                final r = remitos[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.description, color: Colors.white),
                  ),
                  title: Text(r.numeroRemito, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${ArgFormats.fechaHora(r.fecha)}\nPor: ${r.usuarioDespachadorNombre}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.print, color: AppColors.primary),
                    tooltip: 'Reimprimir',
                    onPressed: () => PdfService().generarRemitoHistorico(r, widget.ordenDetalle),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}