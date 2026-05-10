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

# App Source Rules
-keep class com.snapcal.snapcal.** { *; }
-keep class com.snapcal.snapcal.data.models.** { *; }
-keep class com.snapcal.snapcal.data.services.** { *; }
-keep class com.snapcal.snapcal.providers.** { *; }
-keep class com.snapcal.snapcal.core.** { *; }

# Ignore Play Core and GMS warnings
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**
