import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 聊天语音播放器控制器
///
/// 独立 AudioPlayer，与 MusicPlayerController 完全解耦。
/// 使用 audioplayers 包，不依赖 just_audio_background。
class ChatVoiceController extends GetxController {
  late final AudioPlayer _player;

  /// 当前正在播放的语音文件路径
  final Rx<String?> currentPath = Rx<String?>(null);

  /// 是否正在播放
  final RxBool isPlaying = false.obs;

  /// 播放进度（0.0 - 1.0）
  final RxDouble progress = 0.0.obs;

  /// 播放时长（毫秒）
  final RxInt durationMs = 0.obs;

  StreamSubscription<void>? _completeSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<void>? _stateSub;

  @override
  void onInit() {
    super.onInit();
    _player = AudioPlayer();
    _setupListeners();
  }

  @override
  void onClose() {
    _completeSub?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.onClose();
  }

  void _setupListeners() {
    // 播放完成
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (currentPath.value != null) {
        debugPrint('【ChatVoice】播放完成: ${currentPath.value}');
        isPlaying.value = false;
        progress.value = 0.0;
        currentPath.value = null;
      }
    });

    // 播放位置
    _posSub = _player.onPositionChanged.listen((pos) {
      final dur = durationMs.value;
      if (dur > 0) {
        progress.value = pos.inMilliseconds / dur;
      }
    });

    // 播放状态
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });
  }

  /// 播放指定路径的语音文件（本地路径或网络 URL）
  Future<void> play(String filePath) async {
    try {
      // 已在播这条 → 暂停
      if (currentPath.value == filePath && isPlaying.value) {
        await _player.pause();
        isPlaying.value = false;
        debugPrint('【ChatVoice】暂停: $filePath');
        return;
      }

      // 停止当前播放
      await _player.stop();

      // 加载并播放
      final isNetwork = filePath.startsWith('http://') || filePath.startsWith('https://');
      if (isNetwork) {
        await _player.setSourceUrl(filePath);
      } else {
        await _player.setSourceDeviceFile(filePath);
      }

      currentPath.value = filePath;
      isPlaying.value = true;
      progress.value = 0.0;
      await _player.resume();
      debugPrint('【ChatVoice】播放: $filePath');
    } catch (e) {
      debugPrint('【ChatVoice】播放失败: $e');
      isPlaying.value = false;
      currentPath.value = null;
    }
  }

  /// 停止当前播放
  Future<void> stop() async {
    if (currentPath.value == null && !isPlaying.value) return;
    try {
      await _player.stop();
      debugPrint('【ChatVoice】停止');
    } catch (e) {
      debugPrint('【ChatVoice】停止失败: $e');
    }
    isPlaying.value = false;
    progress.value = 0.0;
    currentPath.value = null;
  }

  /// 检查指定路径是否正在播放
  bool isPlayingPath(String path) => currentPath.value == path && isPlaying.value;
}
