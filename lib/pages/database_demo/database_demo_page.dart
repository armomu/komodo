import 'package:flutter/material.dart';
import 'package:komodo/database/chat_database.dart';

/// 数据库查询演示页 — 实时浏览和操作本地 SQLite 数据
class DatabaseDemoPage extends StatefulWidget {
  const DatabaseDemoPage({super.key});

  @override
  State<DatabaseDemoPage> createState() => _DatabaseDemoPageState();
}

class _DatabaseDemoPageState extends State<DatabaseDemoPage> {
  final ChatDatabase _db = ChatDatabase.to;
  final TextEditingController _sqlController = TextEditingController();
  final ScrollController _tableScroll = ScrollController();

  List<String> _tables = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _rows = [];
  List<String> _columns = [];
  String _status = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _sqlController.dispose();
    _tableScroll.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    setState(() => _loading = true);
    try {
      _tables = await _db.getTableNames();
      if (_tables.isNotEmpty) {
        _selectedTable = _tables.first;
        await _queryTable(_selectedTable!);
      }
    } catch (e) {
      _setStatus('加载表失败: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _queryTable(String tableName) async {
    setState(() => _loading = true);
    try {
      _rows = await _db.queryTable(tableName);
      _columns =
          _rows.isNotEmpty ? _rows.first.keys.toList() : [];
      _setStatus('表 "$tableName" 共 ${_rows.length} 条记录');
    } catch (e) {
      _setStatus('查询失败: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _executeSql() async {
    final sql = _sqlController.text.trim();
    if (sql.isEmpty) return;
    setState(() => _loading = true);
    try {
      final isQuery = sql.trim().toUpperCase().startsWith('SELECT');
      if (isQuery) {
        _rows = await _db.queryRaw(sql);
        _columns =
            _rows.isNotEmpty ? _rows.first.keys.toList() : [];
        _setStatus('SQL 查询成功，返回 ${_rows.length} 条');
      } else {
        await _db.db.execute(sql);
        _setStatus('SQL 执行成功');
        _rows = [];
        _columns = [];
      }
    } catch (e) {
      _setStatus('SQL 执行失败: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('将删除所有聊天数据和会话记录，确定吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    await _db.clearAllData();
    _setStatus('所有数据已清空');
    await _loadTables();
  }

  void _setStatus(String msg) {
    setState(() => _status = msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库查询'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清空数据',
            onPressed: _clearAllData,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 表切换 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('选择表: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTable,
                    items: _tables
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedTable = v);
                        _queryTable(v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _queryTable(_selectedTable!),
                ),
              ],
            ),
          ),

          // ── 数据表格 ──
          Expanded(
            flex: 3,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(
                        child: Text('暂无数据', style: TextStyle(color: Colors.grey)))
                    : SingleChildScrollView(
                        controller: _tableScroll,
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 16,
                            dataRowMinHeight: 32,
                            dataRowMaxHeight: 48,
                            headingRowHeight: 40,
                            columns: _columns
                                .map((c) => DataColumn(
                                    label: Text(c,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13))))
                                .toList(),
                            rows: _rows.map((row) {
                              return DataRow(
                                cells: _columns
                                    .map((c) => DataCell(
                                          Text('${row[c] ?? 'NULL'}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),

          const Divider(height: 1),

          // ── 自定义 SQL ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sqlController,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: '输入 SQL 查询...',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _executeSql(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _executeSql,
                  child: const Text('执行'),
                ),
              ],
            ),
          ),

          // ── 状态条 ──
          if (_status.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Text(_status,
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
