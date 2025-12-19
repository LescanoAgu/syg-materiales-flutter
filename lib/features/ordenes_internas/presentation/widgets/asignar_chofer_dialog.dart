import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/usuarios/presentation/providers/usuarios_provider.dart';
import '../../../../features/auth/data/models/usuario_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class AsignarChoferDialog extends StatefulWidget {
  const AsignarChoferDialog({super.key});

  @override
  State<AsignarChoferDialog> createState() => _AsignarChoferDialogState();
}

class _AsignarChoferDialogState extends State<AsignarChoferDialog> {
  UsuarioModel? _seleccionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final miOrg = context.read<AuthProvider>().usuario?.organizationId;
      if (miOrg != null) {
        context.read<UsuariosProvider>().cargarUsuarios(miOrg);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Responsable'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Consumer<UsuariosProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());

            // Filtramos activos
            final disponibles = provider.activos;

            if (disponibles.isEmpty) return const Text("No hay usuarios disponibles");

            return ListView.separated(
              separatorBuilder: (_,__) => const Divider(),
              itemCount: disponibles.length,
              itemBuilder: (ctx, i) {
                final u = disponibles[i];
                final isSelected = _seleccionado?.uid == u.uid;

                return ListTile(
                  leading: CircleAvatar(
                    // ✅ Fix deprecated
                    backgroundColor: isSelected ? AppColors.primary : Colors.grey[300],
                    child: Text(u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                  ),
                  title: Text(u.nombre),
                  subtitle: Text(u.rol.toUpperCase()),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () => setState(() => _seleccionado = u),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _seleccionado == null ? null : () {
            Navigator.pop(context, _seleccionado);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('ASIGNAR'),
        ),
      ],
    );
  }
}