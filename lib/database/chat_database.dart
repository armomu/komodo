import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/message/models/chat_models.dart';

/// 聊天本地数据库 — 方案A：去掉 conversations 表，
/// messages 表直接用 peer_id 关联用户，无中间会话层。
///
/// 启动优化：注册为全局 GetxService 但不立即初始化。
///   通过 ensureInitialized() 在首帧后或消息 Tab 首次访问时懒加载。
class ChatDatabase extends GetxService {
  static ChatDatabase get to => Get.find();

  Database? _db;
  bool _initializing = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// 获取 database 实例（调用前必须先 ensureInitialized）
  Database get db => _db!;

  // ── 表名 ──────────────────────────────────────────────────────────
  static const String tableMessages = 'messages';

  // ── 懒初始化 ──────────────────────────────────────────────────────────

  /// 确保数据库已初始化（幂等，多次调用安全）
  Future<void> ensureInitialized() async {
    if (_db != null) return;
    if (_initializing) {
      await _initCompleter.future;
      return;
    }
    _initializing = true;
    try {
      await _init();
      _initCompleter.complete();
    } catch (e) {
      _initializing = false;
      rethrow;
    }
  }

  Future<void> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'komodo_chat.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableMessages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            peer_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            is_me INTEGER NOT NULL DEFAULT 0,
            content TEXT,
            image_url TEXT,
            is_local_image INTEGER DEFAULT 0,
            duration INTEGER,
            voice_path TEXT,
            gift_emoji TEXT,
            gift_label TEXT,
            time TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // 方案A迁移：删掉旧表，重建 messages 表（旧数据不保留）
          await db.execute('DROP TABLE IF EXISTS conversations');
          await db.execute('DROP TABLE IF EXISTS messages_old');
          await db.execute('ALTER TABLE $tableMessages RENAME TO messages_old');
          await db.execute('''
            CREATE TABLE $tableMessages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              peer_id INTEGER NOT NULL,
              type TEXT NOT NULL,
              is_me INTEGER NOT NULL DEFAULT 0,
              content TEXT,
              image_url TEXT,
              is_local_image INTEGER DEFAULT 0,
              duration INTEGER,
              voice_path TEXT,
              gift_emoji TEXT,
              gift_label TEXT,
              time TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          // 旧表数据不迁移（方案A：conversations 已删除，peer_id 无法追溯）
          await db.execute('DROP TABLE IF EXISTS messages_old');
        }
      },
    );
  }

  // ── 消息 CRUD（方案A：直接用 peer_id）────────────────────────────

  /// 插入一条消息，返回新行 id
  Future<int> insertMessage(int peerId, ChatMessage msg) async {
    await ensureInitialized();
    return await db.insert(tableMessages, {
      'peer_id': peerId,
      'type': msg.type.name,
      'is_me': msg.isMe ? 1 : 0,
      'content': msg.content,
      'image_url': msg.imageUrl,
      'is_local_image': msg.isLocalImage ? 1 : 0,
      'duration': msg.duration,
      'voice_path': msg.voicePath,
      'gift_emoji': msg.giftEmoji,
      'gift_label': msg.giftLabel,
      'time': msg.time,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 获取某用户的消息列表（按 id 升序）
  Future<List<ChatMessage>> getMessagesByPeerId(int peerId) async {
    await ensureInitialized();
    final rows = await db.query(
      tableMessages,
      where: 'peer_id = ?',
      whereArgs: [peerId],
      orderBy: 'id ASC',
    );
    return rows.map((r) {
      final type = ChatMsgType.values.firstWhere(
        (e) => e.name == r['type'],
        orElse: () => ChatMsgType.text,
      );
      return ChatMessage(
        type: type,
        isMe: r['is_me'] == 1,
        content: r['content'] as String?,
        imageUrl: r['image_url'] as String?,
        isLocalImage: r['is_local_image'] == 1,
        duration: r['duration'] as int?,
        voicePath: r['voice_path'] as String?,
        giftEmoji: r['gift_emoji'] as String?,
        giftLabel: r['gift_label'] as String?,
        time: r['time'] as String?,
      );
    }).toList();
  }

  /// 获取某用户的最后一条消息（用于列表 subtitle）
  Future<(String? content, String? time)> getLastMessageByPeerId(
    int peerId,
  ) async {
    await ensureInitialized();
    final rows = await db.query(
      tableMessages,
      where: 'peer_id = ?',
      whereArgs: [peerId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return (null, null);
    final r = rows.first;
    return (r['content'] as String?, r['time'] as String?);
  }

  /// 获取某用户的未读消息数（is_me=0 的消息条数）
  Future<int> getUnreadCountByPeerId(int peerId) async {
    await ensureInitialized();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $tableMessages WHERE peer_id = ? AND is_me = 0',
      [peerId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// 清除某用户的未读数
  Future<void> clearUnreadByPeerId(int peerId) async {
    // 方案A：未读数不单独存，通过 is_me=0 的消息条数实时计算
    // 如需"已读/未读"状态，需要加一个 `is_read` 字段，
    // 这里先保留接口，实际由 getUnreadCountByPeerId 实时查询。
    await ensureInitialized();
    // 标记所有收到的消息为已读（未来加 is_read 字段后实现）
    // 当前未读数 = 收到的消息总数（进入聊天页即视为全部已读）
    // 所以 clearUnread 在方案A下不需要改 DB，只需在 Controller 里把 unread 置零
  }

  /// 增加某用户的未读数（后台收到消息时调用）
  /// 方案A：未读数由 Controller 内存维护，DB 层不单独存未读状态
  /// 如需持久化未读，需加 is_read 字段
  Future<void> incrementUnreadByPeerId(int peerId) async {
    // 方案A：未读数不持久化，由 Controller RxInt 维护
    // 此方法保留接口，实际逻辑在 Controller 中处理
  }

  // ── 清空数据 ─────────────────────────────────────────────────────

  Future<void> clearAllData() async {
    await ensureInitialized();
    await db.delete(tableMessages);
  }

  // ── 查询工具（demo 页使用） ───────────────────────────────────────

  Future<List<String>> getTableNames() async {
    await ensureInitialized();
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    return rows
        .map((r) => r['name'] as String)
        .where((n) => n != 'android_metadata' && n != 'sqlite_sequence')
        .toList();
  }

  Future<List<Map<String, dynamic>>> queryTable(String tableName) async {
    await ensureInitialized();
    return await db.query(tableName, orderBy: 'id DESC', limit: 200);
  }

  Future<List<Map<String, dynamic>>> queryRaw(String sql) async {
    await ensureInitialized();
    return await db.rawQuery(sql);
  }
}
