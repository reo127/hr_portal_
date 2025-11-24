import 'package:dio/dio.dart';
import '../models/holiday.dart';
import 'auth_service.dart';

class HolidayService {
  static const String baseUrl = 'https://hrp.aroha.co.in/api';
  late final Dio _dio;
  final AuthService _authService;

  HolidayService({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _dio = _authService.getDioWithAuth();
  }

  // Get all holidays
  Future<List<Holiday>> getAllHolidays() async {
    try {
      print('DEBUG Holiday: Fetching holidays from API...');
      final response = await _dio.get(
        '/holidays/all',
      );

      print('DEBUG Holiday: Response status: ${response.statusCode}');
      print('DEBUG Holiday: Response data type: ${response.data.runtimeType}');
      print('DEBUG Holiday: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('DEBUG Holiday: Data success: ${data['success']}');
        print('DEBUG Holiday: Data has holidays: ${data['holidays'] != null}');

        if (data['success'] == true && data['holidays'] != null) {
          final List<dynamic> holidaysJson = data['holidays'];
          print('DEBUG Holiday: Holidays count: ${holidaysJson.length}');
          final holidays = holidaysJson.map((json) => Holiday.fromJson(json)).toList();
          print('DEBUG Holiday: Parsed ${holidays.length} holidays');
          return holidays;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch holidays: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ??
                       e.response?.data['msg'] ??
                       'Failed to fetch holidays';
        throw Exception(message);
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
