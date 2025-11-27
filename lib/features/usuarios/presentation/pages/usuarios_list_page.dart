import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/data/models/usuario_model.dart';
import '../providers/usuarios_provider.dart';
import 'usuario_detalle_page.dart';

class UsuariosListPage extends StatefulWidget {
  const UsuariosListPage({super.key});

  @override
  State<UsuariosListPage> createState() => _UsuariosListPageState();
}

class _UsuariosListPageState extends State<UsuariosListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargamos usuarios de la MISMA organización que el admin logueado
      final miOrg = context.read<AuthProvider>().usuario?.organizationId;
      if (miOrg != null) {
        context.read<UsuariosProvider>().cargarUsuarios(miOrg);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Equipo'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'PENDIENTES', icon: Icon(Icons.notifications_active)),
            Tab(text: 'EQUIPO ACTIVO', icon: Icon(Icons.group)),
          ],
        ),
      ),
      body: Consumer<UsuariosProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLista(provider.pendientes, esPendiente: true),
              _buildLista(provider.activos),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLista(List<UsuarioModel> usuarios, {bool esPendiente = false}) {
    if (usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(esPendiente ? Icons.check_circle_outline : Icons.group_off, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text(esPendiente ? 'No hay solicitudes pendientes' : 'No hay usuarios activos', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: usuarios.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final u = usuarios[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: esPendiente ? Colors.orange.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
            child: Text(u.nombre[0].toUpperCase()),
          ),
          title: Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${u.email}\nRol: ${u.rol.toUpperCase()}'),
          isThreeLine: true,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UsuarioDetallePage(usuario: u))
            );
          },
        );
      },
    );
  }
}