import 'package:get/get.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final RxList<User> pendingAdmins = <User>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchPendingAdmins();
  }
  
  Future<void> fetchPendingAdmins() async {
    isLoading.value = true;
    
    try {
      final response = await _apiService.getPendingAdmins();
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        pendingAdmins.value = data.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {
      errorMessage.value = 'Не удалось загрузить заявки';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> approveAdmin(int userId) async {
    isLoading.value = true;
    
    try {
      final response = await _apiService.approveAdmin(userId);
      
      if (response.data['success'] == true) {
        Get.snackbar('Успешно', 'Администратор одобрен!', snackPosition: SnackPosition.BOTTOM);
        await fetchPendingAdmins();
        return true;
      } else {
        errorMessage.value = response.data['message'] ?? 'Не удалось одобрить';
        Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Не удалось одобрить администратора';
      Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
