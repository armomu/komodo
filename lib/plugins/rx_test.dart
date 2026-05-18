import 'package:flutter/material.dart';
import 'dart:collection';

/// 响应式变量包装器
class Rx<T> extends ChangeNotifier {
  T _value;

  Rx(this._value);

  T get value => _value;

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners(); // 通知所有监听者
    }
  }

  void update(T Function(T) updater) {
    value = updater(_value);
  }

  @override
  String toString() => 'Rx($value)';
}

/// 响应式列表
class RxList<T> extends Rx<List<T>> {
  RxList(super.initial);

  void add(T item) {
    value = [...value, item];
  }

  void addAll(Iterable<T> items) {
    value = [...value, ...items];
  }

  void remove(T item) {
    value = value.where((i) => i != item).toList();
  }

  void clear() {
    value = [];
  }
}

/// 响应式 Map
class RxMap<K, V> extends Rx<Map<K, V>> {
  RxMap(super.initial);

  void put(K key, V value) {
    final newMap = Map<K, V>.from(this.value);
    newMap[key] = value;
    this.value = newMap;
  }

  void remove(K key) {
    final newMap = Map<K, V>.from(value);
    newMap.remove(key);
    value = newMap;
  }
}

/// 响应式控制器基类（类似 GetxController）
abstract class RxController extends ChangeNotifier {
  bool _disposed = false;

  /// 标记为已销毁
  void onClose() {
    if (!_disposed) {
      _disposed = true;
      dispose();
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      super.dispose();
    }
  }

  /// 手动触发更新
  void update() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// 检查是否已销毁
  bool get isDisposed => _disposed;
}

/// 增强版依赖注入容器（支持响应式）
class ReactiveInjector {
  static final ReactiveInjector _instance = ReactiveInjector._internal();
  factory ReactiveInjector() => _instance;
  ReactiveInjector._internal();

  // 存储依赖
  final HashMap<Type, _ReactiveDependencyInfo> _dependencies = HashMap();

  // 存储单例实例（包括控制器）
  final HashMap<Type, dynamic> _singletons = HashMap();

  // 存储响应式变量（特殊标记）
  final HashSet<Type> _reactiveTypes = HashSet();

  /// 注册控制器（自动管理生命周期）
  void putController<T extends RxController>(
    T Function(ReactiveInjector injector) factory, {
    String? tag,
    bool permanent = false, // 是否永久保留（不随页面销毁）
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

  /// 注册普通依赖
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

  /// 获取依赖
  T find<T>({String? tag}) {
    final key = _getKey<T>(tag);

    // 检查缓存
    if (_singletons.containsKey(key)) {
      return _singletons[key] as T;
    }

    // 检查注册信息
    if (!_dependencies.containsKey(key)) {
      throw StateError("依赖未注册: ${T.toString()}, tag: $tag");
    }

    final depInfo = _dependencies[key]!;
    final instance = depInfo.factory(this) as T;

    if (depInfo.isSingleton) {
      _singletons[key] = instance;
    }

    return instance;
  }

  /// 尝试获取依赖，如果不存在返回 null
  T? findOrNull<T>({String? tag}) {
    try {
      return find<T>(tag: tag);
    } catch (_) {
      return null;
    }
  }

  /// 删除依赖（用于测试或重置）
  void delete<T>({String? tag}) {
    final key = _getKey<T>(tag);
    final instance = _singletons[key];

    // 如果是控制器，调用 onClose
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

  /// 生成唯一键
  dynamic _getKey<T>(String? tag) {
    if (tag == null) return T;
    return _TaggedType(T, tag);
  }
}

/// 增强版依赖信息
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

final reactiveInjector = ReactiveInjector();

/// 响应式组件（类似 Obx）
class RxBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;

  const RxBuilder({super.key, required this.builder});

  @override
  // ignore: library_private_types_in_public_api
  _RxBuilderState createState() => _RxBuilderState();
}

class _RxBuilderState extends State<RxBuilder> {
  final Set<ChangeNotifier> _subscriptions = {};

  @override
  void initState() {
    super.initState();
    _setupReactiveListener();
  }

  void _setupReactiveListener() {
    // 监听所有当前活跃的响应式对象
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 收集所有被使用的 Rx 变量和控制器
      _updateSubscriptions();
    });
  }

  void _updateSubscriptions() {
    // 实际的订阅逻辑需要配合 Controller 的标记机制
    // 这里简化为监听当前 build 上下文中使用的响应式对象
  }

  void _onNotifierChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.removeListener(_onNotifierChanged);
    }
    _subscriptions.clear();
    super.dispose();
  }
}

/// 获取控制器并自动管理生命周期
class GetView<T extends RxController> extends StatelessWidget {
  final Widget Function(BuildContext context, T controller) builder;
  final String? tag;

  const GetView({super.key, required this.builder, this.tag});

  @override
  Widget build(BuildContext context) {
    final controller = reactiveInjector.find<T>(tag: tag);
    return RxBuilder(builder: (context) => builder(context, controller));
  }
}

/// 响应式值监听器
class RxConsumer<T> extends StatelessWidget {
  final Rx<T> rx;
  final Widget Function(BuildContext context, T value) builder;

  const RxConsumer({super.key, required this.rx, required this.builder});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rx,
      builder: (context, _) => builder(context, rx.value),
    );
  }
}

/// 绑定页面（自动管理控制器生命周期）
class RxPage extends StatefulWidget {
  final String Function()? pageId;
  final List<RxController Function(ReactiveInjector)> bindings;
  final WidgetBuilder builder;

  const RxPage({
    super.key,
    this.pageId,
    required this.bindings,
    required this.builder,
  });

  @override
  // ignore: library_private_types_in_public_api
  _RxPageState createState() => _RxPageState();
}

class _RxPageState extends State<RxPage> {
  final List<RxController> _pageControllers = [];

  @override
  void initState() {
    super.initState();
    _initBindings();
  }

  void _initBindings() {
    for (final binding in widget.bindings) {
      final controller = binding(reactiveInjector);
      _pageControllers.add(controller);
      reactiveInjector.putSingleton(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void dispose() {
    // 页面销毁时自动清理控制器
    for (final controller in _pageControllers) {
      if (!controller.isDisposed) {
        controller.onClose();
      }
    }
    _pageControllers.clear();
    super.dispose();
  }
}
