import 'dart:async';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../models/document.dart';
import '../models/history.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class DocumentController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final RxList<Document> documents = <Document>[].obs;
  final RxList<History> currentDocHistory = <History>[].obs;
  final RxList<User> admins = <User>[].obs;
  final Rx<Document?> selectedDocument = Rx<Document?>(null);
  
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxString uploadedFilePath = ''.obs;
  final RxString uploadedFileName = ''.obs;
  final RxString errorMessage = ''.obs;
  
  Timer? _pollTimer;
  
  @override
  void onInit() {
    super.onInit();
    fetchDocuments();
    fetchAdmins();
    startPolling();
  }
  
  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }
  
  void startPolling() {
    _pollTimer = Timer.periodic(AppConstants.pollInterval, (_) {
      fetchDocuments(silent: true);
    });
  }
  
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
  
  Future<void> fetchDocuments({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    
    try {
      final response = await _apiService.getDocuments();
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        documents.value = data.map((json) => Document.fromJson(json)).toList();
      }
    } catch (e) {
      if (!silent) {
        errorMessage.value = 'Не удалось загрузить документы';
        Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (!silent) isLoading.value = false;
    }
  }
  
  Future<void> fetchDocument(int id) async {
    isLoading.value = true;
    
    try {
      final response = await _apiService.getDocument(id);
      
      if (response.data['success'] == true) {
        selectedDocument.value = Document.fromJson(response.data['data']);
      }
    } catch (e) {
      errorMessage.value = 'Не удалось загрузить документ';
      Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> fetchDocumentHistory(int documentId) async {
    try {
      final response = await _apiService.getDocumentHistory(documentId);
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        currentDocHistory.value = data.map((json) => History.fromJson(json)).toList();
      }
    } catch (e) {
      print('Failed to fetch history: $e');
    }
  }
  
  Future<void> fetchAdmins() async {
    try {
      final response = await _apiService.getAdmins();
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        admins.value = data.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {
      print('Failed to fetch admins: $e');
    }
  }
  
  Future<bool> createDocument({
    required String title,
    required String description,
    required int priority,
  }) async {
    isLoading.value = true;
    
    try {
      final response = await _apiService.createDocument(
        title: title,
        description: description,
        priority: priority,
        filePath: uploadedFilePath.value,
      );
      
      if (response.data['success'] == true) {
        Get.snackbar('Успешно', 'Документ создан!', snackPosition: SnackPosition.BOTTOM);
        clearUpload();
        await fetchDocuments();
        return true;
      } else {
        errorMessage.value = response.data['message'] ?? 'Не удалось создать документ';
        Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Не удалось создать документ';
      Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> updateStatus(int documentId, String status, {String? reason}) async {
    isLoading.value = true;
    
    try {
      final response = await _apiService.updateDocumentStatus(
        documentId, 
        status, 
        reason: reason,
      );
      
      if (response.data['success'] == true) {
        Get.snackbar(
          'Успешно', 
          status == 'approved' ? 'Документ одобрен!' : 'Документ отклонён!',
          snackPosition: SnackPosition.BOTTOM,
        );
        await fetchDocuments();
        await fetchDocument(documentId);
        await fetchDocumentHistory(documentId);
        return true;
      } else {
        errorMessage.value = response.data['message'] ?? 'Не удалось обновить статус';
        Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Не удалось обновить статус';
      Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> delegateDocument(int documentId, int newAdminId) async {
    isLoading.value = true;
    
    try {
      final response = await _apiService.delegateDocument(documentId, newAdminId);
      
      if (response.data['success'] == true) {
        Get.snackbar('Успешно', 'Документ передан!', snackPosition: SnackPosition.BOTTOM);
        await fetchDocuments();
        await fetchDocument(documentId);
        await fetchDocumentHistory(documentId);
        return true;
      } else {
        errorMessage.value = response.data['message'] ?? 'Не удалось передать документ';
        Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Не удалось передать документ';
      Get.snackbar('Ошибка', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'png', 'jpg', 'jpeg', 'gif', 'zip', 'rar'],
        withData: true,
      );
      
      if (result != null && result.files.single.bytes != null) {
        isUploading.value = true;
        
        final file = result.files.single;
        final response = await _apiService.uploadFileBytes(file.bytes!, file.name);
        
        if (response.data['success'] == true) {
          uploadedFilePath.value = response.data['data']['url'];
          uploadedFileName.value = file.name;
          Get.snackbar('Успешно', 'Файл загружен!', snackPosition: SnackPosition.BOTTOM);
        } else {
          Get.snackbar('Ошибка', 'Не удалось загрузить файл', snackPosition: SnackPosition.BOTTOM);
        }
      } else if (result != null && result.files.single.path != null) {
        isUploading.value = true;
        
        final file = result.files.single;
        final response = await _apiService.uploadFile(file.path!, file.name);
        
        if (response.data['success'] == true) {
          uploadedFilePath.value = response.data['data']['url'];
          uploadedFileName.value = file.name;
          Get.snackbar('Успешно', 'Файл загружен!', snackPosition: SnackPosition.BOTTOM);
        } else {
          Get.snackbar('Ошибка', 'Не удалось загрузить файл', snackPosition: SnackPosition.BOTTOM);
        }
      }
    } catch (e) {
      print('File upload error: $e');
      Get.snackbar('Ошибка', 'Не удалось загрузить файл', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUploading.value = false;
    }
  }
  
  void clearUpload() {
    uploadedFilePath.value = '';
    uploadedFileName.value = '';
  }
  
  String getFileUrl(String path) {
    return _apiService.getFileUrl(path);
  }
}
