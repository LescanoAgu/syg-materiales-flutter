import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/cliente_model.dart';
import '../providers/cliente_provider.dart';
import 'cliente_form_page.dart';

class ClientesListPage extends StatefulWidget {
  // ✅ CORRECCIÓN
  final bool esNavegacionPrincipal;
  const ClientesListPage({super.key, this.esNavegacionPrincipal = false});

  @override
  State<ClientesListPage> createState() => _ClientesListPageState();
}

class _ClientesListPageState extends State<ClientesListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si es principal, solo devolvemos el body
    if (widget.esNavegacionPrincipal) return _buildBody();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ClienteProvider>().cargarClientes(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cliente'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: Colors.white,
            ),
            onChanged: (v) => context.read<ClienteProvider>().buscarClientes(v),
          ),
        ),
        Expanded(
          child: Consumer<ClienteProvider>(
            builder: (ctx, provider, _) {
              if (provider.isLoading) return const Center(child: CircularProgressIndicator());
              if (provider.clientes.isEmpty) return const Center(child: Text('Sin clientes'));

              return ListView.builder(
                itemCount: provider.clientes.length,
                padding: const EdgeInsets.only(bottom: 80),
                itemBuilder: (ctx, i) => _buildCard(provider.clientes[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(ClienteModel c) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(c.razonSocial.isNotEmpty ? c.razonSocial[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        title: Text(c.razonSocial, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${c.codigo} • ${c.cuitFormateado}'),
        onTap: () => _mostrarFormulario(context, cliente: c),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmarBorrado(c),
        ),
      ),
    );
  }

  void _confirmarBorrado(ClienteModel c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Cliente?'),
        content: Text('Se borrará ${c.razonSocial} permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              context.read<ClienteProvider>().eliminarCliente(c.id ?? c.codigo);
              Navigator.pop(ctx);
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, {ClienteModel? cliente}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClienteFormPage(cliente: cliente)),
    ).then((_) => context.read<ClienteProvider>().cargarClientes());
  }
}