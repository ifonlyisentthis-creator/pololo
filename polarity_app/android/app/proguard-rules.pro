# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Mobile Ads / AdMob
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Google Play Games Services
-keep class com.google.android.gms.games.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-dontwarn com.google.android.gms.**

# Google UMP (User Messaging Platform)
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.ump.**

# In-App Billing
-keep class com.android.vending.billing.** { *; }

# Google Play Core (deferred components, split install)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Prevent obfuscation of types referenced in Kotlin metadata
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }

# Flutter
-dontwarn io.flutter.embedding.**
