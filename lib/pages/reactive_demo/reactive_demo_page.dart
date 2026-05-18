import 'package:flutter/material.dart';
import 'package:komodo/plugins/reactive/reactive_plugin.dart';
import 'controllers/counter_controller.dart';
import 'services/logger_service.dart';

// ─────────────────────────────────────────────────────────────────
// 依赖注册（幂等）
// ─────────────────────────────────────────────────────────────────
void _setupDependencies() {
  if (reactiveInjector.findOrNull<LoggerService>() == null) {
    reactiveInjector.putController((inj) => LoggerService(), permanent: true);
  }
  // 每次进入页面时重新注册（RxPage 会在离开时销毁旧实例）
  reactiveInjector.putController((inj) => CounterController());
}

// ─────────────────────────────────────────────────────────────────
// 入口页面：由 RxPage 管理控制器生命周期
// ─────────────────────────────────────────────────────────────────
class ReactiveDemoPage extends StatelessWidget {
  const ReactiveDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    _setupDependencies();
    return RxPage(
      bindings: [(inj) => inj.find<CounterController>()],
      builder: (context) => const _DemoTabView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 多 Tab 容器
// ─────────────────────────────────────────────────────────────────
class _DemoTabView extends StatefulWidget {
  const _DemoTabView();

  @override
  State<_DemoTabView> createState() => _DemoTabViewState();
}

class _DemoTabViewState extends State<_DemoTabView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _TabMeta(label: 'RxConsumer', icon: Icons.flash_on_outlined),
    _TabMeta(label: 'RxBuilder', icon: Icons.tune_outlined),
    _TabMeta(label: 'GetView', icon: Icons.view_in_ar_outlined),
    _TabMeta(label: 'Multi', icon: Icons.merge_type_outlined),
    _TabMeta(label: 'Injector', icon: Icons.hub_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('响应式 DI Demo'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: _tabs
              .map(
                (t) => Tab(
                  icon: Icon(t.icon, size: 18),
                  text: t.label,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RxConsumerTab(),
          _RxBuilderTab(),
          _GetViewTab(),
          _RxMultiConsumerTab(),
          _InjectorTab(),
        ],
      ),
    );
  }
}

class _TabMeta {
  final String label;
  final IconData icon;
  const _TabMeta({required this.label, required this.icon});
}

// ═══════════════════════════════════════════════════════════════
// Tab 1 — RxConsumer：精确监听单个 Rx<T>
// ═══════════════════════════════════════════════════════════════
class _RxConsumerTab extends StatelessWidget {
  const _RxConsumerTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = reactiveInjector.find<CounterController>();
    final cs = Theme.of(context).colorScheme;

