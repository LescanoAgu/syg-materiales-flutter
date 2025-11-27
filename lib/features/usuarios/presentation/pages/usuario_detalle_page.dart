import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
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
  late Map<String, bool> _permisosTemp;

  @override
  void initState() {
    super.initState();
    _rolSeleccionado = widget.usuario.rol;
    _estadoSeleccionado = widget.usuario.estado;
    // Copia de seguridad de los permisos para editar
    _permisosTemp = Map.from(widget.usuario.permisos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.usuario.nombre)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarCambios,
        icon: const Icon(Icons.save),
        label: const Text('GUARDAR CAMBIOS'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ESTADO Y ROL
            _buildSectionTitle('Estado y Rol'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Estado de la cuenta'),
                      value: _estadoSeleccionado,
                      items: const [
                        DropdownMenuItem(value: 'pendiente', child: Text('⏳ Pendiente')),
                        DropdownMenuItem(value: 'activo', child: Text('✅ Activo')),
                        DropdownMenuItem(value: 'bloqueado', child: Text('🚫 Bloqueado')),
                      ],
                      onChanged: (v) => setState(() => _estadoSeleccionado = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Rol Base'),
                      value: _rolSeleccionado,
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('🛡️ Administrador')),
                        DropdownMenuItem(value: 'pañolero', child: Text('📦 Pañolero')),
                        DropdownMenuItem(value: 'jefe_obra', child: Text('👷 Jefe de Obra')),
                        DropdownMenuItem(value: 'usuario', child: Text('👤 Usuario Básico')),
                      ],
                      onChanged: (v) => setState(() => _rolSeleccionado = v!),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // PERMISOS ESPECÍFICOS
            _buildSectionTitle('Permisos Específicos'),
            const Text('Define qué puede ver o hacer este usuario.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),

            _buildSwitch('ver_precios', 'Ver Precios', 'Permite ver costos en el catálogo y órdenes.'),
            _buildSwitch('crear_orden', 'Crear Órdenes', 'Puede generar nuevas solicitudes de material.'),
            _buildSwitch('gestionar_stock', 'Ajustar Stock', 'Puede registrar entradas, salidas y ajustes.'),
            _buildSwitch('aprobar_usuarios', 'Gestionar Usuarios', 'Puede aprobar nuevos registros (Admin).'),
            _buildSwitch('ver_reportes', 'Ver Reportes', 'Acceso a estadísticas y descargas PDF.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String key, String titulo, String subtitulo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
        value: _permisosTemp[key] ?? false,
        activeColor: AppColors.primary,
        onChanged: (val) {
          setState(() {
            _permisosTemp[key] = val;
          });
        },
      ),
    );
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
      rol: _rolSeleccionado, // Usamos 'rol' (corregido según tu modelo)
      permisos: _permisosTemp,
    );

    final exito = await context.read<UsuariosProvider>().guardarCambiosUsuario(usuarioActualizado);

    if (mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Usuario actualizado'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Error al guardar'), backgroundColor: AppColors.error));
      }
    }
  }
}