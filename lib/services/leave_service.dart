import 'package:dio/dio.dart';
import '../models/leave_balance.dart';
import '../models/leave.dart';
import '../models/comp_off.dart';
import 'auth_service.dart';

class LeaveService {
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

  // Apply for leave
  Future<void> applyLeave({
    required String userId,
    required String leaveType,
    required String startDate,
    required String endDate,
    required String session,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/leaves/apply',
        data: {
          'userId': userId,
          'leaveType': leaveType,
          'startDate': startDate,
          'endDate': endDate,
          'session': session,
          'reason': reason,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception('Failed to apply leave: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Failed to apply leave';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get all leaves for calendar (unfiltered - shows everyone's leaves)
  Future<List<Leave>> getAllLeavesForCalendar() async {
    try {
      final response = await _dio.get(
        '/leaves/all-leaves-calendar',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final allLeaves = data.map((json) => Leave.fromJson(json)).toList();
        return allLeaves;
      } else {
        throw Exception('Failed to fetch leaves: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Failed to fetch leaves';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get all leaves history (filtered by userId on client side)
  Future<List<Leave>> getAllLeaves(String currentUserId) async {
    try {
      print('DEBUG: Fetching leaves for userId: $currentUserId');

      final response = await _dio.get(
        '/leaves/all-leaves-calendar',
      );

      print('DEBUG: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('DEBUG: Total leaves in response: ${data.length}');

        // Parse all leaves
        final allLeaves = data.map((json) => Leave.fromJson(json)).toList();
        print('DEBUG: Parsed ${allLeaves.length} leaves');

        // Debug: Print first few user IDs
        if (allLeaves.isNotEmpty) {
          print('DEBUG: Sample user IDs from response:');
          for (var i = 0; i < (allLeaves.length > 3 ? 3 : allLeaves.length); i++) {
            print('  - ${allLeaves[i].userId.id}');
          }
        }

        // Filter to only show current user's leaves
        final userLeaves = allLeaves
            .where((leave) => leave.userId.id == currentUserId)
            .toList();

        print('DEBUG: Filtered to ${userLeaves.length} leaves for current user');

        // Sort by applied date descending (newest first)
        userLeaves.sort((a, b) {
          try {
            final dateA = DateTime.parse(a.appliedDate);
            final dateB = DateTime.parse(b.appliedDate);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });

        return userLeaves;
      } else {
        throw Exception('Failed to fetch leave history: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('DEBUG: DioException: ${e.message}');
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Failed to fetch leave history';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      print('DEBUG: Exception: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Apply for comp-off
  Future<CompOff> applyCompOff({
    required String userId,
    required String startDate,
    required String endDate,
    required String reason,
    String? filePath,
    String? fileName,
  }) async {
    try {
      // Create form data
      final formData = FormData.fromMap({
        'userId': userId,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
      });

      // Add file if provided
      if (filePath != null && fileName != null) {
        formData.files.add(
          MapEntry(
            'proof',
            await MultipartFile.fromFile(
              filePath,
              filename: fileName,
            ),
          ),
        );
      }

      print('DEBUG: Applying comp-off with data: userId=$userId, startDate=$startDate, endDate=$endDate');

      final response = await _dio.post(
        '/comp-offs/apply',
        data: formData,
      );

      print('DEBUG: Comp-off response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('DEBUG: Comp-off response: $data');

        if (data['compOff'] != null) {
          return CompOff.fromJson(data['compOff']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to apply comp-off: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('DEBUG: DioException in applyCompOff: ${e.message}');
      if (e.response != null) {
        print('DEBUG: Error response: ${e.response?.data}');
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Failed to apply comp-off';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      print('DEBUG: Exception in applyCompOff: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
