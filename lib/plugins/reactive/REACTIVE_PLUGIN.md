# Reactive Plugin — 实现思路文档

> 路径：`lib/plugins/reactive/`  
> 版本：1.1.0  
> 定位：一个**自研的、轻量级、类 GetX 风格**的响应式状态管理 + 依赖注入系统，零外部依赖，仅用 Flutter SDK 原生能力实现。

---

## 目录

1. [设计目标](#1-设计目标)  
2. [整体架构](#2-整体架构)  
3. [核心模块详解](#3-核心模块详解)  
   - 3.1 [Rx — 响应式变量层](#31-rx--响应式变量层)  
   - 3.2 [RxController — 控制器基类](#32-rxcontroller--控制器基类)  
   - 3.3 [ReactiveInjector — 依赖注入容器](#33-reactiveinjector--依赖注入容器)  
   - 3.4 [Widget 层](#34-widget-层)  
4. [数据流向图](#4-数据流向图)  
5. [生命周期管理](#5-生命周期管理)  
6. [与 GetX 的对比](#6-与-getx-的对比)  
7. [使用指南](#7-使用指南)  
8. [设计权衡 & 已知局限](#8-设计权衡--已知局限)  

---

## 1. 设计目标

| 目标 | 说明 |
|------|------|
| **零外部依赖** | 只用 `flutter/foundation.dart`，不依赖 `get`、`provider`、`riverpod` 等 |
| **与 GetX API 形似** | 学习成本低，团队已有 GetX 经验可快速迁移 |
| **精确重建** | Widget 只在其关心的变量变化时重建，不浪费帧 |
| **生命周期安全** | 控制器随页面自动创建/销毁，防止内存泄漏 |
| **可调试** | 注入容器状态透明，可通过 `findOrNull` 判断注入状态 |

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                     应用层（App）                        │
│  ┌──────────────┐   ┌──────────────┐  ┌──────────────┐  │
│  │  RxPage      │   │  GetView<T>  │  │  RxConsumer  │  │
│  │  (生命周期)  │   │  (全量监听)  │  │  (精确监听)  │  │
│  └──────┬───────┘   └──────┬───────┘  └──────┬───────┘  │
│         │                  │                  │          │
│  ┌──────▼───────────────────▼──────────────────▼──────┐  │
│  │               Widget 层 (rx_widgets.dart)          │  │
│  │  RxBuilder  /  RxMultiConsumer  /  RxConsumer      │  │
│  └──────────────────────────┬──────────────────────────┘  │
│                             │                             │
│  ┌──────────────────────────▼──────────────────────────┐  │
│  │           ReactiveInjector (单例容器)                │  │
│  │   putController / put / putSingleton / find / delete │  │
│  └──────────────────────────┬──────────────────────────┘  │
│                             │                             │
│  ┌──────────────────────────▼──────────────────────────┐  │
│  │     控制器层 (RxController extends ChangeNotifier)   │  │
│  │   CounterController / LoggerService / ...            │  │
│  └──────────────────────────┬──────────────────────────┘  │
│                             │                             │
│  ┌──────────────────────────▼──────────────────────────┐  │
│  │       响应式变量层 (Rx<T> extends ChangeNotifier)    │  │
│  │   Rx<int>  /  RxList<String>  /  RxMap<K,V>         │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

整个系统分为 **4 层**：
- **响应式变量层**：持有数据，变化时发布通知  
- **控制器层**：聚合多个 Rx 变量，提供业务方法  
- **注入容器层**：管理所有控制器/服务的注册与查找  
- **Widget 层**：订阅响应式对象，变化时精确重建  

---

## 3. 核心模块详解

### 3.1 `Rx<T>` — 响应式变量层

**文件**：`rx.dart`

#### 核心实现

```dart
class Rx<T> extends ChangeNotifier {
  T _value;
  Rx(this._value);

  T get value => _value;

  set value(T newValue) {
    if (_value != newValue) {   // ← 值相等时跳过，避免冗余通知
      _value = newValue;
      notifyListeners();         // ← 继承自 ChangeNotifier
    }
  }
}
```

**关键设计**：

- 继承 `ChangeNotifier` 而非实现 `ValueNotifier`，原因是 `ChangeNotifier` 更通用，后续 `RxList` / `RxMap` 继承后可自定义触发时机。
- `set value` 加了相等判断（`if (_value != newValue)`），避免同值赋值触发无意义重建。
- `RxList<T>` 通过每次写入时创建新 `List` 实例（`[...value, item]`）保证不可变语义，使 `!=` 判断总是 `true`，从而正确触发通知。

#### 衍生类型

| 类型 | 说明 |
|------|------|
| `RxList<T>` | 每次 `add/remove/clear` 都创建新 List，触发通知 |
| `RxMap<K,V>` | 每次 `put/remove` 都创建新 Map，触发通知 |

> **为何不直接用 `ValueNotifier<T>`？**  
> `ValueNotifier` 自带相等比较，对 `List`/`Map` 这类引用类型比较的是引用而非内容。`RxList` 每次都创建新实例，所以用 `ChangeNotifier` 手动控制通知时机反而更清晰可控。

---

### 3.2 `RxController` — 控制器基类

**文件**：`rx_controller.dart`

```dart
abstract class RxController extends ChangeNotifier {
  bool _disposed = false;

  void onClose() { ... }  // 页面销毁钩子，可 override
  void update()  { notifyListeners(); }  // 手动触发全量更新
  bool get isDisposed => _disposed;
}
```

**设计要点**：

1. **继承 `ChangeNotifier`**：控制器本身就是一个 `Listenable`，`GetView<T>` 可以直接用 `AnimatedBuilder(animation: controller, ...)` 监听整个控制器的 `update()` 调用。

2. **`_disposed` 守卫**：防止控制器被销毁后仍然调用 `notifyListeners`（FlutterError 常见来源）。

3. **`onClose` vs `dispose`**：  
   - `onClose()` 是业务钩子，供子类 override 做资源清理（如关流、取消订阅）  
   - `dispose()` 是 Flutter SDK 的 `ChangeNotifier` 底层方法，两者配合防止双重 dispose

---

### 3.3 `ReactiveInjector` — 依赖注入容器

**文件**：`reactive_injector.dart`

#### 存储结构

```
ReactiveInjector (Singleton)
├── _dependencies: HashMap<Type|_TaggedType, _ReactiveDependencyInfo>
│                  工厂函数、是否单例、是否控制器、是否永久
├── _singletons:   HashMap<Type|_TaggedType, dynamic>
│                  已创建的实例缓存
└── _reactiveTypes: HashSet<dynamic>
                   标记哪些 key 是 RxController（用于 reset/delete 时批量 onClose）
```

#### 注册方式

| 方法 | 适用场景 |
|------|----------|
| `putController<T>(factory, permanent:)` | 注册 `RxController` 子类，自动管理生命周期 |
| `put<T>(factory, singleton:)` | 注册普通依赖（POJO / Service）|
| `putSingleton<T>(instance)` | 注册已创建好的实例 |

#### 获取方式

| 方法 | 行为 |
|------|------|
| `find<T>()` | 返回实例，不存在时 throw |
| `findOrNull<T>()` | 返回实例或 null，不 throw |

#### 键设计 — `_TaggedType`

同一类型可注册多个实例（用 `tag` 区分），内部用 `_TaggedType(Type, String)` 作为 HashMap 键：

```dart
dynamic _getKey<T>(String? tag) {
  if (tag == null) return T;           // ← 无 tag 直接用 Type 作键
  return _TaggedType(T, tag);          // ← 有 tag 包装成复合键
}
```

#### 全局单例

```dart
final reactiveInjector = ReactiveInjector();
```

整个 App 只有一个注入器实例，通过 Dart 的顶级变量懒初始化保证单例，无需 `static`。

---

### 3.4 Widget 层

**文件**：`rx_widgets.dart`

#### 四个 Widget 的定位与选择

```
需要监听 ──────────────────────────────────────────────► 选哪个？
        │
        ├── 单个 Rx<T>，粒度最细 ───────────────────► RxConsumer<T>
        │
        ├── 多个 Rx<T>，手动列表，控制灵活 ─────────► RxBuilder(listenables: [...])
        │
        ├── 多个 Rx<T>，语义明确 ────────────────────► RxMultiConsumer(rxList: [...])
        │
        └── 整个 Controller（含 update() 调用）─────► GetView<T>
```

#### `RxConsumer<T>` — 精确监听

```dart
AnimatedBuilder(
  animation: rx,           // ← 直接传 Rx<T>（它是 Listenable）
  builder: (context, _) => builder(context, rx.value),
)
```

`AnimatedBuilder` 是 Flutter 官方提供的监听 `Listenable` + 重建子树的最小 Widget，无需自己管理 `addListener/removeListener`，代码最简洁。

#### `RxBuilder` — 多变量监听

```dart
// 核心：用 Listenable.merge 把多个 Listenable 合并成一个
_merged = Listenable.merge(widget.listenables);
_merged!.addListener(_rebuild);
```

`Listenable.merge` 是 Flutter SDK 内置方法，任意一个源触发时整体触发，无需轮询。

#### `RxMultiConsumer` — 多变量语义版

与 `RxBuilder` 内部实现相同，区别在于 API 语义更明确（`rxList` 而非 `listenables`）。

#### `GetView<T>` — 全量控制器监听

```dart
AnimatedBuilder(
  animation: controller,   // ← controller 本身是 ChangeNotifier
  builder: (context, _) => builder(context, controller),
)
```

当控制器调用 `update()` → `notifyListeners()` 时，整个 `GetView` 重建。适合控制器字段较少、或需要整体刷新的场景。

#### `RxPage` — 生命周期绑定

```
initState → 执行 bindings → find 或新建控制器 → putSingleton 到注入器
   │
   ▼
build → 渲染子 Widget
   │
   ▼
dispose → 遍历 _pageControllers → onClose() → 从注入器注销
```

`RxPage` 是唯一"主动管理"生命周期的 Widget，其他 Widget 只负责监听/渲染。

---

## 4. 数据流向图

```
用户操作
   │
   ▼
CounterController.increment()
   │
   ├── count.value++          → Rx<int>.notifyListeners()
   │                              │
   │                              └──► RxConsumer(rx: count) 重建
   │
   ├── message.value = '...'  → Rx<String>.notifyListeners()
   │                              │
   │                              └──► RxConsumer(rx: message) 重建
   │
   ├── history.add('...')     → RxList<String>.notifyListeners()
   │                              │
   │                              └──► RxConsumer(rx: history) 重建
   │
   └── （可选）update()       → RxController.notifyListeners()
                                   │
                                   └──► GetView<CounterController> 全量重建
```

**精确重建原则**：每个 `Rx<T>` 变量是独立的 `ChangeNotifier`，修改 `count` 只触发监听 `count` 的 Widget，不影响监听 `message` 的 Widget。

---

## 5. 生命周期管理

```
路由 push /reactive-demo
       │
       ▼
ReactiveDemoPage.build()
  ├── _setupDependencies()       ← 注册控制器工厂到注入器
  └── RxPage
        │
        ▼ initState
        ├── inj.find<CounterController>()  ← 触发工厂，创建实例
        └── inj.putSingleton(controller)   ← 存入 _singletons

用户操作 / 数据变化...

路由 pop（返回）
       │
       ▼
RxPage._RxPageState.dispose()
  └── controller.onClose()
        └── ChangeNotifier.dispose()  ← 通知所有 listener 取消监听
              │
              ▼
        inj._singletons 中的实例被移除（putSingleton 不自动清理，
        需配合 delete<T> 或由 RxPage 手动 onClose）
```

> **注意**：`LoggerService` 注册时传 `permanent: true`，`RxPage` 的 bindings 只绑定了 `CounterController`，所以 `LoggerService` 的生命周期由 App 全局管理，不随页面销毁。

---

## 6. 与 GetX 的对比

| 特性 | GetX | Reactive Plugin |
|------|------|-----------------|
| 依赖 | `get` 包（~3MB） | 零外部依赖 |
| `Rx<T>` | `Rx<T>`、`.obs` 扩展 | `Rx<T>`（类似，无 `.obs` 语法糖） |
| 控制器 | `GetxController` | `RxController` |
| 自动追踪 | `Obx(() => ...)` 自动收集 | 需手动指定 `listenables`（`RxBuilder`）或用 `RxConsumer` 精确绑定 |
| 路由集成 | `GetMaterialApp` + 命名路由 | 独立，与任何路由系统兼容 |
| 依赖注入 | `Get.put / Get.find` | `reactiveInjector.put / find` |
| 生命周期钩子 | `onInit / onReady / onClose` | `onClose`（可扩展） |
| 学习成本 | 中（需理解 GetX 全家桶） | 低（纯 Flutter 概念） |
| 调试友好 | DevTools 扩展较少 | 直接用 Flutter DevTools |

**最大差异**：GetX 的 `Obx` 通过运行时"收集"在 builder 中被访问的 `Rx` 变量实现自动追踪，无需手动传 `listenables`。本插件选择"手动声明"策略，在牺牲一点便利性的同时，订阅关系在代码中显式可见，更易审查。

---

## 7. 使用指南

### 7.1 快速开始

```dart
import 'package:komodo/plugins/reactive/reactive_plugin.dart';

// 1. 定义控制器
class MyController extends RxController {
  final Rx<int> count = Rx<int>(0);
  void increment() => count.value++;
}

// 2. 注册（通常在页面入口）
reactiveInjector.putController((inj) => MyController());

// 3. 在 Widget 中使用（方式一：精确监听）
RxConsumer(
  rx: controller.count,
  builder: (ctx, value) => Text('$value'),
)

// 方式二：多变量
RxBuilder(
  listenables: [controller.count, controller.name],
  builder: (ctx) => Text('${controller.count.value}'),
)

// 方式三：从注入器取控制器
GetView<MyController>(
  builder: (ctx, ctrl) => Text('${ctrl.count.value}'),
)
```

### 7.2 页面生命周期绑定

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    reactiveInjector.putController((inj) => MyController());
    return RxPage(
      bindings: [(inj) => inj.find<MyController>()],
      builder: (ctx) => const _MyView(),
    );
  }
}
```

### 7.3 全局永久服务

```dart
// 在 main 或 App 初始化时调用一次
void setupServices() {
  reactiveInjector.putController(
    (inj) => AuthService(),
    permanent: true,   // 不随 RxPage 销毁
  );
}
```

### 7.4 标签区分同类型多实例

```dart
reactiveInjector.putController(
  (inj) => FormController(),
  tag: 'login',
);
reactiveInjector.putController(
  (inj) => FormController(),
  tag: 'register',
);

// 获取
final loginCtrl  = reactiveInjector.find<FormController>(tag: 'login');
final regCtrl    = reactiveInjector.find<FormController>(tag: 'register');
```

---

## 8. 设计权衡 & 已知局限

### 已知局限

| 局限 | 说明 | 可能的解法 |
|------|------|-----------|
| 无自动追踪 | `RxBuilder` 需手动传 `listenables`，容易遗漏 | 使用 `Zone` + `runZoned` 记录访问路径（复杂度高） |
| `RxList` 每次创建新 List | 大列表频繁操作时 GC 压力较大 | 改为 `ObservableList`（维护内部 list，手动 notify）|
| 无中间件 / 拦截器 | 不支持 `ever`、`once`、`debounce` 等 GetX 工具 | 可扩展 `RxController` 添加 worker 机制 |
| 注入器无作用域 | 全局单一容器，无法按路由分层 | 支持 `ReactiveInjector(scope: ...)` 多实例 |
| `putController` 重复注册 | 重复调用会覆盖旧工厂但不自动销毁旧实例 | 注册前调用 `findOrNull` 判断（Demo 中已处理） |

### 设计权衡

- **`ChangeNotifier` vs `Stream`**：`ChangeNotifier` 同步通知，与 Flutter build 流程契合；`Stream` 支持异步、背压，但集成到 Widget 需要 `StreamBuilder`，开销更大。
- **手动声明 vs 自动追踪**：自动追踪（如 GetX `Obx`）对开发者更友好，但在 Widget dispose 时存在"遗漏取消订阅"的风险；手动声明在代码审查时订阅关系一目了然。

---

## 文件速览

```
lib/plugins/reactive/
├── rx.dart                 # Rx<T> / RxList / RxMap — 响应式变量
├── rx_controller.dart      # RxController 基类
├── reactive_injector.dart  # ReactiveInjector 容器 + reactiveInjector 全局实例
├── rx_widgets.dart         # RxConsumer / RxBuilder / RxMultiConsumer / GetView / RxPage
├── reactive_plugin.dart    # barrel export（一行 import 全部引入）
└── REACTIVE_PLUGIN.md      # 本文档
```
