import 'package:dio/dio.dart';
import '../models/task.dart';
import 'storage_service.dart';

class TaskService {
  static const String baseUrl = 'https://hrp.aroha.co.in/api';
  final Dio _dio;
  final StorageService _storageService;

  TaskService({StorageService? storageService})
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

  // Get all tasks for the current user with pagination
  Future<Map<String, dynamic>> getTasks({
    int page = 1,
    int limit = 5,
  }) async {
    try {
      // Get user ID from storage
      final userId = await _storageService.getUserId();
      print('DEBUG: userId = $userId');
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get token for authorization
      final token = await _storageService.getToken();
      print('DEBUG: token = ${token?.substring(0, 20)}...');
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make the API call
      final url = '/tasks/AllTasksByUserId/$userId';
      print('DEBUG: Making API call to: $baseUrl$url');

      final response = await _dio.request(
        url,
        options: Options(
          method: 'GET',
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json, text/plain, */*',
          },
        ),
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response data type: ${response.data.runtimeType}');
      print('DEBUG: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // The API returns a list of tasks directly
        List<Task> allTasks = [];
        if (data is List) {
          print('DEBUG: Data is a List with ${data.length} items');
          allTasks = data.map((json) => Task.fromJson(json)).toList();
        } else {
          print('DEBUG: Data is not a List, it is ${data.runtimeType}');
        }

        print('DEBUG: Total tasks parsed: ${allTasks.length}');

        // Implement client-side pagination
        final totalTasks = allTasks.length;
        final startIndex = (page - 1) * limit;
        final endIndex = startIndex + limit;

        final paginatedTasks = allTasks.sublist(
          startIndex,
          endIndex > totalTasks ? totalTasks : endIndex,
        );

        print('DEBUG: Returning ${paginatedTasks.length} tasks for page $page');

        return {
          'tasks': paginatedTasks,
          'total': totalTasks,
          'page': page,
          'limit': limit,
          'totalPages': (totalTasks / limit).ceil(),
          'hasMore': endIndex < totalTasks,
        };
      } else {
        throw Exception('Failed to fetch tasks: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('DEBUG: DioException caught');
      print('DEBUG: Error type: ${e.type}');
      print('DEBUG: Error message: ${e.message}');
      print('DEBUG: Response: ${e.response?.data}');

      if (e.response != null) {
        final message = e.response?.data['message'] ??
            e.response?.data['msg'] ??
            'Failed to fetch tasks';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      print('DEBUG: General exception: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Create a new task
  Future<Task> createTask(Task task) async {
    try {
      // Get token for authorization
      final token = await _storageService.getToken();
      print('DEBUG: token = ${token?.substring(0, 20)}...');
      if (token == null) {
        throw Exception('Token not found');
      }

      // Make the API call
      final url = '/tasks';
      print('DEBUG: Making API call to: $baseUrl$url');
      print('DEBUG: Task data: ${task.toJson()}');

      final response = await _dio.request(
        url,
        options: Options(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json, text/plain, */*',
            'Content-Type': 'application/json',
          },
        ),
        data: task.toJson(),
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // The API returns {msg, task}
        if (data is Map<String, dynamic> && data['task'] != null) {
          return Task.fromJson(data['task']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to create task: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('DEBUG: DioException caught');
      print('DEBUG: Error type: ${e.type}');
      print('DEBUG: Error message: ${e.message}');
      print('DEBUG: Response: ${e.response?.data}');

      if (e.response != null) {
        final message = e.response?.data['message'] ??
            e.response?.data['msg'] ??
            'Failed to create task';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      print('DEBUG: General exception: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
