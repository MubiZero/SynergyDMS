import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/create_document_screen.dart';
import 'screens/document_detail_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  runApp(const SynergyDMSApp());
}

class SynergyDMSApp extends StatelessWidget {
  const SynergyDMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Synergy DMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
      home: const AuthWrapper(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        GetPage(name: '/create-document', page: () => const CreateDocumentScreen()),
        GetPage(name: '/document/:id', page: () => const DocumentDetailScreen()),
      ],
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      if (authController.isLoading.value) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.description_rounded, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text('Загрузка...', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7))),
              ],
            ),
          ),
        );
      }

      if (authController.isLoggedIn.value && authController.currentUser.value?.isApproved == true) {
        return const DashboardScreen();
      }

      return const LoginScreen();
    });
  }
}
