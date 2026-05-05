# HybridArt 项目长期记忆

## 项目概况
- Flutter 多模块混合应用：短视频 + RTMP直播 + 蓝牙充电桩管理(IoT)
- 技术栈：Flutter + GetX全家桶 + video_player + flutter_vlc_player + flutter_blue_plus
- 架构：5 Tab底部导航（首页/短视频/+/消息/我的），各Tab独立Scaffold

## 关键技术决策
- 短视频：video_player，抖音风格竖向PageView，关注/精选共享Feed控制器
- 直播：flutter_vlc_player播放RTMP流，带聊天互动Tab
- 充电桩：flutter_blue_plus BLE，Mock/真实双模式设计
- 主题：Material 3浅色/深色，GetStorage持久化
- Tab懒加载：Offstage + 懒创建策略
- **音乐播放器**：just_audio + just_audio_background，全局单例 `Get.put(permanent:true)`，系统通知/锁屏/控制中心通过 `MediaItem(id/title/artist/artUri)` 传递歌曲信息

## 构建配置
- minSdkVersion 21 (flutter_blue_plus要求)
- Android Maven: 阿里云镜像加速
- 应用ID: com.example.hybridart (待替换)

## UI设计特点
- 音乐tab采用深色主题设计
- 使用card_swiper实现堆叠轮播卡片效果
- 新增音乐歌词卡片组件，包含：
  - 黑色主题卡片
  - 歌曲信息行（绿色音乐图标 + 歌曲信息 + 歌手头像）
  - 歌词展示区域
- 卡片包含细致的分割线和层次感设计
- 适配深色主题的透明度控制

## 技术问题与解决
### Swiper高度约束问题
- **问题1**：Horizontal viewport was given unbounded height错误
  - **原因**：Swiper在Column(mainAxisSize: MainAxisSize.min)中无法获得足够高度约束
  - **解决方案**：用SizedBox包裹Swiper并指定明确高度
  - **代码示例**：`SizedBox(height: 220, child: Swiper(...))`

- **问题2**：Null check operator used on a null value和RenderBox布局错误
  - **原因分析**：
    1. ListView中的Swiper缺乏明确的高度约束
    2. Swiper的itemHeight参数与实际项目高度不匹配
    3. Column的mainAxisSize: min导致尺寸计算冲突
    4. 复杂的尺寸计算造成不一致
  - **解决方案**：
    1. 为所有Swiper提供明确的父容器高度约束
    2. 统一Swiper的itemHeight与实际项目高度
    3. 将Column的mainAxisSize从min改为max避免冲突
    4. 简化尺寸计算，使用固定值代替复杂计算
  - **代码示例**：
    ```dart
    // 堆叠轮播卡片
    SizedBox(
      height: itemHeight + 40,
      child: Swiper(
        itemHeight: itemHeight,
        ...
      ),
    )
    
    // 音乐歌词卡片
    SizedBox(
      height: 200,
      child: Swiper(
        itemHeight: 180, // 与项目高度一致
        ...
      ),
    )
    ```

- **核心经验**：
  1. 在ListView/Column等可滚动容器中使用Swiper时，必须用SizedBox提供明确高度约束
  2. Swiper的itemHeight参数必须与实际渲染的项目高度完全一致
  3. 避免在复杂布局中使用mainAxisSize: MainAxisSize.min与Swiper组合
  4. 优先使用简单、明确的尺寸值，避免动态计算导致的布局冲突
  5. 对于card_swiper组件，需要同时考虑itemHeight和包裹容器的高度

- **文件位置**：lib/pages/home/tabs/music_tab.dart
- **修复时间**：2026-04-27

## UI更新记录
### ProfileTab 新设计 (2026-04-28)
- **参考设计**：Oliver Nicolai 个人资料页面
- **实现特点**：
  - SliverAppBar 顶部区域，蓝色渐变背景配地图纹理图案
  - 圆形头像 + 蓝色加号徽章
  - 用户名、位置、粉丝/关注数据展示
  - 深绿色 Follow 按钮
  - 两个统计卡片（Activities / Saved）
  - 横向 Tab 导航（Feed, Photos, Reviews, Activities）
  - 动态列表展示活动内容
- **文件位置**：lib/pages/home/tabs/profile_tab.dart