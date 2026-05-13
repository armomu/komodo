/// 通话状态
enum CallState {
  /// 空闲
  idle,

  /// 呼叫中（正在给对端发 offer）
  calling,

  /// 收到来电（收到对端 offer）
  incoming,

  /// 正在连接（交换 ICE）
  connecting,

  /// 已连接（视频通话中）
  connected,

  /// 已挂断
  ended,

  /// 错误
  error,
}
