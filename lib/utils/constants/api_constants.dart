/// API-related constants
class ApiConstants {
  // API Versioning
  static const String apiVersion = 'v1';
  static const String baseUrl = 'https://api.dabbler.com';
  static const String apiBaseUrl = '$baseUrl/api/$apiVersion';

  // Timeout Configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Rate Limiting
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);
  static const Duration rateLimitCooldown = Duration(minutes: 5);
  
  // Common Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-App-Version': '1.0.0',
    'X-Platform': 'mobile',
  };
  
  // Authentication
  static const String authTokenHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  
  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/user/profile';
  static const String settings = '/user/settings';
  
  // Cache Control
  static const Map<String, String> cacheHeaders = {
    'Cache-Control': 'public, max-age=300', // 5 minutes
    'Pragma': 'cache',
  };
  
  // Error Codes
  static const int unauthorizedError = 401;
  static const int forbiddenError = 403;
  static const int notFoundError = 404;
  static const int serverError = 500;
  
  // Pagination Parameters
  static const String pageParam = 'page';
  static const String limitParam = 'limit';
  static const String sortParam = 'sort';
  static const String orderParam = 'order';
  
  // Search Parameters
  static const String searchParam = 'q';
  static const String filterParam = 'filter';
  
  // Upload
  static const String uploadEndpoint = '/upload';
  static const Map<String, String> uploadHeaders = {
    'Content-Type': 'multipart/form-data',
  };
  
  // WebSocket
  static const String wsBaseUrl = 'wss://api.dabbler.com/ws';
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const int wsMaxReconnectAttempts = 5;
}
