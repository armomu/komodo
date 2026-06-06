// import 'dart:convert';

class EventBus {
  static final _singleton = EventBus._internal();
  factory EventBus() => _singleton;
  EventBus._internal();

  final Map<String, List<Function>> _channels = {};

  void on(String eventType, Function handler) {
    _channels.putIfAbsent(eventType, () => []).add(handler);
  }

  void emit(String eventType, dynamic data) {
    _channels[eventType]?.forEach((handler) => handler(data));
  }

  void off(String eventType, Function handler) {
    _channels[eventType]?.remove(handler);
  }

  // 处理接收消息
  // void _onData(dynamic strData) {
  //   final json = jsonDecode(strData as String);
  //   final type = json['type'] as String;
  //   final data = json['data'];

  //   // 分发给特定频道的订阅者
  //   _channels[type]?.forEach((handler) {
  //     try {
  //       handler(data);
  //     } catch (e) {
  //       debugPrint('Handler error for $type: $e');
  //     }
  //   });
  // }

  void dispose() {}
}
