import 'package:komodo/models/api_response.dart';
import 'package:komodo/utils/request.dart';
import '../models/live_models.dart';

/// 直播 HTTP API 封装
class LiveRepository {
  /// 创建直播间（主播）
  static Future<ApiResponse<LiveRoom>> createRoom({
    required String title,
    String? coverUrl,
    String? announcement,
  }) {
    return appDio<LiveRoom>(
      '/live/room/create',
      method: 'post',
      data: {
        'title': title,
        if (coverUrl != null) 'coverUrl': coverUrl,
        if (announcement != null) 'announcement': announcement,
      },
      fromJsonT: (json) => LiveRoom.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取正在直播的房间列表
  static Future<ApiResponse<List<LiveRoom>>> getRoomList({int page = 1, int pageSize = 20}) {
    return appDio<List<LiveRoom>>(
      '/live/room/list',
      params: {'page': page, 'pageSize': pageSize},
      fromJsonT: (json) {
        final data = json as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        return items.map((e) => LiveRoom.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  /// 获取直播间详情
  static Future<ApiResponse<LiveRoom>> getRoomDetail(String roomId) {
    return appDio<LiveRoom>(
      '/live/room/$roomId',
      fromJsonT: (json) => LiveRoom.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 更新直播间
  static Future<ApiResponse<LiveRoom>> updateRoom(
    String roomId, {
    String? title,
    String? coverUrl,
    String? announcement,
  }) {
    return appDio<LiveRoom>(
      '/live/room/$roomId',
      method: 'patch',
      data: {
        if (title != null) 'title': title,
        if (coverUrl != null) 'coverUrl': coverUrl,
        if (announcement != null) 'announcement': announcement,
      },
      fromJsonT: (json) => LiveRoom.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 记录一次观看
  static Future<ApiResponse<void>> recordView(String roomId) {
    return appDio<void>('/live/room/$roomId/view', method: 'post');
  }

  /// 获取主播的历史直播列表
  static Future<ApiResponse<List<LiveRoomHistory>>> getHistoryByHost(
    int hostId, {
    int page = 1,
    int pageSize = 20,
  }) {
    return appDio<List<LiveRoomHistory>>(
      '/live/history/$hostId',
      params: {'page': page, 'pageSize': pageSize},
      fromJsonT: (json) {
        final data = json as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        return items.map((e) => LiveRoomHistory.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  /// 获取单场直播历史详情（含评论+礼物）
  static Future<ApiResponse<LiveHistoryDetail>> getHistoryDetail(String roomId) {
    return appDio<LiveHistoryDetail>(
      '/live/history/detail/$roomId',
      fromJsonT: (json) => LiveHistoryDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取直播间评论
  static Future<ApiResponse<List<LiveComment>>> getRoomComments(
    String roomId, {
    int page = 1,
    int pageSize = 50,
  }) {
    return appDio<List<LiveComment>>(
      '/live/$roomId/comments',
      params: {'page': page, 'pageSize': pageSize},
      fromJsonT: (json) {
        final data = json as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        return items.map((e) => LiveComment.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  /// 获取直播间礼物
  static Future<ApiResponse<List<LiveGift>>> getRoomGifts(
    String roomId, {
    int page = 1,
    int pageSize = 50,
  }) {
    return appDio<List<LiveGift>>(
      '/live/$roomId/gifts',
      params: {'page': page, 'pageSize': pageSize},
      fromJsonT: (json) {
        final data = json as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        return items.map((e) => LiveGift.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }
}
