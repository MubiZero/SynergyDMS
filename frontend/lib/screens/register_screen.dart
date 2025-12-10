import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  String _selectedRole = 'student';
  String? _selectedFaculty;
  bool _obscurePassword = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == 'student' && _selectedFaculty == null) {
        Get.snackbar('Ошибка', 'Выберите факультет', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      
      final success = await _authController.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        faculty: _selectedFaculty,
      );
      
      if (success) {
        if (_authController.currentUser.value?.isApproved ?? false) {
          Get.offAllNamed('/dashboard');
        } else {
          Get.offAllNamed('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildRegisterCard(),
                      const SizedBox(height: 24),
                      _buildLoginLink(),
                    ],
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
          width: 80, height: 80,
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]),
          child: const Icon(Icons.person_add_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text('Регистрация', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text('Присоединяйтесь к Synergy DMS', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _fullNameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(labelText: 'ФИО', prefixIcon: const Icon(Icons.person_outline), filled: true, fillColor: AppTheme.cardColor),
            validator: (value) => (value == null || value.isEmpty) ? 'Введите ФИО' : null,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
              filled: true, fillColor: AppTheme.cardColor,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Введите пароль';
              if (value.length < 6) return 'Пароль должен быть не менее 6 символов';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.textMuted)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                isExpanded: true,
                dropdownColor: AppTheme.cardColor,
                style: const TextStyle(color: AppTheme.textPrimary),
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Студент')),
                  DropdownMenuItem(value: 'admin', child: Text('Администратор')),
                ],
                onChanged: (value) => setState(() { _selectedRole = value!; if (value != 'student') _selectedFaculty = null; }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedRole == 'student')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.textMuted)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFaculty,
                  hint: const Text('Выберите факультет', style: TextStyle(color: AppTheme.textSecondary)),
                  isExpanded: true,
                  dropdownColor: AppTheme.cardColor,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                  items: AppConstants.faculties.map((faculty) => DropdownMenuItem(value: faculty, child: Text(faculty))).toList(),
                  onChanged: (value) => setState(() => _selectedFaculty = value),
                ),
              ),
            ),
          if (_selectedRole == 'admin')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warningColor.withOpacity(0.3))),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warningColor.withOpacity(0.8), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Аккаунты администраторов требуют одобрения супер-администратора.', style: TextStyle(color: AppTheme.warningColor.withOpacity(0.9), fontSize: 12))),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Obx(() => SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _authController.isLoading.value ? null : _handleRegister,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8),
              child: _authController.isLoading.value
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Создать аккаунт', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Уже есть аккаунт? ', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8))),
        TextButton(onPressed: () => Get.back(), child: const Text('Войти', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
      ],
    );
  }
}
