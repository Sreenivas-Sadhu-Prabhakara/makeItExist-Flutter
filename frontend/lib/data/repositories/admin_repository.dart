import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/user_model.dart';

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  Future<List<UserModel>> listUsers() async {
    try {
      final response = await apiClient.get(ApiEndpoints.adminUsers);
      final List data = response.data['data'] ?? [];
      return data.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await apiClient.put(
        ApiEndpoints.adminResetPassword(userId),
        data: {'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
