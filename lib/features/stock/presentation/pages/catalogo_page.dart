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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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
            onPressed: () => context.read<ProductoProvider>().recargarProductos(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductoFormPage()))
            .then((_) => context.read<ProductoProvider>().cargarProductos()),
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
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ProductoProvider>().cargarProductos();
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

          // 2. FILTROS DE ORDENAMIENTO (CHIPS)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Consumer<ProductoProvider>(
              builder: (context, provider, _) {
                final actual = provider.ordenActual;
                return Row(
                  children: [
                    _buildSortChip(context, 'A-Z', OrdenamientoCatalogo.nombreAZ, actual),
                    const SizedBox(width: 8),
                    _buildSortChip(context, 'Z-A', OrdenamientoCatalogo.nombreZA, actual),
                    const SizedBox(width: 8),
                    _buildSortChip(context, 'Por Tipo', OrdenamientoCatalogo.categoria, actual),
                    const SizedBox(width: 8),
                    _buildSortChip(context, 'Por Código', OrdenamientoCatalogo.codigo, actual),
                  ],
                );
              },
            ),
          ),

          // 3. Lista
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.productos.isEmpty) return const Center(child: Text('Sin productos. ¡Importa tu Excel!'));

                return ListView.separated(
                  itemCount: provider.productos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _buildItem(context, provider.productos[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(BuildContext context, String label, OrdenamientoCatalogo valor, OrdenamientoCatalogo actual) {
    final selected = valor == actual;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        context.read<ProductoProvider>().cambiarOrden(valor);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : Colors.black,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade300),
    );
  }

  Widget _buildItem(BuildContext context, ProductoModel p) {
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoFormPage(producto: p)))
          .then((_) => context.read<ProductoProvider>().cargarProductos()),

      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmarBorrado(context, p),
          ),
        ],
      ),
    );
  }

  void _confirmarBorrado(BuildContext context, ProductoModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar?'),
        content: Text('Se borrará ${p.nombre}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              context.read<ProductoProvider>().eliminarProducto(p.id ?? p.codigo);
              Navigator.pop(ctx);
            },
            child: const Text('BORRAR'),
          ),
        ],
      ),
    );
  }

  // --- IMPORTACIÓN INTELIGENTE ---
  void _mostrarDialogoImportacion(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pegar contenido CSV'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Orden esperado:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('CODIGO, MATERIAL, PRECIO, TIPO, UNIDAD', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.blue)),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pega aquí tu Excel...', filled: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton.icon(icon: const Icon(Icons.upload), label: const Text('IMPORTAR'), onPressed: () { _procesarImportacion(context, controller.text); Navigator.pop(ctx); }),
        ],
      ),
    );
  }

  // Función interna para limpiar comillas de Excel
  String _limpiarDato(String raw) {
    String s = raw.trim();
    if (s.startsWith('"') && s.endsWith('"')) {
      s = s.substring(1, s.length - 1);
    }
    return s.replaceAll('""', '"'); // Comillas dobles a simples
  }

  void _procesarImportacion(BuildContext context, String texto) async {
    if (texto.isEmpty) return;
    final provider = context.read<ProductoProvider>();
    await provider.cargarCategorias();

    Set<String> categoriasNuevasDetectadas = {};
    List<ProductoModel> listaAImportar = [];
    int ignorados = 0;

    try {
      final lineas = texto.split('\n');
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i].trim();
        if (linea.isEmpty) continue;
        if (i == 0 && (linea.toLowerCase().contains('codigo') || linea.toLowerCase().contains('materiales'))) continue;

        // Split respetando comillas básicas (simple) o split por coma
        final partes = linea.split(','); // Para Excel simple suele bastar

        if (partes.length >= 4) {
          // Aplicamos limpieza a cada parte
          String codigo = _limpiarDato(partes[0]);
          String nombre = _limpiarDato(partes[1]);
          String precioStr = _limpiarDato(partes[2]).replaceAll('\$', '');
          double precio = double.tryParse(precioStr) ?? 0.0;
          String nombreCategoria = _limpiarDato(partes[3]);
          String unidad = partes.length > 4 ? _limpiarDato(partes[4]) : 'Unidad';

          String catId = nombreCategoria.length >= 3 ? nombreCategoria.substring(0, 3).toUpperCase() : nombreCategoria.toUpperCase();
          bool existe = provider.categorias.any((c) => c.codigo == catId || c.nombre.toLowerCase() == nombreCategoria.toLowerCase());

          if (!existe && !categoriasNuevasDetectadas.contains(nombreCategoria)) {
            await provider.crearCategoria(nombreCategoria, catId);
            categoriasNuevasDetectadas.add(nombreCategoria);
          }

          listaAImportar.add(ProductoModel(
            id: codigo, codigo: codigo, nombre: nombre, precioSinIva: precio,
            categoriaId: catId, categoriaNombre: nombreCategoria, unidadBase: unidad, cantidadDisponible: 0,
          ));
        } else { ignorados++; }
      }

      if (listaAImportar.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando...')));
        await provider.importarProductos(listaAImportar);
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Importados: ${listaAImportar.length}'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }
}