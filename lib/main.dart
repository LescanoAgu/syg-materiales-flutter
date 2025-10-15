import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/database/database_helper.dart';
import 'core/database/seed_data.dart';
import 'features/stock/presentation/providers/producto_provider.dart';
import 'features/stock/presentation/pages/catalogo_page.dart';

/// Punto de entrada de la aplicación S&G Materiales
void main() async {
  // Asegura que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicializar la base de datos
  print('🚀 Inicializando aplicación...');
  try {
    await DatabaseHelper().database;
    print('✅ Base de datos inicializada');

    // Cargar datos de ejemplo (solo si la BD está vacía)
    await SeedData().cargarTodo();

  } catch (e) {
    print('❌ Error al inicializar: $e');
  }

  // Ejecutar la aplicación
  runApp(const SyGMaterialesApp());
}

/// Widget raíz de la aplicación
class SyGMaterialesApp extends StatelessWidget {
  const SyGMaterialesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider hace que ProductoProvider esté disponible
    // en TODA la app
    return ChangeNotifierProvider(
      create: (context) => ProductoProvider(),
      child: MaterialApp(
        title: 'S&G Materiales',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,

          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            elevation: 0,
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            elevation: 4,
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),

          cardTheme: CardThemeData(
            color: AppColors.surface,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            error: AppColors.error,
            surface: AppColors.surface,
            background: AppColors.background,
          ),

          useMaterial3: true,
        ),

        // ========================================
        // PANTALLA INICIAL: Stock List
        // ========================================
        home: const CatalogoPage(),
      ),
    );
  }
}