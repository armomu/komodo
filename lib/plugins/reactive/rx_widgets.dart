import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'rx.dart';
import 'rx_controller.dart';
import 'reactive_injector.dart';

// ─────────────────────────────────────────────────────────────────
// RxBuilder — 监听一组 Listenable（Rx / RxController）的 Widget
// 类比 GetX 的 Obx，支持手动传入要监听的变量列表
// ─────────────────────────────────────────────────────────────────

/// 监听多个 [Listenable]（Rx / RxController），任何一个变化即重建
///
/// 用法（手动传入监听源）：
/// ```dart
/// RxBuilder(
///   listenables: [controller.count, controller.message],
///   builder: (context) => Text(
///     '${controller.count.value} - ${controller.message.value}',
///   ),
/// )
/// ```
///
/// 若不传 [listenables]，则退化为每帧重建（不推荐，仅作占位兜底）。
class RxBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;

  /// 需要监听的响应式变量列表（Rx<T> / RxController 均可）
  final List<Listenable>? listenables;

  const RxBuilder({super.key, required this.builder, this.listenables});

  @override
  // ignore: library_private_types_in_public_api
  _RxBuilderState createState() => _RxBuilderState();
}

class _RxBuilderState extends State<RxBuilder> {
  Listenable? _merged;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(RxBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.listenables, oldWidget.listenables)) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _subscribe() {
    final list = widget.listenables;
    if (list == null || list.isEmpty) return;
    _merged = list.length == 1 ? list.first : Listenable.merge(list);
    _merged!.addListener(_rebuild);
  }

  void _unsubscribe() {
    _merged?.removeListener(_rebuild);
    _merged = null;
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────
// RxConsumer — 精确监听单个 Rx<T>，性能最优（推荐用于叶节点）
// ─────────────────────────────────────────────────────────────────

/// 精确监听单个 [Rx<T>] 变量，值变化时仅重建自身
///
/// ```dart
/// RxConsumer(
///   rx: controller.count,
///   builder: (context, value) => Text('$value'),
/// )
/// ```
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

// ─────────────────────────────────────────────────────────────────
// GetView — 从注入器取控制器，监听整个控制器的 notifyListeners
// ─────────────────────────────────────────────────────────────────

/// 自动从 [reactiveInjector] 获取 [T] 控制器，并监听其全量更新
///
/// 适合需要在一个 builder 里读取控制器多个字段的场景。
/// 注：控制器调用 `update()` 时才整体重建，粒度比 [RxConsumer] 粗。
///
/// ```dart
/// GetView<CounterController>(
///   builder: (context, ctrl) => Text('${ctrl.count.value}'),
/// )
/// ```
class GetView<T extends RxController> extends StatelessWidget {
  final Widget Function(BuildContext context, T controller) builder;
  final String? tag;

  const GetView({super.key, required this.builder, this.tag});

  @override
  Widget build(BuildContext context) {
    final controller = reactiveInjector.find<T>(tag: tag);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => builder(context, controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// RxMultiConsumer — 监听多个 Rx，暴露所有最新值
// ─────────────────────────────────────────────────────────────────

/// 监听多个 [Rx] 变量，任一变化均重建
/// 适合需要组合多个响应式值但又不想引入整个 controller 的情形
///
/// ```dart
/// RxMultiConsumer(
///   rxList: [controller.count, controller.message],
///   builder: (context) => Text(
///     '${controller.count.value} / ${controller.message.value}',
///   ),
/// )
/// ```
class RxMultiConsumer extends StatefulWidget {
  final List<Listenable> rxList;
  final Widget Function(BuildContext context) builder;

  const RxMultiConsumer({
    super.key,
    required this.rxList,
    required this.builder,
  });

  @override
  // ignore: library_private_types_in_public_api
  _RxMultiConsumerState createState() => _RxMultiConsumerState();
}

class _RxMultiConsumerState extends State<RxMultiConsumer> {
  late Listenable _merged;

  @override
  void initState() {
    super.initState();
    _merged = Listenable.merge(widget.rxList);
    _merged.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);

  @override
  void dispose() {
    _merged.removeListener(_rebuild);
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────
// RxPage — 页面生命周期绑定，mount 时初始化控制器，unmount 时销毁
// ─────────────────────────────────────────────────────────────────

/// 页面级生命周期绑定
///
/// 在 Widget mount 时通过 [bindings] 初始化控制器并注入到 [reactiveInjector]；
/// Widget dispose 时自动调用每个控制器的 [RxController.onClose]。
///
/// ```dart
/// RxPage(
///   bindings: [(inj) => inj.find<CounterController>()],
///   builder: (context) => const _MyView(),
/// )
/// ```
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
    for (final binding in widget.bindings) {
      final controller = binding(reactiveInjector);
      _pageControllers.add(controller);
      reactiveInjector.putSingleton(controller);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);

  @override
  void dispose() {
    for (final controller in _pageControllers) {
      if (!controller.isDisposed) {
        controller.onClose();
      }
    }
    _pageControllers.clear();
    super.dispose();
  }
}
