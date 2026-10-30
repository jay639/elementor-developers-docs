# R8 rules for release builds. Most plugins ship consumer rules; these cover
# reflection-heavy SDKs whose rules have been incomplete in the past.

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Google Mobile Ads + mediation adapters
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.mediation.** { *; }
-keep class com.applovin.** { *; }
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-keep class com.facebook.ads.** { *; }
-keep class com.ironsource.** { *; }
-keep class com.unity3d.mediation.** { *; }
-dontwarn com.applovin.**
-dontwarn com.facebook.ads.**
-dontwarn com.ironsource.**
-dontwarn com.unity3d.**

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }

# Play Core (deferred components referenced by the Flutter embedding)
-dontwarn com.google.android.play.core.**

# Keep crash stack traces readable after de-obfuscation (Crashlytics)
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
