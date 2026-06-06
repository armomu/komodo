# Flutter Play Store Deferred Components - 项目未使用动态功能模块，忽略缺失类
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter 通用保留规则
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# 保留所有 Annotation
-keepattributes *Annotation*
