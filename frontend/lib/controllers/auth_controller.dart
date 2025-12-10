import 'package:get/get.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    isLoading.value = true;
    try {
      final token = await _apiService.getToken();
      if (token != null) {
        final user = await _apiService.getUser();
        if (user != null) {
          currentUser.value = user;
          isLoggedIn.value = true;
        }
      }
    } catch (e) {
      print('Auth check error: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? faculty,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        faculty: faculty,
      );
      
      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final user = User.fromJson(userData['user']);
        final token = userData['token'];
        
        await _apiService.saveToken(token);
        await _apiService.saveUser(user);
        
        currentUser.value = user;
        isLoggedIn.value = true;
        
        Get.snackbar(
          'Успешно',
          user.isApproved 
              ? 'Регистрация прошла успешно!' 
              : 'Регистрация прошла успешно! Ожидайте одобрения администратора.',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      } else {
        errorMessage.value = response.data['message'] ?? 'Ошибка регистрации';
        Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      errorMessage.value = _getErrorMessage(e);
      Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      
      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final user = User.fromJson(userData['user']);
        final token = userData['token'];
        
        await _apiService.saveToken(token);
        await _apiService.saveUser(user);
        
        currentUser.value = user;
        isLoggedIn.value = true;
        
        Get.snackbar('Добро пожаловать', 'Привет, ${user.fullName}!', snackPosition: SnackPosition.BOTTOM);
        
        return true;
      } else {
        errorMessage.value = response.data['message'] ?? 'Ошибка входа';
        Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      errorMessage.value = _getErrorMessage(e);
      Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> logout() async {
    await _apiService.clearAll();
    currentUser.value = null;
    isLoggedIn.value = false;
    Get.offAllNamed('/login');
  }
  
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final errorStr = error.toString();
      if (errorStr.contains('401')) {
        return 'Неверный email или пароль';
      } else if (errorStr.contains('403')) {
        return 'Ваш аккаунт ожидает одобрения';
      } else if (errorStr.contains('409')) {
        return 'Email уже зарегистрирован';
      } else if (errorStr.contains('connection')) {
        return 'Ошибка соединения. Проверьте интернет.';
      }
    }
    return 'Произошла ошибка. Попробуйте снова.';
  }
}
