import 'package:flutter/material.dart';
import 'package:komodo/components/switch_theme.dart';
import '../../../theme/app_theme.dart';

/// ========================================
/// 对话框 - Material 3 Dialogs
/// ========================================
class DialogsSection extends StatelessWidget {
  const DialogsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('对话框'),
        actions: const [SwitchThemeWidget()],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(0),
        child: Column(
          children: [
            _AlertDialogDemo(),
            SizedBox(height: 24),
            _SimpleDialogDemo(),
            SizedBox(height: 24),
            _ConfirmDialogDemo(),
            SizedBox(height: 24),
            _CustomDialogDemo(),
            SizedBox(height: 24),
            _FullScreenDialogDemo(),
            SizedBox(height: 24),
            _DateTimePickerDialogDemo(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// AlertDialog
class _AlertDialogDemo extends StatelessWidget {
  const _AlertDialogDemo();

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('这是一条提示信息。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAlertDialogWithActions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: const Text('是否保存您的更改？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('不保存'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showScrollableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('服务条款'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 10,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('条款内容 ${index + 1}：这是详细的服务条款内容，请仔细阅读并了解相关规定。\n'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('不同意'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('同意'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogCategory(
      title: 'AlertDialog',
      description: '警告对话框',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showAlertDialog(context),
            child: const Text('基础对话框'),
          ),
          ElevatedButton(
            onPressed: () => _showAlertDialogWithActions(context),
            child: const Text('带操作'),
          ),
          ElevatedButton(
            onPressed: () => _showScrollableDialog(context),
            child: const Text('可滚动内容'),
          ),
        ],
      ),
    );
  }
}

// SimpleDialog
class _SimpleDialogDemo extends StatelessWidget {
  const _SimpleDialogDemo();

  void _showSimpleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择选项'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '选项 A'),
            child: const Text('选项 A'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '选项 B'),
            child: const Text('选项 B'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '选项 C'),
            child: const Text('选项 C'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '选项 D'),
            child: const Text('选项 D'),
          ),
        ],
      ),
    ).then((value) {
      if (value != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择了: $value')));
      }
    });
  }

  void _showIconDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('分享到'),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _IconOption(
                icon: Icons.wechat,
                label: '微信',
                color: Colors.green,
                onTap: () => Navigator.pop(context, '微信'),
              ),
              _IconOption(
                icon: Icons.chat,
                label: '微博',
                color: Colors.orange,
                onTap: () => Navigator.pop(context, '微博'),
              ),
              _IconOption(
                icon: Icons.link,
                label: '复制',
                color: Colors.blue,
                onTap: () => Navigator.pop(context, '复制'),
              ),
              _IconOption(
                icon: Icons.more_horiz,
                label: '更多',
                color: Colors.grey,
                onTap: () => Navigator.pop(context, '更多'),
              ),
            ],
          ),
        ],
      ),
    ).then((value) {
      if (value != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择了: $value')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DialogCategory(
      title: 'SimpleDialog',
      description: '简单选项对话框',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showSimpleDialog(context),
            child: const Text('选项列表'),
          ),
          ElevatedButton(
            onPressed: () => _showIconDialog(context),
            child: const Text('带图标'),
          ),
        ],
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _IconOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ConfirmDialog
class _ConfirmDialogDemo extends StatelessWidget {
  const _ConfirmDialogDemo();

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, size: 48, color: Theme.of(context).colorScheme.error),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogCategory(
      title: 'ConfirmationDialog',
      description: '确认对话框',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showConfirmDialog(
              context,
              '确认删除',
              '确定要删除吗？此操作无法撤销。',
              Icons.delete,
            ),
            child: const Text('删除确认'),
          ),
          ElevatedButton(
            onPressed: () => _showConfirmDialog(
              context,
              '确认退出',
              '您确定要退出吗？',
              Icons.exit_to_app,
            ),
            child: const Text('退出确认'),
          ),
        ],
      ),
    );
  }
}

// Custom Dialog
class _CustomDialogDemo extends StatelessWidget {
  const _CustomDialogDemo();

  void _showCustomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: AppTheme.success),
              const SizedBox(height: 16),
              const Text(
                '操作成功',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '您的操作已成功完成。',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('完成'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogCategory(
      title: 'Custom Dialog',
      description: '自定义对话框',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showCustomDialog(context),
            child: const Text('自定义对话框'),
          ),
        ],
      ),
    );
  }
}

// FullScreen Dialog
class _FullScreenDialogDemo extends StatelessWidget {
  const _FullScreenDialogDemo();

  void _showFullScreenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('全屏对话框'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('完成'),
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 20,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text('列表项 ${index + 1}'),
                subtitle: Text('这是第 ${index + 1} 项的描述文字'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogCategory(
      title: 'Fullscreen Dialog',
      description: '全屏对话框',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showFullScreenDialog(context),
            child: const Text('全屏对话框'),
          ),
        ],
      ),
    );
  }
}

// DateTimePicker Dialog
class _DateTimePickerDialogDemo extends StatelessWidget {
  const _DateTimePickerDialogDemo();

  Future<void> _showDatePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择日期: $date')));
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择时间: $time')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DialogCategory(
      title: 'DatePicker & TimePicker',
      description: '日期和时间选择对话框',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showDatePicker(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('日期选择'),
          ),
          ElevatedButton.icon(
            onPressed: () => _showTimePicker(context),
            icon: const Icon(Icons.access_time),
            label: const Text('时间选择'),
          ),
        ],
      ),
    );
  }
}

// 通用分类组件
class _DialogCategory extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _DialogCategory({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
