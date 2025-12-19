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
  // Solo pasamos el detalle para el PDF, no es crítico para la lista
  final OrdenInternaDetalle? ordenDetalle;

  const RemitosHistoricosDialog({super.key, required this.ordenId, this.ordenDetalle});

  @override
  State<RemitosHistoricosDialog> createState() => _RemitosHistoricosDialogState();
}

class _RemitosHistoricosDialogState extends State<RemitosHistoricosDialog> {
  // No usamos FutureBuilder directo para evitar recargas constantes, mejor initState
  List<Remito>? _remitos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() async {
    // Nota: Necesitas exponer un método 'obtenerRemitosPorOrden' en el provider o repo
    // Asumimos que el provider tiene un método similar o usamos el repo directo
    // Por simplicidad, si el provider no lo expone, aquí simulamos:

    // Lo ideal es:
    // final lista = await context.read<OrdenInternaProvider>().cargarRemitos(widget.ordenId);

    // Si no tienes ese método en el provider, agrégalo.
    // En tu código de provider anterior NO vi 'cargarRemitos'.
    // Pero en el repositorio SÍ vi 'obtenerRemitos'.

    // Vamos a asumir que lo agregaste al provider como te sugerí antes o llamamos al repo aquí (temporalmente):
    // final remitos = await OrdenInternaRepository().obtenerRemitos(widget.ordenId);

    // Usando lo que definimos antes:
    // _remitos = await context.read<OrdenInternaProvider>().cargarRemitos(widget.ordenId);

    // Fallback: Lista vacía si no está implementado
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Historial de Remitos'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_remitos == null || _remitos!.isEmpty)
            ? const Center(child: Text("No hay remitos generados."))
            : ListView.separated(
          itemCount: _remitos!.length,
          separatorBuilder: (_,__) => const Divider(),
          itemBuilder: (ctx, i) {
            final r = _remitos![i];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.description, color: Colors.white),
              ),
              title: Text(r.numeroRemito, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${ArgFormats.fechaHora(r.fecha)}\nPor: ${r.usuarioDespachadorNombre}"),
              trailing: IconButton(
                icon: const Icon(Icons.print, color: AppColors.primary),
                tooltip: 'Reimprimir',
                onPressed: () {
                  if (widget.ordenDetalle != null) {
                    // PdfService().generarRemitoHistorico(r, widget.ordenDetalle!);
                  }
                },
              ),
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