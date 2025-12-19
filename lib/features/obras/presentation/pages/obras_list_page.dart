import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/obra_model.dart';
import '../providers/obra_provider.dart';
import 'obra_form_page.dart';
import 'obra_detalle_page.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Obras en Curso'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<ObraProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          if (prov.obras.isEmpty) return const Center(child: Text("No hay obras registradas"));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: prov.obras.length,
            separatorBuilder: (_,__) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _buildObraCard(prov.obras[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ObraFormPage())),
      ),
    );
  }

  Widget _buildObraCard(ObraModel o) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.construction, color: Colors.orange),
        ),
        title: Text(o.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(o.clienteRazonSocial, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (o.direccion != null) Text(o.direccion!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ObraDetallePage(obra: o))),
      ),
    );
  }
}