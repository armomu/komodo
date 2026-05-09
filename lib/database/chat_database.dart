import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/message/models/chat_models.dart';
import 'package:komodo/pages/home/tabs/models/message_models.dart';

/// 聊天本地数据库 — 持久化会话列表 & 聊天消息
class ChatDatabase extends GetxService {
  static ChatDatabase get to => Get.find();

  Database? _db;

  Database get db => _db!;

  // ── 表名 ──────────────────────────────────────────────────────────
  static const String tableConversations = 'conversations';
  static const String tableMessages = 'messages';

  // ── 初始化 ──────────────────────────────────────────────────────────

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'komodo_chat.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableConversations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            peer_name TEXT NOT NULL,
            peer_avatar TEXT NOT NULL,
            last_message TEXT,
            last_time TEXT,
            unread_count INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableMessages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id INTEGER NOT NULL,
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
            created_at TEXT NOT NULL,
            FOREIGN KEY (conversation_id) REFERENCES $tableConversations(id)
          )
        ''');
      },
    );

    // 首次启动时填充种子数据
    final count = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM $tableConversations'),
    );
    if (count == 0) {
      await _seedDefaultData();
    }
  }

  // ── 种子数据 ──────────────────────────────────────────────────────────

  Future<void> _seedDefaultData() async {
    final conversations = [
      ('Sarah Miller', 'https://picsum.photos/seed/user1/100/100'),
      ('John Doe', 'https://picsum.photos/seed/user2/100/100'),
      ('Emma Wilson', 'https://picsum.photos/seed/user3/100/100'),
      ('Mike Chen', 'https://picsum.photos/seed/user4/100/100'),
    ];

    for (final (name, avatar) in conversations) {
      final convId = await _insertConversation(
        name,
        avatar,
        '你好呀～',
        '昨天',
        name == 'Sarah Miller' ? 2 : 0,
      );
      if (name == 'Sarah Miller') {
        // 初始聊天记录
        await _insertMessage(
          convId,
          ChatMsgType.timestamp,
          false,
          time: '19:01',
        );
        await _insertMessage(
          convId,
          ChatMsgType.text,
          false,
          content: '嗨，你好呀～很高兴认识你 😊',
        );
        await _insertMessage(
          convId,
          ChatMsgType.voice,
          false,
          voicePath: 'https://www.w3schools.com/html/horse.mp3',
          duration: 11,
        );
        await _insertMessage(
          convId,
          ChatMsgType.image,
          false,
          imageUrl: 'https://picsum.photos/seed/chatimg1/400/600',
        );
        await _insertMessage(
          convId,
          ChatMsgType.text,
          false,
          content: '回复了一条信息',
        );
        await _insertMessage(convId, ChatMsgType.text, true, content: '你好呀～');
        await _insertMessage(
          convId,
          ChatMsgType.voice,
          true,
          voicePath: 'https://www.w3schools.com/html/horse.mp3',
          duration: 5,
        );
      }
    }
  }

  // ── 会话 CRUD ──────────────────────────────────────────────────────

  Future<int> _insertConversation(
    String peerName,
    String peerAvatar,
    String? lastMessage,
    String? lastTime, [
    int unread = 0,
  ]) async {
    return await db.insert(tableConversations, {
      'peer_name': peerName,
      'peer_avatar': peerAvatar,
      'last_message': lastMessage,
      'last_time': lastTime,
      'unread_count': unread,
    });
  }

  Future<List<MessageItem>> getConversations() async {
    final rows = await db.query(tableConversations, orderBy: 'id ASC');
    return rows
        .map(
          (r) => MessageItem(
            type: MessageType.private,
            title: r['peer_name'] as String,
            subtitle: r['last_message'] as String? ?? '',
            time: r['last_time'] as String? ?? '',
            avatarUrl: r['peer_avatar'] as String,
            unread: r['unread_count'] as int? ?? 0,
          ),
        )
        .toList();
  }

  /// 获取或创建会话，返回 (id, isNew)
  Future<(int, bool)> getOrCreateConversation(
    String peerName,
    String peerAvatar,
  ) async {
    final rows = await db.query(
      tableConversations,
      where: 'peer_name = ?',
      whereArgs: [peerName],
    );
    if (rows.isNotEmpty) {
      return (rows.first['id'] as int, false);
    }
    final id = await _insertConversation(peerName, peerAvatar, null, null, 0);
    return (id, true);
  }

  Future<void> updateConversationLastMessage(
    int conversationId,
    String lastMessage,
    String lastTime,
  ) async {
    await db.update(
      tableConversations,
      {'last_message': lastMessage, 'last_time': lastTime},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> updateConversationUnread(
    int conversationId,
    int unreadCount,
  ) async {
    await db.update(
      tableConversations,
      {'unread_count': unreadCount},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // ── 消息 CRUD ──────────────────────────────────────────────────────

  Future<int> _insertMessage(
    int conversationId,
    ChatMsgType type,
    bool isMe, {
    String? content,
    String? imageUrl,
    bool? isLocalImage,
    int? duration,
    String? voicePath,
    String? giftEmoji,
    String? giftLabel,
    String? time,
  }) async {
    return await db.insert(tableMessages, {
      'conversation_id': conversationId,
      'type': type.name,
      'is_me': isMe ? 1 : 0,
      'content': content,
      'image_url': imageUrl,
      'is_local_image': isLocalImage == true ? 1 : 0,
      'duration': duration,
      'voice_path': voicePath,
      'gift_emoji': giftEmoji,
      'gift_label': giftLabel,
      'time': time,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> insertMessage(int conversationId, ChatMessage msg) async {
    return await _insertMessage(
      conversationId,
      msg.type,
      msg.isMe,
      content: msg.content,
      imageUrl: msg.imageUrl,
      isLocalImage: msg.isLocalImage,
      duration: msg.duration,
      voicePath: msg.voicePath,
      giftEmoji: msg.giftEmoji,
      giftLabel: msg.giftLabel,
      time: msg.time,
    );
  }

  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final rows = await db.query(
      tableMessages,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
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

  // ── 清空数据 ─────────────────────────────────────────────────────

  Future<void> clearAllData() async {
    await db.delete(tableMessages);
    await db.delete(tableConversations);
  }

  // ── 查询工具（demo 页使用） ───────────────────────────────────────

  Future<List<String>> getTableNames() async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    return rows
        .map((r) => r['name'] as String)
        .where((n) => n != 'android_metadata')
        .toList();
  }

  Future<List<Map<String, dynamic>>> queryTable(String tableName) async {
    return await db.query(tableName, orderBy: 'id DESC', limit: 200);
  }

  Future<List<Map<String, dynamic>>> queryRaw(String sql) async {
    return await db.rawQuery(sql);
  }
}
