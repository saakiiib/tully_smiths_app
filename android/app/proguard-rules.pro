# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# GetX
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keepattributes Signature
-keepattributes *Annotation*

# HTTP
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Your app models - keep all data classes
-keep class com.tullysmiths.taskmanager.** { *; }

# Camera
-keep class androidx.camera.** { *; }

# Location
-keep class com.google.android.gms.location.** { *; }

# Photo Picker
-keep class androidx.activity.result.** { *; }
-keep class androidx.activity.result.contract.** { *; }

# Shared Preferences
-keep class androidx.datastore.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}