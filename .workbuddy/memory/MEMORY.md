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
