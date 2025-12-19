import 'package:flutter/material.dart';
import '../../data/models/orden_interna_model.dart';
import '../widgets/dialogo_aprobar_orden.dart';
import 'package:provider/provider.dart';
import '../providers/orden_interna_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OrdenDetallePage extends StatefulWidget {
  final OrdenInterna orden;

  const OrdenDetallePage({Key? key, required this.orden}) : super(key: key);

  @override
  State<OrdenDetallePage> createState() => _OrdenDetallePageState();
}

class _OrdenDetallePageState extends State<OrdenDetallePage> {
  late OrdenInterna ordenActual;
  bool _editandoDespacho = false;
  TipoDespacho? _tipoDespachoSeleccionado;

  @override
  void initState() {
    super.initState();
    ordenActual = widget.orden;
    _tipoDespachoSeleccionado = ordenActual.tipoDespacho;
  }

  void _mostrarDialogoAprobacion() {
    showDialog(
      context: context,
      builder: (context) => DialogoAprobarOrden(
        orden: ordenActual,
        onAprobar: (itemsModificados, observacion, proveedor) async {
          final user = context.read<AuthProvider>().usuario;

          final exito = await context.read<OrdenInternaProvider>().aprobarOrden(
              ordenId: ordenActual.id!,
              usuarioId: user?.uid ?? 'admin',
              itemsModificados: itemsModificados,
              observaciones: observacion,
              proveedor: proveedor
          );

          if (exito && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Orden Aprobada")));

            setState(() {
              // ✅ CORREGIDO: Usamos proveedorNombre
              ordenActual = OrdenInternaModel(
                  id: ordenActual.id,
                  numero: ordenActual.numero,
                  clienteId: ordenActual.clienteId,
                  obraId: ordenActual.obraId,
                  solicitanteId: ordenActual.solicitanteId,
                  solicitanteNombre: ordenActual.solicitanteNombre,
                  fechaCreacion: ordenActual.fechaCreacion,
                  estado: 'aprobada',
                  prioridad: ordenActual.prioridad,
                  items: itemsModificados,
                  destino: ordenActual.destino,
                  observaciones: ordenActual.observaciones,
                  observacionesAprobacion: observacion,
                  proveedorNombre: proveedor, // CORREGIDO AQUÍ
                  tipoDespacho: ordenActual.tipoDespacho,
                  modificadoPor: user?.nombre,
                  titulo: ordenActual.titulo,
                  observacionesCliente: ordenActual.observacionesCliente,
                  esRetiroAcopio: ordenActual.esRetiroAcopio,
                  acopioId: ordenActual.acopioId
              );
            });
          }
        },
      ),
    );
  }

  void _guardarCambiosDespacho() {
    setState(() {
      _editandoDespacho = false;
      // Aquí actualizamos solo visualmente por ahora
      // En una implementación real, llamarías a un método update en el provider
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orden ${ordenActual.numero}'),
        actions: [
          if (ordenActual.estado == 'solicitado' || ordenActual.estado == 'pendiente')
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Revisar y Aprobar',
              onPressed: _mostrarDialogoAprobacion,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildEstadoCard(),
          const SizedBox(height: 16),
          if (ordenActual.estado != 'solicitado' && ordenActual.estado != 'pendiente')
            _buildLogisticaSection(),
          const SizedBox(height: 16),
          Text('Materiales Solicitados', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...ordenActual.items.map((item) => Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2),
              title: Text(item.nombreMaterial),
              subtitle: Text(item.productoCodigo ?? ''),
              trailing: Text('${item.cantidad} ${item.unidadBase}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )),
          if (ordenActual.observacionesAprobacion != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.orange),
              title: const Text('Notas de Aprobación'),
              subtitle: Text(ordenActual.observacionesAprobacion!),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEstadoCard() {
    Color color = Colors.blue;
    if (ordenActual.estado == 'aprobada') color = Colors.green;
    if (ordenActual.estado == 'solicitado') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Estado: ${ordenActual.estado.toUpperCase()}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLogisticaSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Logística y Despacho', style: Theme.of(context).textTheme.titleMedium),
                if (!_editandoDespacho)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => setState(() => _editandoDespacho = true),
                  ),
                if (_editandoDespacho)
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.green),
                    onPressed: _guardarCambiosDespacho,
                  ),
              ],
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Proveedor:'),
              subtitle: Text(ordenActual.proveedorNombre ?? 'No asignado (Stock propio)'),
              leading: const Icon(Icons.store),
            ),
            if (_editandoDespacho)
              DropdownButtonFormField<TipoDespacho>(
                value: _tipoDespachoSeleccionado,
                decoration: const InputDecoration(labelText: 'Responsable del Despacho'),
                // ✅ CORREGIDO: Quité 'const' porque items no puede ser const con callbacks (si los hubiera)
                items: const [
                  DropdownMenuItem(value: TipoDespacho.empresa, child: Text('Nuestra Empresa')),
                  DropdownMenuItem(value: TipoDespacho.proveedor, child: Text('A cargo del Proveedor')),
                  DropdownMenuItem(value: TipoDespacho.retiro, child: Text('Retiro en local')),
                ],
                onChanged: (val) => setState(() => _tipoDespachoSeleccionado = val),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Método de Despacho:'),
                subtitle: Text(ordenActual.tipoDespacho?.name.toUpperCase() ?? 'PENDIENTE'),
                leading: const Icon(Icons.local_shipping),
              ),
          ],
        ),
      ),
    );
  }
}