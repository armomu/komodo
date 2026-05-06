import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// ========================================
/// 反馈组件 - Material 3 Feedback
/// ========================================
class FeedbackSection extends StatelessWidget {
  const FeedbackSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('反馈组件'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _SnackBarDemo(),
            SizedBox(height: 24),
            _BannerDemo(),
            SizedBox(height: 24),
            _TooltipDemo(),
            SizedBox(height: 24),
            _InkWellDemo(),
            SizedBox(height: 24),
            _BadgeDemo(),
            SizedBox(height: 24),
            _ProgressIndicatorFullDemo(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// SnackBar
class _SnackBarDemo extends StatelessWidget {
  const _SnackBarDemo();

  void _showSnackBar(BuildContext context, String msg, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FeedbackCategory(
      title: 'SnackBar',
      description: '轻量级消息提示',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showSnackBar(context, '默认提示'),
            child: const Text('默认'),
          ),
          ElevatedButton(
            onPressed: () => _showSnackBar(context, '成功操作！', backgroundColor: AppTheme.success),
            child: const Text('成功'),
          ),
          ElevatedButton(
            onPressed: () => _showSnackBar(context, '发生错误！', backgroundColor: AppTheme.error),
            child: const Text('错误'),
          ),
          ElevatedButton(
            onPressed: () => _showSnackBar(context, '警告信息', backgroundColor: AppTheme.warning),
            child: const Text('警告'),
          ),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('带操作按钮的提示'),
                action: SnackBarAction(
                  label: '撤销',
                  onPressed: () {},
                ),
              ),
            ),
            child: const Text('带操作'),
          ),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('这是一段较长的提示文字，可能会换行显示'),
                duration: Duration(seconds: 4),
              ),
            ),
            child: const Text('长文本'),
          ),
        ],
      ),
    );
  }
}

// Banner
class _BannerDemo extends StatelessWidget {
  const _BannerDemo();

  @override
  Widget build(BuildContext context) {
    return _FeedbackCategory(
      title: 'Banner',
      description: '显示在页面顶部的提示条',
      child: Column(
        children: [
          Banner(
            message: '横幅消息',
            location: BannerLocation.topEnd,
            color: Theme.of(context).colorScheme.error,
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('带 Banner 的卡片'),
                subtitle: const Text('顶部显示横幅'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Banner(
            message: '新功能',
            location: BannerLocation.bottomStart,
            color: Theme.of(context).colorScheme.primary,
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.new_releases),
                title: const Text('另一个 Banner'),
                subtitle: const Text('底部显示'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tooltip
class _TooltipDemo extends StatelessWidget {
  const _TooltipDemo();

  @override
  Widget build(BuildContext context) {
    return _FeedbackCategory(
      title: 'Tooltip',
      description: '长按或悬停显示的提示',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          Tooltip(
            message: '这是工具提示',
            child: ElevatedButton(onPressed: () {}, child: const Text('悬停查看')),
          ),
          Tooltip(
            message: '显示在顶部',
            preferBelow: false,
            child: ElevatedButton(onPressed: () {}, child: const Text('顶部提示')),
          ),
          Tooltip(
            message: 'Rich tooltip\n第二行内容',
            child: ElevatedButton(onPressed: () {}, child: const Text('富文本')),
          ),
          Tooltip(
            message: '带图标的提示',
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 28),
              onPressed: () {},
            ),
          ),
          Tooltip(
            message: '禁用状态',
            child: ElevatedButton(onPressed: null, child: const Text('禁用按钮')),
          ),
        ],
      ),
    );
  }
}

// InkWell
class _InkWellDemo extends StatelessWidget {
  const _InkWellDemo();

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return _FeedbackCategory(
      title: 'InkWell & InkResponse',
      description: '点击波纹效果',
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              title: const Text('点击效果'),
              subtitle: const Text('点击会显示波纹'),
              trailing: const Icon(Icons.touch_app),
              onTap: () => _showSnackBar(context, '点击了！'),
            ),
                        const Divider(height: 1),
            GestureDetector(
              onTap: () => _showSnackBar(context, '点击了！'),
              onDoubleTap: () => _showSnackBar(context, '双击了！'),
              child: ListTile(
                title: const Text('双击效果'),
                subtitle: const Text('试试双击此处'),
                trailing: const Icon(Icons.ads_click),
              ),
            ),
            const Divider(height: 1),
            GestureDetector(
              onLongPress: () => _showSnackBar(context, '长按了！'),
              child: ListTile(
                title: const Text('长按效果'),
                subtitle: const Text('试试长按此处'),
                trailing: const Icon(Icons.touch_app_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Badge
class _BadgeDemo extends StatelessWidget {
  const _BadgeDemo();

  @override
  Widget build(BuildContext context) {
    return _FeedbackCategory(
      title: 'Badge',
      description: '徽章组件，用于显示数量或状态',
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          Column(
            children: [
              Badge(
                label: const Text('3'),
                child: IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
              ),
              const SizedBox(height: 4),
              const Text('数字', style: TextStyle(fontSize: 12)),
            ],
          ),
          Column(
            children: [
              Badge(
                label: const Text('99+'),
                child: IconButton(icon: const Icon(Icons.email), onPressed: () {}),
              ),
              const SizedBox(height: 4),
              const Text('99+', style: TextStyle(fontSize: 12)),
            ],
          ),
          Column(
            children: [
              Badge(
                label: const Text('新'),
                smallSize: 8,
                child: IconButton(icon: const Icon(Icons.star), onPressed: () {}),
              ),
              const SizedBox(height: 4),
              const Text('小徽章', style: TextStyle(fontSize: 12)),
            ],
          ),
          Column(
            children: [
              Badge(
                label: const Text('热门'),
                backgroundColor: AppTheme.accent,
                child: IconButton(icon: const Icon(Icons.trending_up), onPressed: () {}),
              ),
              const SizedBox(height: 4),
              const Text('自定义颜色', style: TextStyle(fontSize: 12)),
            ],
          ),
          Column(
            children: [
              Badge(
                child: IconButton(icon: const Icon(Icons.message), onPressed: () {}),
              ),
              const SizedBox(height: 4),
              const Text('无文字', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ProgressIndicator 完整展示
class _ProgressIndicatorFullDemo extends StatelessWidget {
  const _ProgressIndicatorFullDemo();

  @override
  Widget build(BuildContext context) {
    return _FeedbackCategory(
      title: 'ProgressIndicator',
      description: '进度指示器',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LinearProgressIndicator', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.3),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.6),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.9),
          const SizedBox(height: 16),
          const Text('CircularProgressIndicator', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              CircularProgressIndicator(strokeWidth: 4),
              CircularProgressIndicator(strokeWidth: 6),
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(value: 0.7, strokeWidth: 4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('自定义颜色', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.3, color: AppTheme.accent),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.6, color: AppTheme.success),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.8, color: AppTheme.error),
        ],
      ),
    );
  }
}

// 通用分类组件
class _FeedbackCategory extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _FeedbackCategory({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
