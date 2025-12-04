import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/pages/admin_home_page.dart';
import '../../features/home/presentation/pages/jefe_obra_home_page.dart';
import '../../features/home/presentation/pages/panolero_home_page.dart';
import '../../features/stock/presentation/pages/stock_page.dart';

// ✅ Solo debe contener la clase MainLayout, NADA MÁS.
class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    if (usuario == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (usuario.esAdmin) {
      return const AdminHomePage();
    } else if (usuario.esJefeObra) {
      return const JefeObraHomePage();
    } else if (usuario.esPanolero) {
      return const PanoleroHomePage();
    }

    return const StockPage();
  }
}