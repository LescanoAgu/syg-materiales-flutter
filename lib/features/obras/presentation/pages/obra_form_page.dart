import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
// IMPORTANTE: Estos imports deben coincidir con tu estructura
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../data/models/obra_model.dart';
import '../providers/obra_provider.dart';

class ObraFormPage extends StatefulWidget {
  final ObraModel? obra;

  const ObraFormPage({super.key, this.obra});

  @override
  State<ObraFormPage> createState() => _ObraFormPageState();
}

class _ObraFormPageState extends State<ObraFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codigoCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _responsableCtrl;
  late TextEditingController _telefonoCtrl;

  ClienteModel? _clienteSeleccionado;
  String _estado = 'activa';

  @override
  void initState() {
    super.initState();

    _codigoCtrl = TextEditingController(text: widget.obra?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: widget.obra?.nombre ?? '');
    _direccionCtrl = TextEditingController(text: widget.obra?.direccion ?? '');
    _responsableCtrl = TextEditingController(text: widget.obra?.maestroObraNombre ?? widget.obra?.contactoObra ?? '');
    _telefonoCtrl = TextEditingController(text: widget.obra?.maestroObraTelefono ?? widget.obra?.telefonoObra ?? '');

    _estado = widget.obra?.estado ?? 'activa';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();

      if (widget.obra == null) {
        final nuevoCod = context.read<ObraProvider>().generarNuevoCodigo();
        _codigoCtrl.text = nuevoCod;
      } else {
        final clientes = context.read<ClienteProvider>().clientes;
        try {
          _clienteSeleccionado = clientes.firstWhere(
                  (c) => c.id == widget.obra!.clienteId || c.codigo == widget.obra!.clienteId
          );
          setState(() {});
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _responsableCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.obra != null;

    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Obra' : 'Nueva Obra')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Datos de la Obra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: CustomTextField(
                    label: 'Código',
                    controller: _codigoCtrl,
                    enabled: !esEdicion,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildSelectorEstado(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSelectorCliente(),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Nombre de la Obra',
              controller: _nombreCtrl,
              prefixIcon: Icons.business,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Dirección',
              controller: _direccionCtrl,
              prefixIcon: Icons.location_on,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),

            const SizedBox(height: 24),
            const Text('Contacto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Responsable',
              controller: _responsableCtrl,
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Teléfono',
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone,
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: Text(esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR OBRA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCliente() {
    return Consumer<ClienteProvider>(
      builder: (context, provider, _) {
        return DropdownButtonFormField<ClienteModel>(
          value: _clienteSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Cliente',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_pin),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: const Text('Seleccione un cliente...'),
          isExpanded: true,
          items: provider.clientes.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c.razonSocial, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) => setState(() => _clienteSeleccionado = val),
          validator: (val) => val == null ? 'Debe seleccionar un cliente' : null,
        );
      },
    );
  }

  Widget _buildSelectorEstado() {
    return DropdownButtonFormField<String>(
      value: _estado,
      decoration: const InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const [
        DropdownMenuItem(value: 'activa', child: Text('Activa', style: TextStyle(color: Colors.green))),
        DropdownMenuItem(value: 'pausada', child: Text('Pausada', style: TextStyle(color: Colors.orange))),
        DropdownMenuItem(value: 'finalizada', child: Text('Finalizada', style: TextStyle(color: Colors.grey))),
      ],
      onChanged: (v) => setState(() => _estado = v!),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un cliente')));
      return;
    }

    final nuevaObra = ObraModel(
      id: widget.obra?.id,
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      clienteId: _clienteSeleccionado!.codigo,
      clienteRazonSocial: _clienteSeleccionado!.razonSocial,
      clienteCodigo: _clienteSeleccionado!.codigo,
      maestroObraNombre: _responsableCtrl.text.trim(),
      maestroObraTelefono: _telefonoCtrl.text.trim(),
      estado: _estado,
      createdAt: widget.obra?.createdAt ?? DateTime.now().toIso8601String(),
    );

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    final provider = context.read<ObraProvider>();
    bool exito;

    if (widget.obra != null) {
      exito = await provider.actualizarObra(nuevaObra);
    } else {
      exito = await provider.crearObra(nuevaObra);
    }

    if (mounted) {
      Navigator.pop(context);
      if (exito) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Obra guardada'), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: ${provider.errorMessage}'), backgroundColor: AppColors.error));
      }
    }
  }
}