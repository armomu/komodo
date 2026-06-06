import 'package:get/get.dart';

class VideoFeedController extends GetxController {
  int currentPage = 0;

  /// Rx 响应式变量：feed 是否处于活跃（当前显示中的 tab）
  final RxBool isFeedActive = false.obs;

  void onPageChanged(int index) => currentPage = index;

  /// 通知 Feed 是否处于活跃状态（当前显示的 tab）
  void setFeedActive(bool active) {
    isFeedActive.value = active;
  }
}