    return _TabScaffold(
      apiTag: 'RxConsumer<T>',
      description:
          '精确监听单个 Rx<T> 变量。底层用 AnimatedBuilder，'
          '仅在该变量变化时重建自身，粒度最细、性能最优。',
      codeSnippet: '''RxConsumer(
  rx: controller.count,
  builder: (ctx, value) => Text('\$value'),
)''',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // count — 独立监听
          RxConsumer(
            rx: ctrl.count,
            builder: (_, v) => _BigNumber(value: '$v', color: cs.primary),
          ),
          const SizedBox(height: 8),
          // message — 独立监听（count 变化不影响此处重建）
          RxConsumer(
            rx: ctrl.message,
            builder: (_, v) =>
                Text(v, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          const SizedBox(height: 24),
          _CounterButtons(ctrl: ctrl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tab 2 — RxBuilder：监听多个 Rx，手动传入列表
// ═══════════════════════════════════════════════════════════════
class _RxBuilderTab extends StatelessWidget {
  const _RxBuilderTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = reactiveInjector.find<CounterController>();
    final cs = Theme.of(context).colorScheme;

    return _TabScaffold(
      apiTag: 'RxBuilder',
      description:
          '接收 listenables 列表，任意一个变化时重建整个 builder。'
          '适合需要同时读多个变量、但仍想精确控制订阅源的场景。',
      codeSnippet: '''RxBuilder(
  listenables: [ctrl.count, ctrl.message],
  builder: (ctx) => Text(
    '\${ctrl.count.value} — \${ctrl.message.value}',
  ),
)''',
      child: RxBuilder(
        listenables: [ctrl.count, ctrl.message],
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BigNumber(value: '${ctrl.count.value}', color: cs.tertiary),
            const SizedBox(height: 8),
            Text(
              ctrl.message.value,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '监听源：count + message',
                style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
              ),
            ),
            const SizedBox(height: 24),
            _CounterButtons(ctrl: ctrl),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tab 3 — GetView：从注入器取控制器并监听 update()
// ═══════════════════════════════════════════════════════════════
class _GetViewTab extends StatelessWidget {
  const _GetViewTab();

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      apiTag: 'GetView<T>',
      description:
          '自动从 reactiveInjector 查找控制器，监听控制器整体'
          '的 notifyListeners（即 update() 调用）。适合用在需要'
          '从注入器懒查的场景，无需在外部 find。',
      codeSnippet: '''GetView<CounterController>(
  builder: (ctx, ctrl) => Text('\${ctrl.count.value}'),
)''',
      child: GetView<CounterController>(
        builder: (ctx, ctrl) {
          final cs = Theme.of(ctx).colorScheme;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BigNumber(value: '${ctrl.count.value}', color: cs.secondary),
              const SizedBox(height: 8),
              Text(
                ctrl.message.value,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '监听整个 CounterController',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _CounterButtons(ctrl: ctrl),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tab 4 — RxMultiConsumer：组合多个 Rx 变量
// ═══════════════════════════════════════════════════════════════
class _RxMultiConsumerTab extends StatelessWidget {
  const _RxMultiConsumerTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = reactiveInjector.find<CounterController>();
    final cs = Theme.of(context).colorScheme;

    return _TabScaffold(
      apiTag: 'RxMultiConsumer',
      description:
          '同时监听多个 Rx 变量，任一变化即重建。'
          '与 RxBuilder 类似但语义更明确——专为"多变量组合"设计，'
          '不需要手动管理 listenables 字段名。',
      codeSnippet: '''RxMultiConsumer(
  rxList: [ctrl.count, ctrl.history],
  builder: (ctx) => Column(children: [
    Text('\${ctrl.count.value}'),
    Text('历史 \${ctrl.history.length} 条'),
  ]),
)''',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RxMultiConsumer(
            rxList: [ctrl.count, ctrl.history],
            builder: (ctx) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      label: '计数',
                      value: '${ctrl.count.value}',
                      color: cs.primary,
                    ),
                    const SizedBox(width: 16),
                    _StatChip(
                      label: '历史',
                      value: '${ctrl.history.length} 条',
                      color: cs.error,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ctrl.history.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 80),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: ctrl.history.length > 4
                          ? 4
                          : ctrl.history.length,
                      itemBuilder: (_, i) {
                        final idx = ctrl.history.length - 1 - i;
                        return Text(
                          ctrl.history[idx],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _CounterButtons(ctrl: ctrl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tab 5 — ReactiveInjector：依赖注入演示
// ═══════════════════════════════════════════════════════════════
class _InjectorTab extends StatefulWidget {
  const _InjectorTab();

  @override
  State<_InjectorTab> createState() => _InjectorTabState();
}

class _InjectorTabState extends State<_InjectorTab> {
  String _lastLog = '—';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = reactiveInjector.find<CounterController>();
    final logger = reactiveInjector.find<LoggerService>();

    return _TabScaffold(
      apiTag: 'ReactiveInjector',
      description:
          'Dart 版依赖注入容器，支持单例/工厂/控制器注册，'
          '并与 RxPage 配合实现页面级生命周期自动清理。'
          'LoggerService 是全局永久单例，CounterController 随页面销毁。',
      codeSnippet: '''// 注册
reactiveInjector.putController(
  (inj) => LoggerService(), permanent: true);

// 获取
final logger = reactiveInjector.find<LoggerService>();

// 删除（自动 onClose）
reactiveInjector.delete<CounterController>();''',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 注入器状态卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前注入状态',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InjectorRow(
                    label: 'CounterController',
                    status: '已注入（页面级）',
                    color: cs.primary,
                  ),
                  _InjectorRow(
                    label: 'LoggerService',
                    status: '已注入（永久）',
                    color: cs.secondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '最新日志：$_lastLog',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('计数 +1'),
                onPressed: () {
                  ctrl.increment();
                  setState(() {});
                },
              ),
              FilledButton.tonal(
                child: const Text('写入日志'),
                onPressed: () {
                  logger.log('计数 = ${ctrl.count.value}');
                  setState(() => _lastLog = logger.logs.value.last);
                },
              ),
              OutlinedButton(
                child: const Text('重置'),
                onPressed: () {
                  ctrl.reset();
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 共用组件
// ─────────────────────────────────────────────────────────────────

/// 通用 Tab 布局框架：顶部 API 说明 + 代码片段 + 演示区域
class _TabScaffold extends StatelessWidget {
  final String apiTag;
  final String description;
  final String codeSnippet;
  final Widget child;

  const _TabScaffold({
    required this.apiTag,
    required this.description,
    required this.codeSnippet,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // API 标签 + 说明
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(isDark ? 60 : 120),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    apiTag,
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(description, style: TextStyle(color: cs.onSurface)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 代码片段
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              codeSnippet,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFCDD6F4)
                    : const Color(0xFF1C1C1E),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 演示区域
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '▶ 实时演示',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 大数字展示组件
class _BigNumber extends StatelessWidget {
  final String value;
  final Color color;

  const _BigNumber({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1,
      ),
    );
  }
}

/// + / - / 重置 三个按钮
class _CounterButtons extends StatelessWidget {
  final CounterController ctrl;

  const _CounterButtons({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleBtn(icon: Icons.remove, color: cs.error, onTap: ctrl.decrement),
        const SizedBox(width: 20),
        _CircleBtn(icon: Icons.add, color: cs.primary, onTap: ctrl.increment),
        const SizedBox(width: 20),
        _CircleBtn(icon: Icons.refresh, color: cs.secondary, onTap: ctrl.reset),
      ],
    );
  }
}

/// 圆形按钮
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(25),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}

/// 统计数字 Chip
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withAlpha(180)),
          ),
        ],
      ),
    );
  }
}

/// Injector 状态行
class _InjectorRow extends StatelessWidget {
  final String label;
  final String status;
  final Color color;

  const _InjectorRow({
    required this.label,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(fontSize: 11, color: color)),
          ),
        ],
      ),
    );
  }
}
