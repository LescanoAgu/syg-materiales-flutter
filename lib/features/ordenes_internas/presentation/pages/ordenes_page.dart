import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../../../features/stock/presentation/pages/stock_page.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import 'orden_form_page.dart';
import 'orden_detalle_page.dart';

class OrdenesPage extends StatefulWidget {
  // ✅ CORRECCIÓN
  final bool esNavegacionPrincipal;
  const OrdenesPage({super.key, this.esNavegacionPrincipal = false});

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
  String? _filtroClienteId;
  String? _filtroObraId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdenInternaProvider>().cargarOrdenes();
      context.read<ClienteProvider>().cargarClientes();
      context.read<ObraProvider>().cargarObras();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ LÓGICA DE NAVEGACIÓN
    if (widget.esNavegacionPrincipal) {
      return Scaffold( // Scaffold interno para el FAB y la barra de filtros
        floatingActionButton: _buildFab(),
        body: Column(
          children: [
            _buildBarraFiltros(), // Barra de filtros integrada en el body
            Expanded(child: _buildLista()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📋 Órdenes Internas'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StockPage())),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<OrdenInternaProvider>().cargarOrdenes())],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildBarraFiltros(),
        ),
      ),
      floatingActionButton: _buildFab(),
      body: _buildLista(),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdenFormPage())).then((_) => context.read<OrdenInternaProvider>().cargarOrdenes()),
      icon: const Icon(Icons.add), label: const Text('Nueva Orden'),
    );
  }

  Widget _buildLista() {
    return Consumer<OrdenInternaProvider>(
      builder: (ctx, prov, _) {
        var lista = prov.ordenes;
        if (_filtroClienteId != null) {
          lista = lista.where((o) => o.orden.clienteId == _filtroClienteId).toList();
        }
        if (_filtroObraId != null) {
          lista = lista.where((o) => o.orden.obraId == _filtroObraId).toList();
        }

        if (prov.isLoading) return const Center(child: CircularProgressIndicator());
        if (lista.isEmpty) return const Center(child: Text('Sin órdenes que coincidan'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          itemBuilder: (ctx, i) => _buildCard(lista[i]),
        );
      },
    );
  }

  // ... (El resto de tus widgets _buildBarraFiltros, _buildCard, etc. se mantienen igual, solo cópialos del archivo anterior si los borraste)
  // Te los incluyo para completar:

  Widget _buildBarraFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Consumer<ClienteProvider>(
              builder: (ctx, cliProv, _) => DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Cliente"),
                value: _filtroClienteId,
                underline: Container(),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Todos")),
                  ...cliProv.clientes.map((c) => DropdownMenuItem(value: c.codigo, child: Text(c.razonSocial, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() { _filtroClienteId = v; _filtroObraId = null; }),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Consumer<ObraProvider>(
              builder: (ctx, obraProv, _) {
                final obras = _filtroClienteId == null ? obraProv.obras : obraProv.obras.where((o) => o.clienteId == _filtroClienteId).toList();
                return DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text("Obra"),
                  value: _filtroObraId,
                  underline: Container(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Todas")),
                    ...obras.map((o) => DropdownMenuItem(value: o.codigo, child: Text(o.nombre, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => setState(() => _filtroObraId = v),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(OrdenInternaDetalle od) {
    final orden = od.orden;
    Color colorBorde;
    IconData iconPrioridad;
    switch (orden.prioridad) {
      case 'urgente': colorBorde = Colors.red; iconPrioridad = Icons.local_fire_department; break;
      case 'alta': colorBorde = Colors.orange; iconPrioridad = Icons.priority_high; break;
      case 'baja': colorBorde = Colors.green; iconPrioridad = Icons.low_priority; break;
      default: colorBorde = Colors.grey.shade300; iconPrioridad = Icons.circle_outlined;
    }
    final progreso = orden.porcentajeAvance;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colorBorde, width: orden.prioridad == 'urgente' ? 2 : 1)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdenDetallePage(ordenResumen: od))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [Icon(iconPrioridad, size: 16, color: colorBorde), const SizedBox(width: 4), Text(orden.numero, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                  _buildEstadoBadge(orden.estado),
                ],
              ),
              const SizedBox(height: 8),
              _buildDato(Icons.business, od.clienteRazonSocial),
              _buildDato(Icons.location_on, od.obraNombre ?? 'Sin obra asignada'),
              _buildDato(Icons.person, 'Solicita: ${orden.solicitanteNombre}'),
              const SizedBox(height: 10),
              if (orden.estado != 'solicitado') ...[
                Row(
                  children: [
                    Expanded(child: LinearProgressIndicator(value: progreso, backgroundColor: Colors.grey[200], color: _getColorProgreso(progreso), minHeight: 6, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Text('${(progreso * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                if(orden.responsableEntregaNombre != null)
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text('Chofer: ${orden.responsableEntregaNombre}', style: TextStyle(fontSize: 11, color: Colors.blue[800]))),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDato(IconData icon, String text) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 6), Expanded(child: Text(text, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))]));

  Widget _buildEstadoBadge(String estado) {
    Color bg; Color text;
    switch(estado) {
      case 'solicitado': bg = Colors.orange.shade100; text = Colors.orange.shade800; break;
      case 'en_curso': bg = Colors.blue.shade100; text = Colors.blue.shade800; break;
      case 'aprobado': bg = Colors.purple.shade100; text = Colors.purple.shade800; break;
      case 'finalizado': bg = Colors.green.shade100; text = Colors.green.shade800; break;
      default: bg = Colors.grey.shade200; text = Colors.black;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)), child: Text(estado.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)));
  }

  Color _getColorProgreso(double val) { if (val < 0.3) return Colors.red; if (val < 0.7) return Colors.orange; return Colors.green; }
}