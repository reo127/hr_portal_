import 'package:dio/dio.dart';
import '../models/leave_balance.dart';
import 'auth_service.dart';

class LeaveService {
  static const String baseUrl = 'https://hrp.aroha.co.in/api';
  late final Dio _dio;
  final AuthService _authService;

  LeaveService({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _dio = _authService.getDioWithAuth();
  }

  // Get leave balance for a user
  Future<LeaveBalance> getLeaveBalance(String userId) async {
    try {
      final response = await _dio.get(
        '/leaves/my-leave-balance/user/$userId',
      );

      if (response.statusCode == 200) {
        return LeaveBalance.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch leave balance: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Failed to fetch leave balance';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
