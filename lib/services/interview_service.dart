import 'package:dio/dio.dart';
import '../models/interview_stats.dart';
import '../models/interview.dart';
import 'storage_service.dart';

class InterviewService {
  static const String baseUrl = 'https://hrp.aroha.co.in/api';
  final Dio _dio;
  final StorageService _storageService;

  InterviewService({StorageService? storageService})
      : _storageService = storageService ?? StorageService(),
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  // Get interview statistics
  Future<InterviewStats> getInterviewStats() async {
    try {
      // Get token for authorization
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make the API call
      final response = await _dio.request(
        '/interviews/stats',
        options: Options(
          method: 'GET',
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json, text/plain, */*',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['stats'] != null) {
          return InterviewStats.fromJson(data['stats']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch interview stats: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
            e.response?.data['msg'] ??
            'Failed to fetch interview stats';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get interviews with pagination
  Future<Map<String, dynamic>> getInterviews({
    int page = 1,
    int limit = 10,
    String search = '',
  }) async {
    try {
      // Get token for authorization
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make the API call
      final response = await _dio.request(
        '/interviews',
        queryParameters: {
          'page': page,
          'limit': limit,
          'search': search,
        },
        options: Options(
          method: 'GET',
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json, text/plain, */*',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> &&
            data['data'] != null &&
            data['pagination'] != null) {
          final List<Interview> interviews = (data['data'] as List)
              .map((json) => Interview.fromJson(json))
              .toList();

          final pagination = InterviewPagination.fromJson(data['pagination']);

          return {
            'interviews': interviews,
            'pagination': pagination,
          };
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch interviews: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
            e.response?.data['msg'] ??
            'Failed to fetch interviews';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Create a new interview
  Future<Interview> createInterview({
    required String employeeName,
    required String date,
    required String userId,
    required String clientName,
    required String jobRole,
    required String questions,
    required String status,
  }) async {
    try {
      print('=== Creating Interview ===');
      print('Employee: $employeeName');
      print('Client: $clientName');
      print('Job Role: $jobRole');
      print('Date: $date');
      print('Status: $status');
      print('User ID: $userId');

      // Get token for authorization
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }
      print('Token found: ${token.substring(0, 20)}...');

      // Make the API call
      print('Making API call to: $baseUrl/interviews');
      final response = await _dio.request(
        '/interviews',
        data: {
          'employeeName': employeeName,
          'date': date,
          'userId': userId,
          'clientName': clientName,
          'jobRole': jobRole,
          'questions': questions,
          'status': status,
        },
        options: Options(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json, text/plain, */*',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('API Response: $data'); // Debug log
        print('Status Code: ${response.statusCode}');

        if (data is Map<String, dynamic>) {
          // Check if interview data is returned
          if (data['interview'] != null) {
            return Interview.fromJson(data['interview']);
          }
          // If no interview object but has success message, return a dummy interview
          // The UI will refresh and get the actual data
          else if (data['message'] != null &&
                   (data['message'].toString().contains('success') ||
                    data['message'].toString().contains('added'))) {
            print('Interview created successfully, but no interview object returned');
            // Return a minimal interview object - the list will refresh anyway
            return Interview(
              id: '',
              serialNumber: 0,
              clientName: clientName,
              date: date,
              jobRole: jobRole,
              questions: questions,
              employeeName: employeeName,
              userId: userId,
              status: status,
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
            );
          } else {
            throw Exception('Invalid response format. Response: $data');
          }
        } else {
          throw Exception('Invalid response format. Response: $data');
        }
      } else {
        throw Exception('Failed to create interview: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
            e.response?.data['msg'] ??
            'Failed to create interview';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
