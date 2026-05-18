import 'package:flutter/material.dart';
import 'rx.dart';
import 'rx_controller.dart';
import 'reactive_injector.dart';

/// 响应式构建器（类似 GetX 的 Obx）
/// 用法：RxBuilder(builder: (context) => Text(controller.xxx.value))
/// 注：当前实现依赖 AnimatedBuilder / ValueListenableBuilder 手动绑定；
/// 如需自动追踪请配合 RxConsumer 使用。
class RxBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;

  const RxBuilder({super.key, required this.builder});

  @override
  // ignore: library_private_types_in_public_api
  _RxBuilderState createState() => _RxBuilderState();
}

class _RxBuilderState extends State<RxBuilder> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

/// 精确监听单个 Rx 变量的 Widget（推荐使用）
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

/// 从注入器取控制器并自动刷新子树（类似 GetView）
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

/// 页面级生命周期绑定 Widget（类似 GetX 的 Binding）
/// 在页面 mount 时初始化绑定的控制器，unmount 时自动销毁
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
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

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
