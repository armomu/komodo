import 'package:flutter/material.dart';
import 'package:komodo/components/switch_theme.dart';
import '../../../theme/app_theme.dart';

/// ========================================
/// 表单组件 - Material 3 Form Components
/// ========================================
class FormSection extends StatelessWidget {
  const FormSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('表单组件'),
        actions: const [SwitchThemeWidget()],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _TextFieldDemo(),
            SizedBox(height: 24),
            _SwitchDemo(),
            SizedBox(height: 24),
            _CheckboxDemo(),
            SizedBox(height: 24),
            _RadioDemo(),
            SizedBox(height: 24),
            _SliderDemo(),
            SizedBox(height: 24),
            _DropdownDemo(),
            SizedBox(height: 24),
            _ChipDemo(),
            SizedBox(height: 24),
            _DateTimePickerDemo(),
            SizedBox(height: 24),
            _SearchBarDemo(),
            SizedBox(height: 24),
            _ProgressIndicatorDemo(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// TextField
class _TextFieldDemo extends StatelessWidget {
  const _TextFieldDemo();

  @override
  Widget build(BuildContext context) {
    return _FormCategory(
      title: 'TextField & TextFormField',
      description: '文本输入框，支持多种状态和变体',
      child: Column(
        children: [
          const TextField(
            decoration: InputDecoration(
              hintText: '请输入文字',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: '用户名',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: '邮箱',
              prefixIcon: Icon(Icons.email),
              helperText: '请输入有效的邮箱地址',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: Icon(Icons.lock),
              errorText: '密码不能为空',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: '电话号码',
              prefixIcon: Icon(Icons.phone),
              filled: true,
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: '验证码',
                    prefixIcon: Icon(Icons.verified_user),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () {}, child: const Text('获取验证码')),
            ],
          ),
        ],
      ),
    );
  }
}

// Switch
class _SwitchDemo extends StatefulWidget {
  const _SwitchDemo();

  @override
  State<_SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> {
  bool _switchValue = true;
  bool _switch2Value = false;

  @override
  Widget build(BuildContext context) {
    return _FormCategory(
      title: 'Switch',
      description: '开关选择器',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('接收通知'),
              Switch(
                value: _switchValue,
                onChanged: (v) => setState(() => _switchValue = v),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('深色模式'),
              Switch(
                value: _switch2Value,
                onChanged: (v) => setState(() => _switch2Value = v),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '禁用状态',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Switch(value: false, onChanged: null),
            ],
          ),
        ],
      ),
    );
  }
}

// Checkbox
class _CheckboxDemo extends StatefulWidget {
  const _CheckboxDemo();

  @override
  State<_CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<_CheckboxDemo> {
  bool _checkboxValue = true;
  bool? _tristateValue;

  @override
  Widget build(BuildContext context) {
    return _FormCategory(
      title: 'Checkbox',
      description: '复选框，支持三态',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('同意服务条款'),
              Checkbox(
                value: _checkboxValue,
                onChanged: (v) => setState(() => _checkboxValue = v ?? false),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('不确定状态'),
              Checkbox(
                value: _tristateValue,
                tristate: true,
                onChanged: (v) => setState(() => _tristateValue = v),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '禁用状态',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Checkbox(value: false, onChanged: null),
            ],
          ),
        ],
      ),
    );
  }
}

// Radio
class _RadioDemo extends StatefulWidget {
  const _RadioDemo();

  @override
  State<_RadioDemo> createState() => _RadioDemoState();
}

class _RadioDemoState extends State<_RadioDemo> {
  int? _radioValue;

