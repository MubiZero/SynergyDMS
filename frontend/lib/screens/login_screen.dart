import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (success) {
        Get.offAllNamed('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildLoginCard(),
                        const SizedBox(height: 24),
                        _buildRegisterLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
        const SizedBox(height: 24),
        const Text(
          'Synergy DMS',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          'Система Управления Документами',
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Добро пожаловать', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Войдите для продолжения', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withOpacity(0.8)), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), filled: true, fillColor: AppTheme.cardColor),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Введите email';
              if (!GetUtils.isEmail(value)) return 'Введите корректный email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: AppTheme.cardColor,
            ),
            validator: (value) => (value == null || value.isEmpty) ? 'Введите пароль' : null,
          ),
          const SizedBox(height: 32),
          Obx(() => SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _authController.isLoading.value ? null : _handleLogin,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8),
              child: _authController.isLoading.value
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Войти', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Нет аккаунта? ', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8))),
        TextButton(
          onPressed: () => Get.toNamed('/register'),
          child: const Text('Зарегистрироваться', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
