class AppConstants {
  // API Configuration
  // static const String baseUrl = 'http://10.0.2.2:8080'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8080'; // iOS Simulator / Web
  static const String baseUrl = 'http://108.181.167.236:8080'; // Production Server
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Polling Interval
  static const Duration pollInterval = Duration(seconds: 5);
  
  // Priorities
  static const Map<int, String> priorityLabels = {
    1: 'Низкий',
    2: 'Средний',
    3: 'Высокий',
  };
  
  // Statuses
  static const Map<String, String> statusLabels = {
    'pending': 'На рассмотрении',
    'approved': 'Одобрено',
    'rejected': 'Отклонено',
    'expired': 'Истекло',
  };
  
  // Faculties
  static const List<String> faculties = [
    'Факультет информатики',
    'Факультет экономики',
    'Факультет права',
    'Инженерный факультет',
    'Медицинский факультет',
    'Факультет искусств',
    'Факультет естественных наук',
    'Администрация',
  ];
}
