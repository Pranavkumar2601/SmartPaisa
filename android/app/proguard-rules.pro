-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep SMS service classes
-keep class com.example.smartpaisaa.** { *; }

# Keep WorkManager classes
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger

# Keep notification classes
-keep class androidx.core.app.NotificationCompat** { *; }

# General Android optimizations
-dontwarn okio.**
-dontwarn retrofit2.**
-dontwarn rx.**

# Keep native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep SMS-related permissions and receivers
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Service
