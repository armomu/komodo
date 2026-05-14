import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:komodo/models/api_response.dart';

/// 统一 API 请求服务
/// 基于 GetX 的 GetConnect 封装，提供统一的 GET/POST 请求能力。
/// 支持 token 自动注入、错误处理、超时控制。
class ApiService extends GetxService {
  static ApiService get to => Get.find();

  /// 后端服务基础地址
  static const String _baseUrl = 'http://192.168.1.38:8085';

  /// 请求超时时间
  static const Duration _timeout = Duration(seconds: 30);

  /// 本地存储中的 token key
  static const String _tokenStorageKey = 'access_token';

  late final GetConnect _connect;

  @override
  void onInit() {
    super.onInit();
    _initConnect();
  }

  void _initConnect() {
    _connect = GetConnect(timeout: _timeout);
    _connect.httpClient.baseUrl = _baseUrl;

    // ========== 请求拦截器：自动注入 token ==========
    _connect.httpClient.addRequestModifier<void>((request) {
      final token = _getToken();
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Content-Type'] = 'application/json';
      return request;
    });

    // ========== 响应拦截器：统一错误处理 ==========
    _connect.httpClient.addResponseModifier((request, response) {
      // 非 2xx 状态码统一处理
      if (response.statusCode != null && response.statusCode! >= 400) {
        _handleHttpError(response.statusCode!, response.statusText);
      }
      return response;
    });
  }

  /// 获取本地存储的 token
  String _getToken() {
    final box = GetStorage();
    return box.read<String>(_tokenStorageKey) ?? '';
  }

  /// 保存 token 到本地
  void saveToken(String token) {
    final box = GetStorage();
    box.write(_tokenStorageKey, token);
  }

  /// 清除本地 token
  void clearToken() {
    final box = GetStorage();
    box.remove(_tokenStorageKey);
  }

  /// 统一 POST 请求
  /// [path] 接口路径，如 /auth/login
  /// [body] 请求体（会序列化为 JSON）
  /// [fromJsonT] 可选：将 data 字段转换为指定类型
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _connect.post(
        path,
        body != null ? jsonEncode(body) : null,
        contentType: 'application/json',
        decoder: (data) => data, // 取原始 JSON 自行解析
      );

      return _parseResponse<T>(response, fromJsonT);
    } on TimeoutException {
      return const ApiResponse(code: -1, message: '请求超时，请检查网络连接');
    } on SocketException {
      return const ApiResponse(code: -1, message: '网络连接失败，请检查网络');
    } catch (e) {
      return ApiResponse(code: -1, message: '请求异常：${e.toString()}');
    }
  }

  /// 统一 PATCH 请求
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _connect.patch(
        path,
        body != null ? jsonEncode(body) : null,
        contentType: 'application/json',
        decoder: (data) => data,
      );

      return _parseResponse<T>(response, fromJsonT);
    } on TimeoutException {
      return const ApiResponse(code: -1, message: '请求超时，请检查网络连接');
    } on SocketException {
      return const ApiResponse(code: -1, message: '网络连接失败，请检查网络');
    } catch (e) {
      return ApiResponse(code: -1, message: '请求异常：${e.toString()}');
    }
  }

  /// 统一 GET 请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _connect.get(
        path,
        query: query,
        decoder: (data) => data,
      );

      return _parseResponse<T>(response, fromJsonT);
    } on TimeoutException {
      return const ApiResponse(code: -1, message: '请求超时，请检查网络连接');
    } on SocketException {
      return const ApiResponse(code: -1, message: '网络连接失败，请检查网络');
    } catch (e) {
      return ApiResponse(code: -1, message: '请求异常：${e.toString()}');
    }
  }

  /// 解析 GetConnect 的 Response 为 ApiResponse
  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic json)? fromJsonT,
  ) {
    // 状态码非 200 系列
    if (response.statusCode != null && response.statusCode! >= 400) {
      return ApiResponse(
        code: response.statusCode!,
        message: response.statusText ?? '请求失败',
      );
    }

    // 返回体为空
    if (response.body == null) {
      return const ApiResponse(code: -1, message: '服务器返回为空');
    }

    // body 可能是 String 或 Map
    Map<String, dynamic> json;
    if (response.body is String) {
      try {
        json = jsonDecode(response.body as String) as Map<String, dynamic>;
      } catch (e) {
        return ApiResponse(code: -1, message: '响应解析失败：$e');
      }
    } else if (response.body is Map) {
      json = response.body as Map<String, dynamic>;
    } else {
      return const ApiResponse(code: -1, message: '未知的响应格式');
    }

    return ApiResponse.fromJson(json, fromJsonT);
  }

  /// HTTP 错误处理
  void _handleHttpError(int statusCode, String? statusText) {
    switch (statusCode) {
      case 401:
        // token 过期或未授权，清除本地 token
        clearToken();
        break;
      case 403:
        break;
      case 500:
        break;
    }
  }
}
