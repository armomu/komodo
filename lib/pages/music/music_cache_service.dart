import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 音乐缓存服务
///
/// 负责将网络歌曲下载到本地缓存目录，下次播放时直接从本地读取。
/// 缓存目录：{应用文档目录}/music_cache/
class MusicCacheService {
  static const String _cacheDirName = 'music_cache';

  /// 共享 Dio 实例（复用连接池，提高下载效率）
  static Dio? _dio;

  static Dio get _sharedDio {
    if (_dio != null) return _dio!;
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        // 下载大文件时不限制响应体大小
      ),
    );
    return _dio!;
  }

  /// 获取音乐缓存目录（不存在则自动创建）
  static Future<Directory> getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}${p.separator}$_cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 根据 URL 生成唯一且安全的本地文件名
  ///
  /// 使用 URL 的 base64Url 编码作为文件名主体，并保留原始扩展名（如 .mp3）。
  /// base64Url 编码不含 +/= 等文件系统不安全字符。
  static String _filenameFromUrl(String url) {
    final bytes = utf8.encode(url);
    final encoded = base64Url.encode(bytes);
    // 截断避免文件名过长（大多数文件系统限制 255 字符）
    final truncated = encoded.length > 64 ? encoded.substring(0, 64) : encoded;
    // 保留扩展名便于识别文件类型
    String ext = '';
    try {
      ext = p.extension(Uri.parse(url).path);
    } catch (_) {}
    return '$truncated$ext';
  }

  /// 获取给定 URL 对应的缓存文件路径（不检查文件是否存在）
  static Future<String> _getCacheFilePath(String audioPath) async {
    final dir = await getCacheDirectory();
    final filename = _filenameFromUrl(audioPath);
    return '${dir.path}${p.separator}$filename';
  }

  /// 检查指定网络地址是否已有本地缓存
  ///
  /// 返回缓存文件的完整路径，若未缓存则返回 null。
  static Future<String?> getCachedPath(String audioPath) async {
    if (!audioPath.startsWith('http://') && !audioPath.startsWith('https://')) {
      return null;
    }
    final filePath = await _getCacheFilePath(audioPath);
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    return null;
  }

  /// 下载网络歌曲到本地缓存
  ///
  /// [audioPath] 网络音频 URL
  /// [onProgress] 下载进度回调，参数为 0.0 ~ 1.0
  /// 返回缓存文件路径。
  /// 抛出 [DioException] 或 [Exception] 时请由调用方处理。
  static Future<String> cacheSong(
    String audioPath, {
    void Function(double progress)? onProgress,
  }) async {
    final filePath = await _getCacheFilePath(audioPath);

    debugPrint('[MusicCache] 开始下载: $audioPath -> $filePath');

    await _sharedDio.download(
      audioPath,
      filePath,
      onReceiveProgress: onProgress != null
          ? (received, total) {
              if (total != -1) {
                final progress = received / total;
                onProgress(progress);
                if (progress == 1.0) {
                  debugPrint('[MusicCache] 下载进度: ${(progress * 100).toStringAsFixed(0)}%');
                }
              }
            }
          : null,
    );

    // 验证文件下载成功
    final file = File(filePath);
    final fileSize = await file.length();
    if (fileSize == 0) {
      await file.delete();
      throw Exception('下载文件为空，已删除: $audioPath');
    }

    debugPrint('[MusicCache] 下载完成: $filePath (${(fileSize / 1024).toStringAsFixed(1)} KB)');
    return filePath;
  }

  /// 获取音乐缓存目录下所有缓存文件
  static Future<List<File>> getAllCachedFiles() async {
    final dir = await getCacheDirectory();
    if (!await dir.exists()) return [];
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        files.add(entity);
      }
    }
    return files;
  }

  /// 获取音乐缓存总大小（字节）
  static Future<int> getTotalCacheSize() async {
    final files = await getAllCachedFiles();
    int total = 0;
    for (final f in files) {
      total += await f.length();
    }
    return total;
  }

  /// 清空所有音乐缓存
  static Future<void> clearCache() async {
    final dir = await getCacheDirectory();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  /// 根据 URL 删除对应的缓存文件
  static Future<void> deleteCacheByUrl(String audioPath) async {
    final cachedPath = await getCachedPath(audioPath);
    if (cachedPath != null) {
      await File(cachedPath).delete();
    }
  }
}
