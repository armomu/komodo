import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 路由中间件
/// 当前不自动重定向，允许用户自由浏览。
/// 登录入口由各页面自行控制（如点击头像跳转到 /login）。
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // 不自动拦截，用户在需要时主动触发登录
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    debugPrint('🚀 页面被调用: ${page?.name}');
    return page;
  }

  @override
  List<Bindings>? onBindingsStart(List<Bindings>? bindings) {
    debugPrint('🔗 绑定开始: ${bindings?.length}');
    return bindings;
  }

  @override
  Widget onPageBuilt(Widget page) {
    debugPrint('🏗️ 页面构建完成');
    return page;
  }

  @override
  void onPageDispose() {
    debugPrint('🗑️ 页面已销毁');
  }
}

/// 日志中间件 - 记录路由跳转
class LoggingMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    debugPrint('📍 路由跳转: $route');
    return null;
  }
}
