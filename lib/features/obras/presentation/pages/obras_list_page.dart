import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/obra_model.dart';
import '../providers/obra_provider.dart';
import 'obra_form_page.dart';

class ObrasListPage extends StatefulWidget {
  const ObrasListPage({super.key});
  @override
  State<ObrasListPage> createState() => _ObrasListPageState();
}

class _ObrasListPageState extends State<ObrasListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ObraProvider>().cargarObras());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Obras'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<ObraProvider>().cargarObras())],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ObraFormPage())).then((_) => context.read<ObraProvider>().cargarObras()),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Obra'),
      ),
      body: Consumer<ObraProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          if (prov.obras.isEmpty) return const Center(child: Text('Sin obras'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prov.obras.length,
            itemBuilder: (c, i) => _buildCard(prov.obras[i]),
          );
        },
      ),
    );
  }

  Widget _buildCard(ObraModel o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.business)),
        title: Text(o.nombre),
        subtitle: Text('${o.codigo} - ${o.clienteRazonSocial ?? "?"}'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ObraFormPage(obra: o))).then((_) => context.read<ObraProvider>().cargarObras()),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _borrar(o),
        ),
      ),
    );
  }

  void _borrar(ObraModel o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Obra'),
        content: Text('¿Borrar ${o.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              context.read<ObraProvider>().eliminarObra(o.id ?? o.codigo);
              Navigator.pop(ctx);
            },
            child: const Text('BORRAR'),
          )
        ],
      ),
    );
  }
}