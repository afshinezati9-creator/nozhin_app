## Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

## local_auth / secure storage
-keep class androidx.biometric.** { *; }
-keep class com.google.crypto.** { *; }
-dontwarn com.google.crypto.**
