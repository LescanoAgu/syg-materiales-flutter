import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import '../../../../core/widgets/app_drawer.dart';
import 'producto_detalle_page.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductoProvider>();
      provider.cargarCategorias(); // Cargar las categorías para los chips
      provider.cargarProductos(recargar: true); // Cargar productos iniciales
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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar CSV',
            onPressed: () => _mostrarDialogoImportacion(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductoProvider>().cargarProductos(recargar: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductoFormPage()))
            .then((_) => context.read<ProductoProvider>().cargarProductos(recargar: true)),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 1. Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar material...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ProductoProvider>().buscarProductos('');
                  },
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // 2. FILTROS DE CATEGORÍA (Horizontal Scroll)
          SizedBox(
            height: 50,
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Chip "Todos"
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
                    // Chips de Categorías dinámicas
                    ...provider.categorias.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat.nombre),
                          selected: provider.categoriaFiltroId == cat.codigo,
                          onSelected: (bool selected) {
                            // Si se deselecciona, volvemos a 'null' (Todos). Si se selecciona, mandamos el ID.
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

          const Divider(height: 1),

          // 3. Lista con Lazy Loading
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.productos.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.productos.isEmpty) {
                  return const Center(child: Text('No hay productos.'));
                }

                return ListView.separated(
                  controller: _scrollController,
                  itemCount: provider.productos.length + (provider.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    if (i == provider.productos.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _buildItem(context, provider.productos[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, ProductoModel p) {
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoFormPage(producto: p)))
          .then((_) => context.read<ProductoProvider>().cargarProductos(recargar: true)),

      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        // Mostramos las primeras 2 letras del código o '?'
        child: Text(
            p.codigo.length > 2 ? p.codigo.substring(0,2) : (p.nombre.isNotEmpty ? p.nombre[0] : '?'),
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)
        ),
      ),
      title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${p.codigo} • ${p.categoriaNombre ?? "-"}', style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Stock: ${p.cantidadFormateada}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
              if((p.precioSinIva ?? 0) > 0)
                Text('\$${p.precioSinIva}', style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.blue),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MovimientoHistorialPage(productoId: p.codigo)));
            },
          ),
        ],
      ),
    );
  }

  // --- IMPORTACIÓN DE EXCEL (Lógica corregida) ---
  void _mostrarDialogoImportacion(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pegar contenido CSV (Excel)'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Formato esperado (Punto y coma):', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('CODIGO; MATERIAL; PRECIO; TIPO; UNIDAD', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.blue)),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pega aquí el contenido...', filled: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('IMPORTAR'),
              onPressed: () {
                _procesarImportacion(context, controller.text);
                Navigator.pop(ctx);
              }
          ),
        ],
      ),
    );
  }

  String _limpiarDato(String raw) {
    String s = raw.trim();
    if (s.startsWith('"') && s.endsWith('"')) {
      s = s.substring(1, s.length - 1);
    }
    return s.replaceAll('""', '"');
  }

  void _procesarImportacion(BuildContext context, String texto) async {
    if (texto.isEmpty) return;
    final provider = context.read<ProductoProvider>();
    // Aseguramos tener las categorías para no duplicarlas
    if (provider.categorias.isEmpty) await provider.cargarCategorias();

    Set<String> categoriasNuevasDetectadas = {};
    List<ProductoModel> listaAImportar = [];
    int ignorados = 0;

    try {
      final lineas = texto.split('\n');
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i].trim();
        if (linea.isEmpty) continue;
        // Ignorar encabezados probables
        if (i == 0 && (linea.toLowerCase().contains('codigo') || linea.toLowerCase().startsWith('a;'))) continue;

        // SEPARADOR PUNTO Y COMA
        final partes = linea.split(';');

        if (partes.length >= 4) {
          String codigo = _limpiarDato(partes[0]);
          String nombre = _limpiarDato(partes[1]);
          // Limpieza de precio: quitar $, puntos de miles, y cambiar coma decimal por punto para Dart
          String precioStr = _limpiarDato(partes[2])
              .replaceAll(r'$', '')
              .replaceAll('.', '') // Quitar separador miles
              .replaceAll(',', '.'); // Coma decimal a punto

          double precio = double.tryParse(precioStr) ?? 0.0;
          String nombreCategoria = _limpiarDato(partes[3]);
          String unidad = partes.length > 4 ? _limpiarDato(partes[4]) : 'u';

          // ID Categoría: Las 3 primeras letras en mayúscula (Agua -> AGU)
          String catId = nombreCategoria.length >= 3
              ? nombreCategoria.substring(0, 3).toUpperCase()
              : nombreCategoria.toUpperCase();

          // Lógica de Categorías: Si no existe en el provider ni en las detectadas, la creamos
          bool existe = provider.categorias.any((c) => c.codigo == catId || c.nombre.toLowerCase() == nombreCategoria.toLowerCase());

          if (!existe && !categoriasNuevasDetectadas.contains(nombreCategoria)) {
            await provider.crearCategoria(nombreCategoria, catId);
            categoriasNuevasDetectadas.add(nombreCategoria);
          }

          listaAImportar.add(ProductoModel(
            id: codigo,
            codigo: codigo,
            nombre: nombre,
            precioSinIva: precio,
            categoriaId: catId,
            categoriaNombre: nombreCategoria,
            unidadBase: unidad,
            cantidadDisponible: 0,
          ));
        } else {
          ignorados++;
        }
      }

      if (listaAImportar.isNotEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Procesando ${listaAImportar.length} productos...')));

        await provider.importarProductos(listaAImportar);

        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('✅ Éxito: ${listaAImportar.length} productos importados.'),
                  backgroundColor: AppColors.success
              )
          );
        }
      } else {
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ No se leyeron productos. Verifica el separador (;).')));
      }
    } catch (e) {
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error crítico: $e'), backgroundColor: AppColors.error));
    }
  }
}