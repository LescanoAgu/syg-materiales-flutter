import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/cliente_model.dart';
import '../providers/cliente_provider.dart';

class ClientesImportPage extends StatefulWidget {
  const ClientesImportPage({super.key});

  @override
  State<ClientesImportPage> createState() => _ClientesImportPageState();
}

class _ClientesImportPageState extends State<ClientesImportPage> {
  final TextEditingController _csvController = TextEditingController();
  bool _procesando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Importar Clientes"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pegar lista de Clientes (CSV)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Formato: Nombre, CUIT, Teléfono, Dirección, Email",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const Text(
              "El código se generará automáticamente (CL-001, CL-002...)",
              style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _csvController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: "Juan Perez, 20304050607, 11223344, Calle Falsa 123, juan@mail.com\nEmpresa SA, 3050..., ...",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : _procesarImportacion,
                icon: const Icon(Icons.group_add),
                label: _procesando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("IMPORTAR AHORA"),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _procesarImportacion() async {
    final texto = _csvController.text;
    if (texto.isEmpty) return;

    setState(() => _procesando = true);

    List<ClienteModel> clientes = [];
    final lineas = texto.split('\n');

    for (var linea in lineas) {
      if (linea.trim().isEmpty) continue;
      final partes = linea.split(',');

      if (partes.isNotEmpty) {
        // Orden esperado: Nombre, CUIT, Telefono, Direccion, Email
        String nombre = partes[0].trim();
        if (nombre.isEmpty) continue;

        String? cuit = partes.length > 1 ? partes[1].trim() : null;
        String? tel = partes.length > 2 ? partes[2].trim() : null;
        String? dir = partes.length > 3 ? partes[3].trim() : null;
        String? mail = partes.length > 4 ? partes[4].trim() : null;

        clientes.add(ClienteModel(
          id: '', // Se genera en BD
          codigo: '', // Se genera en BD (CL-XXX)
          razonSocial: nombre,
          cuit: cuit,
          telefono: tel,
          direccion: dir,
          email: mail,
          activo: true,
          createdAt: DateTime.now(),
        ));
      }
    }

    if (clientes.isNotEmpty) {
      final exito = await context.read<ClienteProvider>().importarClientes(clientes);
      if (mounted) {
        setState(() => _procesando = false);
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ${clientes.length} clientes importados")));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al importar"), backgroundColor: Colors.red));
        }
      }
    } else {
      if (mounted) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se detectaron datos válidos")));
      }
    }
  }
}