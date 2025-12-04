import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/obra_model.dart';
import '../providers/obra_provider.dart';
import 'obra_form_page.dart';
import 'obra_detalle_page.dart'; // ✅ Importamos la nueva ficha

class ObrasListPage extends StatefulWidget {
  const ObrasListPage({super.key});
  @override
  State<ObrasListPage> createState() => _ObrasListPageState();
}

class _ObrasListPageState extends State<ObrasListPage> {
  final TextEditingController _searchController = TextEditingController();

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
        title: const Text('Obras en Curso'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<ObraProvider>().cargarObras())],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ObraFormPage())).then((_) => context.read<ObraProvider>().cargarObras()),
        icon: const Icon(Icons.add_business),
        label: const Text('Nueva Obra'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar obra...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => context.read<ObraProvider>().buscarObras(v),
            ),
          ),
          Expanded(
            child: Consumer<ObraProvider>(
              builder: (ctx, prov, _) {
                if (prov.isLoading) return const Center(child: CircularProgressIndicator());
                if (prov.obras.isEmpty) return const Center(child: Text('No hay obras activas'));

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                  itemCount: prov.obras.length,
                  itemBuilder: (c, i) => _buildObraCard(prov.obras[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObraCard(ObraModel o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.construction, color: Colors.orange),
        ),
        title: Text(o.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(o.clienteRazonSocial, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
            if (o.direccion != null) Text(o.direccion!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ObraDetallePage(obra: o)),
        ).then((_) => context.read<ObraProvider>().cargarObras()),
      ),
    );
  }
}