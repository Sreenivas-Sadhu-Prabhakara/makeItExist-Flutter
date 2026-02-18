import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/request_model.dart';

class RequestRepository {
  final ApiClient apiClient;

  RequestRepository({required this.apiClient});

  Future<BuildRequestModel> createRequest(CreateBuildRequestInput input) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.requests,
        data: input.toJson(),
      );
      return BuildRequestModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<BuildRequestModel>> getMyRequests({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.requests,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final List data = response.data['data'] ?? [];
      return data.map((json) => BuildRequestModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<BuildRequestModel> getRequestById(String id) async {
    try {
      final response = await apiClient.get(ApiEndpoints.requestById(id));
      return BuildRequestModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
