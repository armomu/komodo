import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:komodo/pages/music/music_cache_service.dart';

// ─── 工具函数 ──────────────────────────────────────────────────────────

String _formatDate(DateTime dt) {
  final y = dt.year.toString();
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// 缓存来源分组
class _CacheGroup {
  final String title;
  final String subtitle;
  final IconData icon;
  final Directory directory;
  List<File> files = [];
  int totalSize = 0;

  _CacheGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.directory,
  });
}

/// 本地缓存浏览页 — 扫描所有可能的缓存目录，支持浏览和清理
class CacheBrowserPage extends StatefulWidget {
  const CacheBrowserPage({super.key});

  @override
  State<CacheBrowserPage> createState() => _CacheBrowserPageState();
}

class _CacheBrowserPageState extends State<CacheBrowserPage> {
  List<_CacheGroup> _groups = [];
  bool _loading = true;
  int _grandTotal = 0;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadAllCache();
  }

  Future<List<_CacheGroup>> _buildGroups() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();
    final musicCacheDir = await MusicCacheService.getCacheDirectory();

    // 缓存目录：按来源分组，即使目录不存在也保留以便提示
    final groups = <_CacheGroup>[
      _CacheGroup(
        title: '音乐缓存',
        subtitle: '网络歌曲离线缓存文件',
        icon: Icons.music_note,
        directory: musicCacheDir,
      ),
      _CacheGroup(
        title: '录音缓存',
        subtitle: '聊天语音消息录音文件',
        icon: Icons.mic,
        directory: Directory('${appDir.path}/voice_messages'),
      ),
      _CacheGroup(
        title: '图片缓存',
        subtitle: '聊天发送的图片文件',
        icon: Icons.image,
        directory: Directory('${appDir.path}/image_cache'),
      ),
      _CacheGroup(
        title: '临时目录',
        subtitle: '系统临时文件缓存',
        icon: Icons.timer,
        directory: Directory(tempDir.path),
      ),
    ];

    // 扫描每个目录
    for (final group in groups) {
      if (!await group.directory.exists()) continue;
      await for (final entity in group.directory.list()) {
        if (entity is File) {
          group.files.add(entity);
          group.totalSize += await entity.length();
        }
      }
      // 文件按修改时间倒序
      group.files.sort((a, b) {
        return b.statSync().modified.compareTo(a.statSync().modified);
      });
    }

    return groups;
  }

  Future<void> _loadAllCache() async {
    setState(() => _loading = true);
    try {
      _groups = await _buildGroups();
      _grandTotal = _groups.fold(0, (sum, g) => sum + g.totalSize);
      _selected.clear();
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载失败: $e')));
      }
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      _loadAllCache();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    try {
      for (final path in _selected) {
        await File(path).delete();
      }
      _loadAllCache();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('批量删除失败: $e')));
      }
    }
  }

  Future<void> _clearGroup(_CacheGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: Text(
          '删除「${group.title}」全部 ${group.files.length} 个文件（${_formatSize(group.totalSize)}）？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      for (final f in group.files) {
        await f.delete();
      }
      _loadAllCache();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('清空失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('缓存管理'),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '删除选中 (${_selected.length})',
              onPressed: _deleteSelected,
            ),
          // if (_grandTotal > 0)
          //   IconButton(
          //     icon: const Icon(Icons.delete_sweep),
          //     tooltip: '清空全部缓存',
          //     onPressed: _clearAll,
          //   ),
          // IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllCache),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _grandTotal == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无缓存文件',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _loadAllCache,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('刷新'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllCache,
              child: SafeArea(
                bottom: true,
                child: ListView.builder(
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    if (group.files.isEmpty) return const SizedBox.shrink();
                    return _CacheGroupTile(
                      group: group,
                      selected: _selected,
                      onDeleteFile: _deleteFile,
                      onClearGroup: () => _clearGroup(group),
                      onToggleSelect: (path, value) {
                        setState(() {
                          if (value) {
                            _selected.add(path);
                          } else {
                            _selected.remove(path);
                          }
                        });
                      },
                      theme: theme,
                    );
                  },
                ),
              ),
            ),
    );
  }
}

/// 单个缓存来源的展开面板
class _CacheGroupTile extends StatelessWidget {
  final _CacheGroup group;
  final Set<String> selected;
  final Function(File) onDeleteFile;
  final VoidCallback onClearGroup;
  final void Function(String path, bool selected) onToggleSelect;
  final ThemeData theme;

  const _CacheGroupTile({
    required this.group,
    required this.selected,
    required this.onDeleteFile,
    required this.onClearGroup,
    required this.onToggleSelect,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: Icon(group.icon),
        title: Text(
          group.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${group.files.length} 个文件 · ${_formatSize(group.totalSize)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatSize(group.totalSize),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: '清空此分组',
              onPressed: onClearGroup,
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        childrenPadding: EdgeInsets.zero,
        children: group.files.map((file) {
          final stat = file.statSync();
          final name = file.uri.pathSegments.last;
          final isSelected = selected.contains(file.path);
          return ListTile(
            dense: true,
            selected: isSelected,
            selectedTileColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
            leading: Checkbox(
              value: isSelected,
              onChanged: (v) => onToggleSelect(file.path, v ?? false),
            ),
            title: Text(
              name,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${_formatSize(stat.size)}  ·  ${_formatDate(stat.modified)}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => onDeleteFile(file),
            ),
          );
        }).toList(),
      ),
    );
  }
}
