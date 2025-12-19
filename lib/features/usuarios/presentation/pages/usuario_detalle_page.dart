import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../features/auth/data/models/usuario_model.dart';
import '../providers/usuarios_provider.dart';

class UsuarioDetallePage extends StatefulWidget {
  final UsuarioModel usuario;
  const UsuarioDetallePage({super.key, required this.usuario});

  @override
  State<UsuarioDetallePage> createState() => _UsuarioDetallePageState();
}

class _UsuarioDetallePageState extends State<UsuarioDetallePage> {
  late String _rolSeleccionado;
  late String _estadoSeleccionado;
  // Mapa temporal para permisos
  late Map<String, bool> _permisosTemp;

  @override
  void initState() {
    super.initState();
    _rolSeleccionado = widget.usuario.rol;
    _estadoSeleccionado = widget.usuario.estado;
    _permisosTemp = Map.from(widget.usuario.permisosEspeciales);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.usuario.nombre),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarCambios,
        icon: const Icon(Icons.save),
        label: const Text('Guardar Cambios'),
        backgroundColor: AppColors.success,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person, size: 40, color: Colors.grey),
              title: Text(widget.usuario.email),
              subtitle: Text("ID: ${widget.usuario.uid}", style: const TextStyle(fontSize: 10)),
            ),
            const Divider(),

            // Estado de Cuenta
            _buildSectionTitle("Estado de la Cuenta"),
            DropdownButtonFormField<String>(
              value: _estadoSeleccionado,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente de Aprobación')),
                DropdownMenuItem(value: 'activo', child: Text('Activo (Permitir Acceso)')),
                DropdownMenuItem(value: 'suspendido', child: Text('Suspendido (Bloquear)')),
              ],
              onChanged: (val) => setState(() => _estadoSeleccionado = val!),
            ),
            const SizedBox(height: 20),

            // Rol del Usuario
            _buildSectionTitle("Rol y Nivel de Acceso"),
            DropdownButtonFormField<String>(
              value: _rolSeleccionado,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: AppRoles.labels.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _rolSeleccionado = val!;
                  // Al cambiar rol, podríamos resetear permisos especiales si quisieras
                });
              },
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200)
              ),
              child: Text(
                _getDescripcionRol(_rolSeleccionado),
                style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDescripcionRol(String rol) {
    switch (rol) {
      case AppRoles.admin: return "Acceso total al sistema, gestión de usuarios y configuración.";
      case AppRoles.panolero: return "Gestión de stock, armado de pedidos y despachos.";
      case AppRoles.jefeObra: return "Solicitud de materiales y visualización de sus obras.";
      default: return "Solo visualización limitada.";
    }
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Future<void> _guardarCambios() async {
    final usuarioActualizado = widget.usuario.copyWith(
      estado: _estadoSeleccionado,
      rol: _rolSeleccionado,
      permisosEspeciales: _permisosTemp,
    );

    final exito = await context.read<UsuariosProvider>().guardarCambiosUsuario(usuarioActualizado);

    if (mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambios guardados exitosamente'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red));
      }
    }
  }
}