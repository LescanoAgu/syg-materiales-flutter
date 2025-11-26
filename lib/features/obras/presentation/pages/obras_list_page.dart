import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/obra_model.dart';
import '../providers/obra_provider.dart';
import 'obra_form_page.dart'; // Import necesario para la navegación

class ObrasListPage extends StatefulWidget {
  const ObrasListPage({super.key});

  @override
  State<ObrasListPage> createState() => _ObrasListPageState();
}

class _ObrasListPageState extends State<ObrasListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _filtroEstado = 'Activas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraProvider>().cargarObras();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Obras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ObraProvider>().cargarObras(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<ObraProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.obras.isEmpty) return const Center(child: Text('No hay obras cargadas'));

                return ListView.builder(
                  itemCount: provider.obras.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final obra = provider.obras[index];
                    return _buildObraCard(obra);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarAFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Obra'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar obra...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (v) => context.read<ObraProvider>().buscarObras(v),
      ),
    );
  }

  Widget _buildObraCard(ObraModel obra) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: obra.estado == 'activa' ? Colors.green : Colors.grey,
          child: const Icon(Icons.business, color: Colors.white),
        ),
        title: Text(obra.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cód: ${obra.codigo}'),
            Text('Cliente: ${obra.clienteRazonSocial ?? "Sin asignar"}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navegarAFormulario(context, obra: obra),
      ),
    );
  }

  void _navegarAFormulario(BuildContext context, {ObraModel? obra}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ObraFormPage(obra: obra)),
    ).then((_) => context.read<ObraProvider>().cargarObras());
  }
}