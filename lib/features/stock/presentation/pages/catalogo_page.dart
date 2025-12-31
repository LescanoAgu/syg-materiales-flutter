import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final TextEditingController _csvController = TextEditingController();
  bool _procesando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Importar Catálogo (TXT/CSV)"),
          backgroundColor: AppColors.primary
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Pegar lista de materiales",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            const Text(
                "El sistema detectará automáticamente los prefijos (Ej: A, OG, E)\nFormato: CODIGO;NOMBRE;PRECIO;CATEGORIA;UNIDAD",
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TextField(
                controller: _csvController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: "Pega aquí el contenido de Items.txt...",
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
                icon: const Icon(Icons.upload_file),
                label: _procesando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("PROCESAR E IMPORTAR"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _procesando ? null : _procesarCSV,
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _procesarCSV() async {
    final texto = _csvController.text;
    if (texto.isEmpty) return;

    setState(() => _procesando = true);

    final lineas = texto.split('\n');
    final provider = context.read<ProductoProvider>();
    List<ProductoModel> productosAImportar = [];
    Set<String> categoriasProcesadas = {};

    try {
      for (var linea in lineas) {
        if (linea.trim().isEmpty) continue;
        if (!linea.contains(';')) continue; // Ignora encabezados basura

        final partes = linea.split(';');

        if (partes.length >= 2) {
          final codigo = partes[0].trim().toUpperCase(); // Ej: OG001 o A-001
          final nombre = partes[1].trim();

          // Validación básica
          if (codigo.length < 2) continue;

          double? precio;
          if (partes.length > 2 && partes[2].trim().isNotEmpty) {
            String precioStr = partes[2].trim().replaceAll(',', '.');
            precio = double.tryParse(precioStr);
          }

          String catNombre = "General";
          if (partes.length > 3 && partes[3].trim().isNotEmpty) {
            catNombre = partes[3].trim();
          }

          String unidad = "Unidad";
          if (partes.length > 4 && partes[4].trim().isNotEmpty) {
            unidad = partes[4].trim();
          }

          // --- LOGICA DE PREFIJOS CORRECTA ---
          // Extraemos TODAS las letras antes de los números
          // Si codigo es "OG001" -> prefijo "OG"
          // Si codigo es "A-001" -> prefijo "A-"
          // Si codigo es "A001"  -> prefijo "A"

          final regex = RegExp(r'^([A-Z\-]+)'); // Captura letras y guiones al inicio
          final match = regex.firstMatch(codigo);
          String prefijo = "G"; // Default

          if (match != null) {
            prefijo = match.group(0) ?? "G";
            // Si el usuario quiere guardar sin guión en la categoría pero el código lo tiene
            // prefijo = prefijo.replaceAll('-', '');
          }

          // ID de categoría basado en el nombre, para no duplicar "Agua" con "agua"
          String catId = catNombre.toUpperCase().replaceAll(' ', '_');

          // Crear categoría si no existe en memoria local
          // (Nota: Esto no chequea contra Firebase en tiempo real por performance,
          //  asume que Provider tiene la lista cargada o no duplica al guardar)
          if (!categoriasProcesadas.contains(catId)) {
            await provider.crearCategoria(catNombre, catId, prefijo);
            categoriasProcesadas.add(catId);
          }

          productosAImportar.add(ProductoModel(
            codigo: codigo,
            nombre: nombre,
            precioSinIva: precio,
            categoriaId: catId,
            categoriaNombre: catNombre,
            unidadBase: unidad,
            cantidadDisponible: 0,
          ));
        }
      }

      if (productosAImportar.isNotEmpty) {
        final exito = await provider.importarProductos(productosAImportar);

        if (mounted) {
          setState(() => _procesando = false);
          if (exito) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("✅ Éxito: ${productosAImportar.length} productos importados"), backgroundColor: Colors.green)
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al guardar en base de datos"), backgroundColor: Colors.red)
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _procesando = false);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ No se encontraron productos válidos."), backgroundColor: Colors.orange)
          );
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error grave: $e"), backgroundColor: Colors.red));
      }
    }
  }
}