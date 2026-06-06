import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'video_data.dart';
import 'video_feed_controller.dart';
import 'video_page.dart';
import 'visibility_detector.dart';

export 'video_feed_controller.dart';

class VideoFeedView extends StatefulWidget {
  final VideoFeedController controller;
  final int tabIndex;

  const VideoFeedView({
    required this.controller,
    required this.tabIndex,
    super.key,
  });

  @override
  State<VideoFeedView> createState() => _VideoFeedViewState();
}

class _VideoFeedViewState extends State<VideoFeedView>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  bool _isViewVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.controller.currentPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(WidgetVisibilityInfo info) {
    final visible = info.visibleFraction > 0.1;
    if (visible != _isViewVisible) {
      setState(() {
        _isViewVisible = visible;
      });
    }
  }

  @override
  void didUpdateWidget(covariant VideoFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videoList.length,
        onPageChanged: (index) {
          widget.controller.onPageChanged(index);
          setState(() {});
        },
        itemBuilder: (context, index) {
          return Obx(() {
            final active =
                widget.controller.isFeedActive.value &&
                (index == widget.controller.currentPage);
            return VideoPage(
              key: ValueKey('video_$index'),
              data: videoList[index],
              isActive: active,
              lazyLoad: !_isViewVisible,
            );
          });
        },
      ),
    );
  }
}
