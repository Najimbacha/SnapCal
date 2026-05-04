# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase Proguard Rules
-keep class com.google.firebase.** { *; }

# Hive Proguard Rules (Crucial for TypeAdapters)
-keep class * extends TypeAdapter { *; }
-keep class * implements TypeAdapter { *; }
-keep class com.snapcal.snapcal.data.models.** { *; }
-keep @hive.HiveType class * { *; }

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }

# Groq/Gemini Dio
-keep class com.snapcal.snapcal.data.services.** { *; }

# Ignore Play Core and GMS warnings
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**
