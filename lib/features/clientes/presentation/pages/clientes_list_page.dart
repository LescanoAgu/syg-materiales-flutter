import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/cliente_model.dart';
import '../providers/cliente_provider.dart';
import 'cliente_form_page.dart';
import 'cliente_detalle_page.dart';

class ClientesListPage extends StatefulWidget {
  const ClientesListPage({super.key});

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
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Directorio de Clientes'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<ClienteProvider>().cargarClientes()
          )
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, CUIT o código...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.backgroundGray,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => context.read<ClienteProvider>().buscarClientes(val),
            ),
          ),

          // Lista
          Expanded(
            child: Consumer<ClienteProvider>(
              builder: (ctx, prov, _) {
                if (prov.isLoading) return const Center(child: CircularProgressIndicator());
                if (prov.clientes.isEmpty) return const Center(child: Text("No se encontraron clientes"));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.clientes.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _buildClienteCard(prov.clientes[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClienteFormPage())),
      ),
    );
  }

  Widget _buildClienteCard(ClienteModel c) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
          child: Text(
              c.razonSocial.isNotEmpty ? c.razonSocial[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)
          ),
        ),
        title: Text(c.razonSocial, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.cuitFormateado, style: const TextStyle(fontSize: 12)),
            if (c.direccion != null)
              Text(c.direccion!, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClienteDetallePage(cliente: c)),
        ),
      ),
    );
  }
}