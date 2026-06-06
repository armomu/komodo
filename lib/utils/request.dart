import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:komodo/components/show_snackbar.dart';
import 'package:komodo/config/base_url.dart';
import 'package:komodo/models/api_response.dart';
import 'package:komodo/routes/app_routes.dart';

Future<ApiResponse<T>> appDio<T>(
  String path, {
  Map<String, dynamic>? params,
  Map<String, dynamic>? data,
  String method = 'get',
  bool loading = true,
  bool errTip = true,
  String baseUrl = '',
  T Function(dynamic json)? fromJsonT,
}) async {
  final box = GetStorage();
  final token = box.read<String>('access_token') ?? '';
  baseUrl = baseUrl == '' ? BaseUrl.host() : baseUrl;

  final option = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: <String, dynamic>{
      HttpHeaders.userAgentHeader: 'dio',
      'api': '1.0.0',
      'Connection': 'keep-alive',
      'Authorization': 'Bearer $token',
    },
    responseType: ResponseType.json,
  );

  var dio = Dio(option);

  debugPrint('$path==================');
  if (data != null) {
    debugPrint('data==================');
    debugPrint('$data');
  }
  if (params != null) {
    debugPrint('params==================');
    debugPrint('$params');
  }

  try {
    final response = await dio.request<dynamic>(
      path,
      data: data,
      queryParameters: params,
      options: Options(method: method),
    );

    final resData = response.data as Map<String, dynamic>;

    // 401 未授权
    if (resData['code'] == 401) {
      Get.toNamed<dynamic>(Routes.login);
      throw Exception('Unauthorized');
    }

    // 业务错误
    if (resData['code'] != 0) {
      if (errTip) {
        AppSnackBar.show(resData['message'] ?? '请求失败');
      }
      throw Exception(resData['message'] ?? '请求失败');
    }

    // 🔥 关键：使用 ApiResponse.fromJson 构造返回值
    // 注意：这里需要传递泛型参数 T 和转换函数 fromJsonT
    return ApiResponse<T>.fromJson(resData, fromJsonT);
  } on DioException catch (e) {
    debugPrint('DioError: $e');
    if (errTip) {
      AppSnackBar.show(e.type.toString());
    }
    throw Exception(e.type.toString());
  } catch (e) {
    debugPrint('=========appDio Error: $e==========================');
    if (errTip) {
      AppSnackBar.show(e.toString());
    }
    throw Exception(e.toString());
  }
}
