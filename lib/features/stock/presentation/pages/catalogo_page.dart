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
          title: const Text("Importar Catálogo (CSV)"),
          backgroundColor: AppColors.primary
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Pegar datos desde Excel/CSV",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            const Text(
                "Columnas: Código, Nombre, Precio, Categoría, Unidad",
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TextField(
                controller: _csvController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: "A001, Martillo, 5000, Herramientas, un\nA002, Clavos, 200, Fijaciones, kg...",
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
                    : const Text("PROCESAR DATOS"),
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

        final partes = linea.split(',');
        // Mínimo necesitamos código y nombre
        if (partes.length >= 2) {
          final codigo = partes[0].trim();
          final nombre = partes[1].trim();

          double? precio;
          if (partes.length > 2 && partes[2].trim().isNotEmpty) {
            precio = double.tryParse(partes[2].trim());
          }

          String catNombre = "General";
          if (partes.length > 3 && partes[3].trim().isNotEmpty) {
            catNombre = partes[3].trim();
          }

          String unidad = "u";
          if (partes.length > 4 && partes[4].trim().isNotEmpty) {
            unidad = partes[4].trim();
          }

          // --- FIX RANGE ERROR ---
          // Aseguramos que catNombre tenga longitud suficiente antes de substring
          String catId = "GEN";
          String prefijo = "G";

          if (catNombre.isNotEmpty) {
            // ID: Primeras 3 letras mayúsculas
            catId = catNombre.length >= 3
                ? catNombre.substring(0, 3).toUpperCase()
                : catNombre.toUpperCase();

            // Prefijo: Primera letra
            prefijo = catNombre.substring(0, 1).toUpperCase();
          }

          // Crear categoría si no existe (evitamos repetidos en el loop)
          bool existeCatLocal = provider.categorias.any((c) => c.codigo == catId);
          if (!existeCatLocal && !categoriasProcesadas.contains(catId)) {
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
                SnackBar(content: Text("✅ Importación exitosa: ${productosAImportar.length} productos"), backgroundColor: Colors.green)
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Hubo un error al guardar los productos"), backgroundColor: Colors.red)
            );
          }
        }
      } else {
        if (mounted) setState(() => _procesando = false);
      }

    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error grave: $e"), backgroundColor: Colors.red));
      }
    }
  }
}