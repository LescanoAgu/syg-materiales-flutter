import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/acopio_provider.dart';
import 'proveedor_form_page.dart';
import 'proveedor_detalle_page.dart';

class ProveedoresListPage extends StatefulWidget {
  final bool esNavegacionPrincipal;
  const ProveedoresListPage({super.key, this.esNavegacionPrincipal = false});

  @override
  State<ProveedoresListPage> createState() => _ProveedoresListPageState();
}

class _ProveedoresListPageState extends State<ProveedoresListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.esNavegacionPrincipal ? null : AppBar(title: const Text('Proveedores'), backgroundColor: AppColors.primary),
      body: Consumer<AcopioProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          if (prov.proveedores.isEmpty) return const Center(child: Text("No hay proveedores registrados"));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: prov.proveedores.length,
            separatorBuilder: (_,__) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final p = prov.proveedores[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.esDepositoSyg ? AppColors.primary : Colors.grey[300],
                    child: Icon(p.esDepositoSyg ? Icons.warehouse : Icons.store, color: p.esDepositoSyg ? Colors.white : Colors.grey[700]),
                  ),
                  title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.direccion ?? 'Sin dirección'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProveedorDetallePage(proveedor: p))),
                  trailing: !p.esDepositoSyg
                      ? IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProveedorFormPage(proveedor: p))))
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProveedorFormPage())),
      ),
    );
  }
}