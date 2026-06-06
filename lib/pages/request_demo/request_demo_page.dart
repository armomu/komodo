import 'package:flutter/material.dart';
import 'package:komodo/utils/request.dart';

/// ========================================
/// 网络请求 Demo 页面
/// 展示使用 request.dart 的 appDio() 方法发起 GET / POST 请求
/// GET  — /consumer/auth/list  消息用户列表
/// POST — /consumer/auth/login 登录接口
/// ========================================
class RequestDemoPage extends StatefulWidget {
  const RequestDemoPage({super.key});

  @override
  State<RequestDemoPage> createState() => _RequestDemoPageState();
}

class _RequestDemoPageState extends State<RequestDemoPage> {
  /// 日志列表：每条日志包含时间和内容
  final List<_LogEntry> _logs = [];

  /// 是否正在请求
  bool _loading = false;

  // POST 表单控制器
  final _emailCtrl = TextEditingController(text: 'test@qq.com');
  final _passwordCtrl = TextEditingController(text: '123456');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ===================== 日志工具 =====================

  void _addLog(String tag, String message, {bool isError = false}) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
    setState(() {
      _logs.add(
        _LogEntry(time: time, tag: tag, message: message, isError: isError),
      );
    });
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }

  // ===================== GET 请求演示 =====================

  Future<void> _doGetRequest() async {
    if (_loading) return;
    setState(() => _loading = true);

    _addLog('GET', '▶ 开始请求 GET /consumer/auth/list');
    _addLog('GET', '  params: {"page": 1, "pageSize": 10}');

    final stopwatch = Stopwatch()..start();

    try {
      // 使用 appDio 发起 GET 请求
      final response = await appDio<Map<String, dynamic>>(
        '/consumer/auth/list',
        method: 'get',
        params: {'page': 1, 'pageSize': 10},
      );

      stopwatch.stop();
      _addLog('GET', '✔ 请求完成  耗时: ${stopwatch.elapsedMilliseconds}ms');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        _addLog('GET', '  响应码: ${response.code}');
        _addLog('GET', '  message: ${response.message}');

        // data 是 Map，解析分页数据
        final page = data['page'] ?? data['currentPage'] ?? '?';
        final total = data['total'] ?? data['totalCount'] ?? '?';
        final list = data['list'] as List<dynamic>? ?? [];

        _addLog('GET', '  总数: $total  当前页: $page');
        for (var i = 0; i < list.length; i++) {
          final u = list[i] as Map<String, dynamic>;
          final nickname = u['nickname'] ?? '';
          final id = u['id'] ?? '';
          final avatar = (u['avatar'] ?? '') as String;
          final avatarShort = avatar.length > 50
              ? '${avatar.substring(0, 50)}...'
              : avatar;
          _addLog(
            'GET',
            '  [$i] id=$id  nickname="$nickname"  avatar="$avatarShort"',
          );
        }
      } else {
        _addLog('GET', '✘ 请求失败: ${response.message}', isError: true);
      }
    } catch (e) {
      stopwatch.stop();
      _addLog(
        'GET',
        '✘ 异常: $e  耗时: ${stopwatch.elapsedMilliseconds}ms',
        isError: true,
      );
    }

    setState(() => _loading = false);
  }

  // ===================== POST 请求演示 =====================

  Future<void> _doPostRequest() async {
    if (_loading) return;
    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    _addLog('POST', '▶ 开始请求 POST /consumer/auth/login');
    _addLog('POST', '  data: {"email": "$email", "password": "******"}');

    final stopwatch = Stopwatch()..start();

    try {
      // 使用 appDio 发起 POST 请求
      final response = await appDio<Map<String, dynamic>>(
        '/consumer/auth/login',
        method: 'post',
        data: {'email': email, 'password': password},
        errTip: false, // Demo 页面不弹 snackbar，用日志展示
      );

      stopwatch.stop();
      _addLog('POST', '✔ 请求完成  耗时: ${stopwatch.elapsedMilliseconds}ms');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        _addLog('POST', '  响应码: ${response.code}');

        final token = (data['accessToken'] ?? data['token'] ?? '') as String;
        final tokenShort = token.length > 20
            ? '${token.substring(0, 20)}...'
            : token;
        _addLog('POST', '  accessToken: "$tokenShort"');
        _addLog('POST', '  id: ${data['id']}');
        _addLog('POST', '  email: ${data['email']}');
        _addLog('POST', '  nickname: ${data['nickname']}');
        _addLog('POST', '  avatar: ${data['avatar']}');
      } else {
        _addLog('POST', '✘ 请求失败: ${response.message}', isError: true);
      }
    } catch (e) {
      stopwatch.stop();
      _addLog(
        'POST',
        '✘ 异常: $e  耗时: ${stopwatch.elapsedMilliseconds}ms',
        isError: true,
      );
    }

    setState(() => _loading = false);
  }

  // ===================== 构建UI =====================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('网络请求 Demo')),
      body: Column(
        children: [
          // ---- 操作区域 ----
          _buildActionArea(colorScheme, isDark),

          const Divider(height: 1),

          // ---- 日志区域 ----
          Expanded(child: _buildLogArea(colorScheme, isDark)),
        ],
      ),
    );
  }

  /// 操作区域：GET 按钮 + POST 表单
  Widget _buildActionArea(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- GET 演示 ----
          _buildSectionHeader(
            icon: Icons.download_outlined,
            title: 'GET 请求',
            subtitle: '/consumer/auth/list',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey[300]!,
              ),
            ),
            child: Text(
              "final response = await appDio<Map<String, dynamic>>(\n"
              "  '/consumer/auth/list',\n"
              "  method: 'get',\n"
              "  params: {'page': 1, 'pageSize': 10},\n"
              "  errTip: false,\n"
              ");",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isDark ? Colors.green[300] : Colors.green[800],
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _doGetRequest,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('发送 GET 请求'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- POST 演示 ----
          _buildSectionHeader(
            icon: Icons.upload_outlined,
            title: 'POST 请求',
            subtitle: '/consumer/auth/login',
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey[300]!,
              ),
            ),
            child: Text(
              "final response = await appDio<Map<String, dynamic>>(\n"
              "  '/consumer/auth/login',\n"
              "  method: 'post',\n"
              "  data: {'email': email, 'password': password},\n"
              "  errTip: false,\n"
              ");",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isDark ? Colors.green[300] : Colors.green[800],
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _doPostRequest,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('发送 POST 请求'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 日志展示区域
  Widget _buildLogArea(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // 日志标题栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
          child: Row(
            children: [
              Icon(
                Icons.terminal,
                size: 16,
                color: isDark ? Colors.green[400] : Colors.green[700],
              ),
              const SizedBox(width: 6),
              Text(
                '请求日志',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.green[400] : Colors.green[700],
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              if (_logs.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('清空', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ),

        // 日志列表
        Expanded(
          child: _logs.isEmpty
              ? Center(
                  child: Text(
                    '点击上方按钮发送请求，日志将在此显示',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return _buildLogItem(log, isDark);
                  },
                ),
        ),
      ],
    );
  }

  /// 单条日志项
  Widget _buildLogItem(_LogEntry log, bool isDark) {
    final tagColor = log.tag == 'GET' ? Colors.blue : Colors.orange;
    final msgColor = log.isError
        ? Colors.red[400]
        : (isDark ? Colors.grey[300] : Colors.grey[800]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            height: 1.5,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          children: [
            // 时间戳
            TextSpan(
              text: '${log.time} ',
              style: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            // 标签
            TextSpan(
              text: '[${log.tag}] ',
              style: TextStyle(color: tagColor, fontWeight: FontWeight.bold),
            ),
            // 消息
            TextSpan(
              text: log.message,
              style: TextStyle(color: msgColor),
            ),
          ],
        ),
      ),
    );
  }

  /// 区域标题
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

/// 日志条目
class _LogEntry {
  final String time;
  final String tag;
  final String message;
  final bool isError;

  const _LogEntry({
    required this.time,
    required this.tag,
    required this.message,
    this.isError = false,
  });
}
