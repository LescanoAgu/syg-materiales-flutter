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
  late Map<String, bool> _permisosTemp;

  @override
  void initState() {
    super.initState();
    _rolSeleccionado = widget.usuario.rol;
    _estadoSeleccionado = widget.usuario.estado;
    // ✅ AHORA SÍ EXISTE ESTE CAMPO
    _permisosTemp = Map.from(widget.usuario.permisosEspeciales);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.usuario.nombre)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarCambios,
        icon: const Icon(Icons.save),
        label: const Text('GUARDAR'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Estado y Rol'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                      value: _rolSeleccionado,
                      items: [
                        _buildRoleItem(AppRoles.admin),
                        _buildRoleItem(AppRoles.jefeObra),
                        _buildRoleItem(AppRoles.panolero),
                        _buildRoleItem(AppRoles.observador),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _rolSeleccionado = v!;
                          _permisosTemp.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_rolSeleccionado != AppRoles.admin) ...[
              _buildSectionTitle('Ajuste Fino de Permisos'),
              const Text('Modifica permisos específicos fuera del rol base.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),

              _buildSwitch(AppRoles.verPrecios, 'Ver Precios', 'Ver costos en catálogo'),
              _buildSwitch(AppRoles.crearOrden, 'Crear Órdenes', 'Solicitar materiales'),
              _buildSwitch(AppRoles.aprobarOrden, 'Aprobar Órdenes', 'Autorizar salidas'),
              _buildSwitch(AppRoles.gestionarStock, 'Gestionar Stock', 'Ajustes, entradas y salidas'),
              _buildSwitch(AppRoles.verReportes, 'Ver Reportes', 'Estadísticas y PDF'),
            ],
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildRoleItem(String rolKey) {
    return DropdownMenuItem(
      value: rolKey,
      child: Text(AppRoles.labels[rolKey] ?? rolKey),
    );
  }

  Widget _buildSwitch(String key, String titulo, String subtitulo) {
    final tienePorRol = AppRoles.tienePermisoBase(_rolSeleccionado, key);
    final valorActual = _permisosTemp.containsKey(key) ? _permisosTemp[key]! : tienePorRol;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: tienePorRol ? Colors.grey[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          tienePorRol ? '$subtitulo (Incluido en Rol)' : subtitulo,
          style: TextStyle(fontSize: 12, color: tienePorRol ? AppColors.primary : Colors.grey),
        ),
        value: valorActual,
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
      rol: _rolSeleccionado,
      permisosEspeciales: _permisosTemp, // ✅ PARAMETRO CORREGIDO
    );

    final exito = await context.read<UsuariosProvider>().guardarCambiosUsuario(usuarioActualizado);

    if (mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Guardado'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Error'), backgroundColor: AppColors.error));
      }
    }
  }
}