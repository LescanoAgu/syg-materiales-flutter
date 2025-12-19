import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/proveedor_model.dart';
import '../providers/acopio_provider.dart';

class ProveedorFormPage extends StatefulWidget {
  final ProveedorModel? proveedor;
  const ProveedorFormPage({super.key, this.proveedor});

  @override
  State<ProveedorFormPage> createState() => _ProveedorFormPageState();
}

class _ProveedorFormPageState extends State<ProveedorFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.proveedor != null) {
      _nombreCtrl.text = widget.proveedor!.nombre;
      _direccionCtrl.text = widget.proveedor!.direccion ?? '';
      _telefonoCtrl.text = widget.proveedor!.telefono ?? '';
      _emailCtrl.text = widget.proveedor!.email ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.proveedor == null ? "Nuevo Proveedor" : "Editar Proveedor"), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Razón Social', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
              const SizedBox(height: 16),
              TextFormField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text("GUARDAR PROVEEDOR"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = ProveedorModel(
      id: widget.proveedor?.id,
      codigo: widget.proveedor?.codigo ?? 'PROV-${DateTime.now().millisecondsSinceEpoch}',
      nombre: _nombreCtrl.text,
      tipo: TipoProveedor.proveedor,
      direccion: _direccionCtrl.text,
      telefono: _telefonoCtrl.text,
      email: _emailCtrl.text,
      createdAt: widget.proveedor?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<AcopioProvider>();
    bool exito;

    if (widget.proveedor != null) {
      exito = await provider.actualizarProveedor(prov);
    } else {
      exito = await provider.crearProveedor(prov);
    }

    if (exito && mounted) {
      Navigator.pop(context);
    }
  }
}