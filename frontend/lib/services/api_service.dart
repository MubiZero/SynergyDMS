import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../models/user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('📤 ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('📥 ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }
  
  // Token Management
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }
  
  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }
  
  // User Data Management
  Future<void> saveUser(User user) async {
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
  }
  
  Future<User?> getUser() async {
    final userData = await _storage.read(key: AppConstants.userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }
  
  Future<void> deleteUser() async {
    await _storage.delete(key: AppConstants.userKey);
  }
  
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  // Auth Endpoints
  Future<Response> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? faculty,
  }) async {
    return await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': role,
      'faculty': faculty ?? '',
    });
  }
  
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }
  
  Future<Response> getProfile() async {
    return await _dio.get('/auth/profile');
  }
  
  // User Endpoints
  Future<Response> getPendingAdmins() async {
    return await _dio.get('/users/pending-admins');
  }
  
  Future<Response> approveAdmin(int userId) async {
    return await _dio.put('/users/$userId/approve');
  }
  
  Future<Response> getAdmins() async {
    return await _dio.get('/users/admins');
  }
  
  // Document Endpoints
  Future<Response> getDocuments({String? status, int? priority}) async {
    Map<String, dynamic> params = {};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    return await _dio.get('/documents', queryParameters: params);
  }
  
  Future<Response> getDocument(int id) async {
    return await _dio.get('/documents/$id');
  }
  
  Future<Response> createDocument({
    required String title,
    required String description,
    required int priority,
    String? filePath,
  }) async {
    return await _dio.post('/documents', data: {
      'title': title,
      'description': description,
      'priority': priority,
      'file_path': filePath ?? '',
    });
  }
  
  Future<Response> updateDocumentStatus(int id, String status, {String? reason}) async {
    return await _dio.put('/documents/$id/status', data: {
      'status': status,
      'reason': reason ?? '',
    });
  }
  
  Future<Response> delegateDocument(int id, int newAdminId) async {
    return await _dio.put('/documents/$id/delegate', data: {
      'new_admin_id': newAdminId,
    });
  }
  
  Future<Response> getDocumentHistory(int id) async {
    return await _dio.get('/documents/$id/history');
  }
  
  // Upload Endpoint
  Future<Response> uploadFile(String filePath, String fileName) async {
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return await _dio.post('/api/upload', data: formData);
  }
  
  // Upload file from bytes (for web)
  Future<Response> uploadFileBytes(List<int> bytes, String fileName) async {
    FormData formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    return await _dio.post('/api/upload', data: formData);
  }
  
  // Get file URL
  String getFileUrl(String filePath) {
    if (filePath.startsWith('http')) {
      return filePath;
    }
    return '${AppConstants.baseUrl}$filePath';
  }
}
