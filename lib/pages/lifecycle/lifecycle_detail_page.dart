import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 生命周期详情页面
class LifecycleDetailPage extends StatelessWidget {
  const LifecycleDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生命周期详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(result: '从详情页返回'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildLifecycleList(),
            const SizedBox(height: 24),
            _buildGetXFeatures(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.loop, size: 64, color: Get.theme.colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Flutter 生命周期',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'StatefulWidget 的生命周期方法详解',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleList() {
    final lifecycleMethods = [
      {
        'name': 'createState()',
        'description': '创建 State 对象，每个 StatefulWidget 都会调用',
        'color': Colors.blue,
      },
      {'name': '构造函数', 'description': 'State 对象被创建时调用', 'color': Colors.indigo},
      {
        'name': 'initState()',
        'description': 'State 对象插入到渲染树中，只调用一次',
        'color': Colors.green,
      },
      {
        'name': 'didChangeDependencies()',
        'description': 'State 对象的依赖发生变化时调用',
        'color': Colors.cyan,
      },
      {'name': 'build()', 'description': '构建 UI，可多次调用', 'color': Colors.blue},
      {
        'name': 'didUpdateWidget()',
        'description': 'Widget 配置发生变化时调用',
        'color': Colors.purple,
      },
      {
        'name': 'deactivate()',
        'description': 'State 对象从渲染树中移除时调用',
        'color': Colors.orange,
      },
      {
        'name': 'dispose()',
        'description': 'State 对象被永久销毁时调用',
        'color': Colors.red,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '生命周期方法',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...lifecycleMethods.map((method) => _buildMethodCard(method)),
      ],
    );
  }

  Widget _buildMethodCard(Map<String, dynamic> method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (method['color'] as Color).withValues(alpha: 0.2),
          child: Icon(Icons.code, color: method['color'] as Color, size: 20),
        ),
        title: Text(
          method['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(method['description'] as String),
      ),
    );
  }

  Widget _buildGetXFeatures() {
    return Card(
      color: Get.theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, color: Get.theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'GetX 特性',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FeatureItem(
              icon: Icons.route,
              title: '路由管理',
              description: '无需 BuildContext 的导航，支持中间件',
            ),
            const _FeatureItem(
              icon: Icons.palette,
              title: '主题管理',
              description: '动态切换主题，支持深色模式',
            ),
            const _FeatureItem(
              icon: Icons.storage,
              title: '状态管理',
              description: '响应式编程，简单易用',
            ),
            const _FeatureItem(
              icon: Icons.grade,
              title: '依赖注入',
              description: '自动管理 Controller 生命周期',
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