  @override
  Widget build(BuildContext context) {
    return _FormCategory(
      title: 'Radio',
      description: '单选按钮',
      child: Column(
        children: [
          RadioListTile<int>(
            value: 0,
            groupValue: _radioValue,
            onChanged: (v) => setState(() => _radioValue = v),
            title: const Text('选项 A'),
            subtitle: const Text('描述文本 A'),
          ),
          RadioListTile<int>(
            value: 1,
            groupValue: _radioValue,
            onChanged: (v) => setState(() => _radioValue = v),
            title: const Text('选项 B'),
            subtitle: const Text('描述文本 B'),
          ),
          RadioListTile<int>(
            value: 2,
            groupValue: _radioValue,
            onChanged: (v) => setState(() => _radioValue = v),
            title: const Text('选项 C'),
            subtitle: const Text('描述文本 C'),
          ),
          RadioListTile<int>(
            value: 3,
            groupValue: null,
            onChanged: null,
            title: Text(
              '禁用状态',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Slider
class _SliderDemo extends StatefulWidget {
  const _SliderDemo();

  @override
  State<_SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<_SliderDemo> {
  double _sliderValue = 0.5;
  RangeValues _rangeValues = const RangeValues(0.2, 0.8);

  @override
  Widget build(BuildContext context) {
    return _FormCategory(
      title: 'Slider & RangeSlider',
      description: '滑块选择器',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('音量'),
              Expanded(
                child: Slider(
                  value: _sliderValue,
                  onChanged: (v) => setState(() => _sliderValue = v),
                ),
              ),
              Text('${(_sliderValue * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('范围选择'),
          RangeSlider(
            values: _rangeValues,
            onChanged: (values) => setState(() => _rangeValues = values),
            labels: RangeLabels(
              '${(_rangeValues.start * 100).toInt()}',
              '${(_rangeValues.end * 100).toInt()}',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_rangeValues.start * 100).toInt()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${(_rangeValues.end * 100).toInt()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Dropdown
class _DropdownDemo extends StatefulWidget {
  const _DropdownDemo();

  @override
  State<_DropdownDemo> createState() => _DropdownDemoState();
}

class _DropdownDemoState extends State<_DropdownDemo> {
  String? _dropdownValue;
  final _items = [
    const DropdownMenuItem(value: 'beijing', child: Text('北京')),
    const DropdownMenuItem(value: 'shanghai', child: Text('上海')),
    const DropdownMenuItem(value: 'guangzhou', child: Text('广州')),
    const DropdownMenuItem(value: 'shenzhen', child: Text('深圳')),
  ];

  @override
  Widget build(BuildContext context) {
    return _FormCategory(
      title: 'DropdownButton',
      description: '下拉选择器',
      child: Column(
        children: [
          DropdownButton<String>(
            value: _dropdownValue,
            hint: const Text('请选择城市'),
            isExpanded: true,
            items: _items,
            onChanged: (v) => setState(() => _dropdownValue = v),
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            value: 'guangzhou',
            items: _items,
            onChanged: (v) => setState(() => _dropdownValue = v),
          ),
        ],
      ),
    );
  }
}

// Chip
class _ChipDemo extends StatelessWidget {
  const _ChipDemo();

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormCategory(
      title: 'Chip',
      description: '标签组件，多种变体',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基础 Chip',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Chip(label: Text('标签 1')),
              const Chip(label: Text('标签 2')),
              const Chip(
                label: Text('音乐'),
                avatar: Icon(Icons.music_note, size: 18),
              ),
              Chip(
                label: const Text('可删除'),
                onDeleted: () => _showSnackBar(context, '删除标签'),
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'FilterChip (可选择)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('未选中'),
                selected: false,
                onSelected: (v) => _showSnackBar(context, '选择: $v'),
              ),
              FilterChip(
                label: const Text('已选中'),
                selected: true,
                onSelected: (v) => _showSnackBar(context, '选择: $v'),
              ),
              const FilterChip(
                label: Text('禁用'),
                selected: false,
                onSelected: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'InputChip (输入型)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InputChip(label: const Text('输入标签'), onPressed: () {}),
              InputChip(
                label: const Text('带头像'),
                avatar: const CircleAvatar(child: Text('A')),
                onPressed: () {},
              ),
              InputChip(
                label: const Text('可删除'),
                onDeleted: () {},
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'ActionChip (操作型)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('添加'),
                avatar: const Icon(Icons.add, size: 18),
                onPressed: () => _showSnackBar(context, '添加'),
              ),
              ActionChip(
                label: const Text('编辑'),
                avatar: const Icon(Icons.edit, size: 18),
                onPressed: () => _showSnackBar(context, '编辑'),
              ),
              ActionChip(
                label: const Text('删除'),
                avatar: const Icon(Icons.delete, size: 18),
                onPressed: () => _showSnackBar(context, '删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// DateTimePicker
class _DateTimePickerDemo extends StatelessWidget {
  const _DateTimePickerDemo();

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
    return _FormCategory(
      title: 'DatePicker & TimePicker',
      description: '日期和时间选择器',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showDatePicker(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('选择日期'),
          ),
          ElevatedButton.icon(
            onPressed: () => _showTimePicker(context),
            icon: const Icon(Icons.access_time),
            label: const Text('选择时间'),
          ),
        ],
      ),
    );
  }
}

// SearchBar
class _SearchBarDemo extends StatelessWidget {
  const _SearchBarDemo();

  @override
  Widget build(BuildContext context) {
    return _FormCategory(
      title: 'SearchBar',
      description: '搜索框组件',
      child: Column(
        children: [
          SearchBar(
            hintText: '搜索...',
            leading: const Icon(Icons.search),
            trailing: [
              IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 12),
          SearchBar(
            hintText: '带麦克风',
            leading: const Icon(Icons.search),
            trailing: [
              IconButton(icon: const Icon(Icons.mic), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

// ProgressIndicator
class _ProgressIndicatorDemo extends StatelessWidget {
  const _ProgressIndicatorDemo();

  @override
  Widget build(BuildContext context) {
    return const _FormCategory(
      title: 'ProgressIndicator',
      description: '进度指示器',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LinearProgressIndicator',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(),
          SizedBox(height: 12),
          LinearProgressIndicator(value: 0.3, color: AppTheme.accent),
          SizedBox(height: 8),
          LinearProgressIndicator(value: 0.6, color: AppTheme.success),
          SizedBox(height: 8),
          LinearProgressIndicator(value: 0.8, color: AppTheme.error),
          SizedBox(height: 16),
          Text(
            'CircularProgressIndicator',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 8),
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
        ],
      ),
    );
  }
}

// 通用分类组件
class _FormCategory extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _FormCategory({
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
