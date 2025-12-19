import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _orgCtrl = TextEditingController(); // ID Organización
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Únete a tu equipo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),

              // Campo de organización (Opcional si es app cerrada, pero útil si es multi-tenant)
              TextFormField(
                controller: _orgCtrl,
                decoration: const InputDecoration(
                    labelText: 'ID Organización (Opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.apartment),
                    helperText: "Si no tienes, dejalo vacío"
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTRARSE'),
                ),
              ),

              Consumer<AuthProvider>(
                builder: (ctx, auth, _) => auth.errorMessage != null
                    ? Padding(padding: const EdgeInsets.only(top: 16), child: Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await context.read<AuthProvider>().registrar(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
      _nombreCtrl.text.trim(),
      _orgCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context); // Volver al login o ir a AccessPending
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta creada. Esperando aprobación.')));
      }
    }
  }
}