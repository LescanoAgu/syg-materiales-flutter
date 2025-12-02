import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/acopio_provider.dart';
import 'proveedor_form_page.dart';

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
    if (widget.esNavegacionPrincipal) return _buildBody();

    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProveedorFormPage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading)
          return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.proveedores.length,
          itemBuilder: (ctx, i) {
            final p = provider.proveedores[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.esDepositoSyg
                      ? AppColors.primary
                      : Colors.grey[300],
                  child: Icon(
                    p.esDepositoSyg ? Icons.warehouse : Icons.store,
                    color: p.esDepositoSyg ? Colors.white : Colors.grey[700],
                  ),
                ),
                title: Text(
                  p.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(p.direccion ?? 'Sin dirección'),
                trailing: !p.esDepositoSyg
                    ? IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProveedorFormPage(proveedor: p),
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
