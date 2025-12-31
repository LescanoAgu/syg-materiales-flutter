import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/orden_interna_model.dart';
import '../../data/models/remito_model.dart';
import '../widgets/dialogo_aprobar_orden.dart';
import '../providers/orden_interna_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/remito_list_widget.dart';
import '../../../reportes/data/services/pdf_service.dart';

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
  List<Remito>? _remitosDeOrden;

  @override
  void initState() {
    super.initState();
    ordenActual = widget.orden;
    _tipoDespachoSeleccionado = ordenActual.tipoDespacho;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarRemitos();
    });
  }

  void _cargarRemitos() {
    context.read<OrdenInternaProvider>().getRemitosPorOrden(ordenActual.id!).listen((lista) {
      if (mounted) setState(() => _remitosDeOrden = lista);
    });
  }

  void _mostrarDialogoAprobacion() {
    showDialog(
      context: context,
      builder: (ctx) => DialogoAprobarOrden(
        orden: ordenActual,
        onAprobar: (itemsModificados, observacion, provId, provNombre, origen) async {
          Navigator.pop(ctx);
          final user = context.read<AuthProvider>().usuario;

          final exito = await context.read<OrdenInternaProvider>().aprobarOrden(
            ordenId: ordenActual.id!,
            usuarioId: user?.uid ?? 'admin',
            itemsModificados: itemsModificados,
            observaciones: observacion,
            proveedorId: provId,
            proveedorNombre: provNombre,
            origen: origen,
          );

          if (!mounted) return;

          if (exito) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Orden Aprobada")));
            await context.read<OrdenInternaProvider>().cargarDetalleOrden(ordenActual.id!);
            final actualizado = context.read<OrdenInternaProvider>().ordenSeleccionada;
            if (actualizado != null) {
              setState(() => ordenActual = actualizado.orden);
            }
          }
        },
      ),
    );
  }

  void _guardarCambiosDespacho() async {
    if (_tipoDespachoSeleccionado == null) return;

    final exito = await context.read<OrdenInternaProvider>().actualizarLogistica(
      ordenId: ordenActual.id!,
      tipoDespacho: _tipoDespachoSeleccionado!,
      proveedorId: ordenActual.proveedorId,
      proveedorNombre: ordenActual.proveedorNombre,
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Logística actualizada")));
      setState(() {
        _editandoDespacho = false;
        ordenActual = OrdenInternaModel(
            id: ordenActual.id,
            numero: ordenActual.numero,
            clienteId: ordenActual.clienteId,
            obraId: ordenActual.obraId,
            solicitanteId: ordenActual.solicitanteId,
            solicitanteNombre: ordenActual.solicitanteNombre,
            fechaCreacion: ordenActual.fechaCreacion,
            estado: ordenActual.estado,
            prioridad: ordenActual.prioridad,
            items: ordenActual.items,
            destino: ordenActual.destino,
            observaciones: ordenActual.observaciones,
            observacionesAprobacion: ordenActual.observacionesAprobacion,
            proveedorId: ordenActual.proveedorId,
            proveedorNombre: ordenActual.proveedorNombre,
            tipoDespacho: _tipoDespachoSeleccionado,
            modificadoPor: ordenActual.modificadoPor,
            origen: ordenActual.origen,
            esRetiroAcopio: ordenActual.esRetiroAcopio,
            acopioId: ordenActual.acopioId,
            titulo: ordenActual.titulo,
            observacionesCliente: ordenActual.observacionesCliente
        );
      });
    }
  }

  // ✅ NUEVO: Generar PDF de la Orden (Presupuesto)
  void _imprimirOrdenPedido() async {
    final provider = context.read<OrdenInternaProvider>();
    OrdenInternaDetalle? detalleFull;

    // Buscamos los datos completos (nombre cliente/obra) en el provider
    try {
      detalleFull = provider.ordenes.firstWhere((d) => d.orden.id == ordenActual.id);
    } catch (_) {
      // Si no está en la lista general, quizas es la seleccionada actualmente
      if (provider.ordenSeleccionada?.orden.id == ordenActual.id) {
        detalleFull = provider.ordenSeleccionada;
      }
    }

    // Si aun así no tenemos nombres (orden vieja), usamos fallbacks
    final detalleParaPdf = OrdenInternaDetalle(
        orden: ordenActual,
        clienteRazonSocial: detalleFull?.clienteRazonSocial ?? "Cliente: ${ordenActual.clienteId}",
        obraNombre: detalleFull?.obraNombre ?? "Obra: ${ordenActual.obraId}"
    );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Orden de Pedido...")));
    await PdfService().generarOrdenDePedido(detalleParaPdf);
  }

  @override
  Widget build(BuildContext context) {
    // Buscar detalle completo para mostrar nombres en UI
    final provider = context.watch<OrdenInternaProvider>();
    OrdenInternaDetalle? detalleEncontrado;

    try {
      detalleEncontrado = provider.ordenes.firstWhere((d) => d.orden.id == ordenActual.id);
    } catch (_) {
      if (provider.ordenSeleccionada?.orden.id == ordenActual.id) {
        detalleEncontrado = provider.ordenSeleccionada;
      }
    }

    final String clienteNombre = detalleEncontrado?.clienteRazonSocial ?? "Cliente: ${ordenActual.clienteId}";
    final String obraNombre = detalleEncontrado?.obraNombre ?? "Obra: ${ordenActual.obraId}";

    return Scaffold(
      appBar: AppBar(
        title: Text('Orden ${ordenActual.numero}'),
        actions: [
          // ✅ BOTÓN DE IMPRIMIR ORDEN
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Orden de Pedido',
            onPressed: _imprimirOrdenPedido,
          ),
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

          const SizedBox(height: 30),
          const Divider(thickness: 2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Historial de Entregas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarRemitos),
              ],
            ),
          ),

          if (_remitosDeOrden == null)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_remitosDeOrden!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 40, color: Colors.grey),
                    Text("No se han generado remitos aún.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            RemitoListWidget(
                remitos: _remitosDeOrden!,
                ordenContexto: OrdenInternaDetalle(
                    orden: ordenActual,
                    clienteRazonSocial: clienteNombre,
                    obraNombre: obraNombre
                ),
                mostrarCliente: false
            ),

          const SizedBox(height: 80),
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
              title: const Text('Origen / Proveedor:'),
              subtitle: Text(ordenActual.proveedorNombre ?? ordenActual.origen.name.toUpperCase()),
              leading: const Icon(Icons.store),
            ),
            if (_editandoDespacho)
              DropdownButtonFormField<TipoDespacho>(
                value: _tipoDespachoSeleccionado,
                decoration: const InputDecoration(labelText: 'Responsable del Despacho'),
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