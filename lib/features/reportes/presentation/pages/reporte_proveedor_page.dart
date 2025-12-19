import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../ordenes_internas/presentation/providers/orden_interna_provider.dart';
import '../../../ordenes_internas/data/models/remito_model.dart';
// ✅ IMPORT CORRECTO (Nivel relativo de carpetas)
import '../../../ordenes_internas/presentation/widgets/remito_list_widget.dart';

class ReporteProveedorPage extends StatefulWidget {
  const ReporteProveedorPage({super.key});

  @override
  State<ReporteProveedorPage> createState() => _ReporteProveedorPageState();
}

class _ReporteProveedorPageState extends State<ReporteProveedorPage> {
  String? _proveedorIdSeleccionado;

  // TODO: Conectar con AcopioProvider para traer la lista real
  final List<Map<String, String>> _proveedoresSimulados = [
    {'id': 'PR-001', 'nombre': 'Pannochia'},
    {'id': 'PR-002', 'nombre': 'Corralón El Constructor'},
    {'id': 'PR-003', 'nombre': 'Hierros S.A.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reporte Entregas Proveedor"), backgroundColor: AppColors.primary),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<String>(
              value: _proveedorIdSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Seleccione Proveedor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              items: _proveedoresSimulados.map((p) {
                return DropdownMenuItem(value: p['id'], child: Text(p['nombre']!));
              }).toList(),
              onChanged: (val) => setState(() => _proveedorIdSeleccionado = val),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _proveedorIdSeleccionado == null
                ? const Center(child: Text("Seleccione un proveedor para ver sus entregas"))
                : StreamBuilder<List<Remito>>(
              stream: context.read<OrdenInternaProvider>().getRemitosPorProveedor(_proveedorIdSeleccionado!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No hay entregas registradas"));
                }
                // Aquí usamos el widget que acabamos de crear
                return RemitoListWidget(remitos: snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }
}