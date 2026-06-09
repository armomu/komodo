class BaseUrl {
  static const String tokenKey = 'access_token';

  static bool inPrd = true;

  static String prodApiHost = 'http://192.168.1.38:8085';
  static String devApiHost = 'http://192.168.1.38:8085';

  // http·
  static String host() {
    return inPrd ? prodApiHost : devApiHost;
  }

  // ws
  static String msgWsHost() {
    return inPrd ? 'ws://192.168.1.38:8086' : 'ws://192.168.1.38:8086';
  }

  static String rtmpPush() {
    return inPrd
        ? 'rtmp://192.168.1.38:8000/live/stream'
        : "rtmp://192.168.1.38:1935/live/stream";
  }
}
