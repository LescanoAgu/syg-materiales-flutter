import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/cliente_model.dart';
import '../providers/cliente_provider.dart';
import 'cliente_form_page.dart';
import 'cliente_detalle_page.dart'; // ✅ Importamos la nueva ficha

class ClientesListPage extends StatefulWidget {
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
    // Si es navegación principal (desde Home), solo mostramos el contenido
    if (widget.esNavegacionPrincipal) return _buildBody();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Directorio de Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ClienteProvider>().cargarClientes(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
        backgroundColor: AppColors.primary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Buscador
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.05),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, código o CUIT...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<ClienteProvider>().buscarClientes('');
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => context.read<ClienteProvider>().buscarClientes(v),
          ),
        ),

        // Lista
        Expanded(
          child: Consumer<ClienteProvider>(
            builder: (ctx, provider, _) {
              if (provider.isLoading) return const Center(child: CircularProgressIndicator());
              if (provider.clientes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No se encontraron clientes', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: provider.clientes.length,
                padding: const EdgeInsets.only(bottom: 80, top: 8),
                separatorBuilder: (_,__) => const Divider(height: 1, indent: 70),
                itemBuilder: (ctx, i) => _buildClienteTile(provider.clientes[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClienteTile(ClienteModel c) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.secondary.withOpacity(0.1),
        child: Text(
          c.razonSocial.isNotEmpty ? c.razonSocial[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 18),
        ),
      ),
      title: Text(c.razonSocial, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                child: Text(c.codigo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text(c.cuitFormateado, style: const TextStyle(fontSize: 12)),
            ],
          ),
          if (c.direccion != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(c.direccion!, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () => _navegarFicha(context, c),
    );
  }

  void _navegarFicha(BuildContext context, ClienteModel c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClienteDetallePage(cliente: c)),
    ).then((_) => context.read<ClienteProvider>().cargarClientes());
  }

  void _mostrarFormulario(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClienteFormPage()),
    ).then((_) => context.read<ClienteProvider>().cargarClientes());
  }
}