import 'dart:collection';
import 'rx_controller.dart';

/// 增强版依赖注入容器（支持响应式控制器生命周期管理）
class ReactiveInjector {
  static final ReactiveInjector _instance = ReactiveInjector._internal();

  factory ReactiveInjector() => _instance;

  ReactiveInjector._internal();

  final HashMap<dynamic, _ReactiveDependencyInfo> _dependencies = HashMap();
  final HashMap<dynamic, dynamic> _singletons = HashMap();
  final HashSet<dynamic> _reactiveTypes = HashSet();

  /// 注册控制器（自动管理生命周期）
  void putController<T extends RxController>(
    T Function(ReactiveInjector injector) factory, {
    String? tag,
    bool permanent = false,
  }) {
    final key = _getKey<T>(tag);
    _dependencies[key] = _ReactiveDependencyInfo(
      factory: (inj) => factory(inj),
      isSingleton: true,
      isController: true,
      permanent: permanent,
    );
    _reactiveTypes.add(key);
  }

  /// 注册普通依赖（工厂 / 单例均可）
  void put<T>(
    T Function(ReactiveInjector injector) factory, {
    String? tag,
    bool singleton = true,
  }) {
    final key = _getKey<T>(tag);
    _dependencies[key] = _ReactiveDependencyInfo(
      factory: (inj) => factory(inj),
      isSingleton: singleton,
      isController: false,
    );
  }

  /// 注册已创建的实例
  void putSingleton<T>(T instance, {String? tag}) {
    final key = _getKey<T>(tag);
    _singletons[key] = instance;

    if (instance is RxController) {
      _reactiveTypes.add(key);
      _dependencies[key] = _ReactiveDependencyInfo(
        factory: (_) => instance,
        isSingleton: true,
        isController: true,
        permanent: false,
      );
    }
  }

  /// 获取依赖实例
  T find<T>({String? tag}) {
    final key = _getKey<T>(tag);
    if (_singletons.containsKey(key)) {
      return _singletons[key] as T;
    }
    if (!_dependencies.containsKey(key)) {
      throw StateError('依赖未注册: ${T.toString()}, tag: $tag');
    }
    final depInfo = _dependencies[key]!;
    final instance = depInfo.factory(this) as T;
    if (depInfo.isSingleton) {
      _singletons[key] = instance;
    }
    return instance;
  }

  /// 尝试获取，不存在则返回 null
  T? findOrNull<T>({String? tag}) {
    try {
      return find<T>(tag: tag);
    } catch (_) {
      return null;
    }
  }

  /// 删除并销毁某个依赖
  void delete<T>({String? tag}) {
    final key = _getKey<T>(tag);
    final instance = _singletons[key];
    if (instance is RxController && !instance.isDisposed) {
      instance.onClose();
    }
    _dependencies.remove(key);
    _singletons.remove(key);
    _reactiveTypes.remove(key);
  }

  /// 重置所有依赖（慎用，主要用于测试）
  void reset() {
    for (final key in _reactiveTypes.toList()) {
      final instance = _singletons[key];
      if (instance is RxController && !instance.isDisposed) {
        instance.onClose();
      }
    }
    _dependencies.clear();
    _singletons.clear();
    _reactiveTypes.clear();
  }

  dynamic _getKey<T>(String? tag) {
    if (tag == null) return T;
    return _TaggedType(T, tag);
  }
}

class _ReactiveDependencyInfo {
  final dynamic Function(ReactiveInjector injector) factory;
  final bool isSingleton;
  final bool isController;
  final bool permanent;

  _ReactiveDependencyInfo({
    required this.factory,
    required this.isSingleton,
    this.isController = false,
    this.permanent = false,
  });
}

class _TaggedType {
  final Type type;
  final String tag;

  const _TaggedType(this.type, this.tag);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TaggedType && other.type == type && other.tag == tag;
  }

  @override
  int get hashCode => type.hashCode ^ tag.hashCode;
}

/// 全局单例注入器
final reactiveInjector = ReactiveInjector();
