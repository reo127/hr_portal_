import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

class AuthService {
  final Dio _dio;
  final StorageService _storageService;

  AuthService({StorageService? storageService})
      : _storageService = storageService ?? StorageService(),
        _dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  // Login method
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Extract token expiry from JWT
        final token = data['token'];
        final decodedToken = JwtDecoder.decode(token);
        final tokenExpiry = decodedToken['exp'] as int;

        // Create user object
        final user = User(
          userId: decodedToken['userId'] ?? '',
          username: data['username'] ?? email,
          token: token,
          loginTime: data['loginTimeIST'] ?? '',
        );

        // Save to secure storage
        await _storageService.saveAuthData(
          token: token,
          userId: user.userId,
          username: user.username,
          tokenExpiry: tokenExpiry,
          loginTime: user.loginTime,
        );

        return user;
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Login failed';
        throw Exception(message);
      } else {
        // Network error
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Check authentication status
  Future<bool> isAuthenticated() async {
    final hasToken = await _storageService.hasToken();
    if (!hasToken) return false;

    final isValid = await _storageService.isTokenValid();
    if (!isValid) {
      // Token expired, clear storage
      await logout();
      return false;
    }

    return true;
  }

  // Get current user from storage
  Future<User?> getCurrentUser() async {
    final token = await _storageService.getToken();
    final userId = await _storageService.getUserId();
    final username = await _storageService.getUsername();
    final loginTime = await _storageService.getLoginTime();

    if (token == null || userId == null || username == null) {
      return null;
    }

    return User(
      userId: userId,
      username: username,
      token: token,
      loginTime: loginTime ?? '',
    );
  }

  // Logout
  Future<void> logout() async {
    await _storageService.clearAuthData();
  }

  // Generate OTP for password reset
  Future<String> generateOTP(String email) async {
    try {
      final response = await _dio.get(
        '/generateOTP',
        queryParameters: {'email': email},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final otpCode = data['code'] ?? '';

        // Send the OTP via email
        await sendOTPEmail(email, otpCode);

        return otpCode;
      } else {
        throw Exception('Failed to generate OTP');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Failed to generate OTP';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Send OTP email
  Future<void> sendOTPEmail(String email, String otpCode) async {
    try {
      final response = await _dio.post(
        '/registerMail',
        data: {
          'username': email,
          'userEmail': email,
          'text': 'Your Password Recovery OTP is $otpCode. Verify and recover your password.',
          'subject': 'Password recovery OTP',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send OTP email');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Failed to send OTP email';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String email, String code) async {
    try {
      final response = await _dio.get(
        '/verifyOTP',
        queryParameters: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('OTP verification failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Invalid OTP';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email, String password) async {
    try {
      final response = await _dio.put(
        '/resetPassword',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Password reset failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Failed to reset password';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get Dio instance with auth headers for other API calls
  Dio getDioWithAuth() {
    return Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ))..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to every request
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized
          if (error.response?.statusCode == 401) {
            await logout();
          }
          handler.next(error);
        },
      ));
  }
}
