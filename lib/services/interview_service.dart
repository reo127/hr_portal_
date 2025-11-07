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
}
