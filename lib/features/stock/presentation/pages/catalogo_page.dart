import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import '../../../../core/widgets/app_drawer.dart';
import 'producto_form_page.dart';
import 'movimiento_historial_page.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _verPrecios = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductoProvider>();
      provider.cargarCategorias();
      provider.cargarProductos(recargar: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<ProductoProvider>().cargarMasProductos();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      context.read<ProductoProvider>().buscarProductos(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Catálogo Maestro'),
        actions: [
          IconButton(
            icon: Icon(_verPrecios ? Icons.visibility : Icons.visibility_off),
            tooltip: 'Alternar Precios',
            onPressed: () => setState(() => _verPrecios = !_verPrecios),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar CSV',
            onPressed: () => _mostrarDialogoImportacion(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductoFormPage()))
            .then((_) => context.read<ProductoProvider>().cargarProductos(recargar: true)),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Buscador
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar material...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _searchController.clear();
                  context.read<ProductoProvider>().buscarProductos('');
                })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.backgroundGray,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Categorías
          SizedBox(
            height: 60,
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Todos'),
                        selected: provider.categoriaFiltroId == null,
                        onSelected: (bool selected) {
                          if (selected) provider.seleccionarCategoria(null);
                        },
                      ),
                    ),
                    ...provider.categorias.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat.nombre),
                          selected: provider.categoriaFiltroId == cat.codigo,
                          onSelected: (bool selected) {
                            provider.seleccionarCategoria(selected ? cat.codigo : null);
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          // Lista
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.productos.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.productos.isEmpty) {
                  return const Center(child: Text('No hay productos en el catálogo.'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.productos.length + (provider.isLoadingMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == provider.productos.length) return const Center(child: CircularProgressIndicator());
                    return _buildCatalogItem(context, provider.productos[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogItem(BuildContext context, ProductoModel p) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoFormPage(producto: p)))
            .then((_) => context.read<ProductoProvider>().cargarProductos(recargar: true)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    p.codigo.contains('-') ? p.codigo.split('-').first : p.codigo.substring(0, 1),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                      child: Text('${p.codigo} • ${p.categoriaNombre ?? "Gral"}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                    ),
                  ],
                ),
              ),
              if (_verPrecios)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(p.precioSinIva != null ? '\$${p.precioSinIva}' : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    Text('x ${p.unidadBase}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (v) {
                  if (v == 'historial') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MovimientoHistorialPage(productoId: p.codigo)));
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'historial', child: Row(children: [Icon(Icons.history, size: 18), SizedBox(width: 8), Text('Historial')])),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- IMPORTACIÓN INTELIGENTE ---
  void _mostrarDialogoImportacion(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar CSV'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pega las filas del CSV (COD;NOMBRE;PRECIO;CAT;UNIDAD)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'A001;Caño...')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () {
                _procesarImportacion(context, controller.text);
                Navigator.pop(ctx);
              },
              child: const Text('Importar')
          ),
        ],
      ),
    );
  }

  String _limpiarDato(String raw) {
    String s = raw.trim();
    if (s.startsWith('"') && s.endsWith('"')) s = s.substring(1, s.length - 1);
    return s.replaceAll('""', '"');
  }

  void _procesarImportacion(BuildContext context, String texto) async {
    if (texto.isEmpty) return;
    final provider = context.read<ProductoProvider>();
    if (provider.categorias.isEmpty) await provider.cargarCategorias();

    Set<String> categoriasProcesadas = {};
    List<ProductoModel> listaAImportar = [];

    try {
      final lineas = texto.split('\n');
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i].trim();
        if (linea.isEmpty) continue;
        if (i == 0 && (linea.toLowerCase().contains('codigo'))) continue;

        final partes = linea.split(';');
        if (partes.length >= 2) {
          String codigoRaw = _limpiarDato(partes[0]);
          String nombre = _limpiarDato(partes[1]);
          double precio = 0;
          String catNombre = 'General';
          String unidad = 'u';

          if(partes.length > 2) precio = double.tryParse(_limpiarDato(partes[2]).replaceAll(r'$','').replaceAll('.','').replaceAll(',','.')) ?? 0;
          if(partes.length > 3) catNombre = _limpiarDato(partes[3]);
          if(partes.length > 4) unidad = _limpiarDato(partes[4]);

          // Detectamos el prefijo (Letras del código)
          String prefijoDetectado = codigoRaw.replaceAll(RegExp(r'[0-9\-]'), '').toUpperCase();
          if (prefijoDetectado.isEmpty) prefijoDetectado = catNombre.substring(0, 1).toUpperCase();

          String catId = catNombre.length >= 3 ? catNombre.substring(0, 3).toUpperCase() : catNombre.toUpperCase();

          bool existeCat = provider.categorias.any((c) => c.codigo == catId);
          if (!existeCat && !categoriasProcesadas.contains(catId)) {
            // ✅ CORRECCIÓN: Ahora pasamos los 3 argumentos requeridos
            await provider.crearCategoria(catNombre, catId, prefijoDetectado);
            categoriasProcesadas.add(catId);
          }

          listaAImportar.add(ProductoModel(
              id: codigoRaw,
              codigo: codigoRaw,
              nombre: nombre,
              precioSinIva: precio,
              categoriaId: catId,
              categoriaNombre: catNombre,
              unidadBase: unidad,
              cantidadDisponible: 0
          ));
        }
      }

      if (listaAImportar.isNotEmpty) {
        await provider.importarProductos(listaAImportar);
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${listaAImportar.length} productos importados')));
      }
    } catch (e) {
      print("Error importación: $e");
    }
  }
}