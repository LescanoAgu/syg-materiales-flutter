import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/cliente_provider.dart';

class ClientesImportPage extends StatefulWidget {
  const ClientesImportPage({super.key});

  @override
  State<ClientesImportPage> createState() => _ClientesImportPageState();
}

class _ClientesImportPageState extends State<ClientesImportPage> {
  bool _procesando = false;

  void _importarCSV() async {
    setState(() => _procesando = true);

    // Llamamos al método del provider que abre el selector de archivos
    final mensaje = await context.read<ClienteProvider>().importarClientesDesdeCSV();

    if (mounted) {
      setState(() => _procesando = false);

      bool exito = mensaje.contains("Éxito");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(mensaje),
        backgroundColor: exito ? Colors.green : Colors.red,
      ));

      if (exito) {
        // Esperamos un poco para que el usuario lea y cerramos
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Importación Masiva"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.upload_file, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Importar Clientes y Obras",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Selecciona un archivo .CSV con el siguiente formato:\n\nRazón Social, CUIT, Teléfono, Estado (Activo/Inactivo), Nombre Obra, Dirección Obra",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _procesando ? null : _importarCSV,
              icon: const Icon(Icons.folder_open),
              label: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _procesando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SELECCIONAR ARCHIVO CSV"),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}