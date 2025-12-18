## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

## Google Play Core (deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

## Drift (SQLite)
-keep class com.simolus.** { *; }
-keep class org.sqlite.** { *; }

## Gson (si se usa)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

## OkHttp y Retrofit (para las APIs)
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

## Seguridad
-keep class androidx.security.** { *; }

## Mantener clases de datos de Drift
-keep class * extends com.drift.** { *; }

## Evitar warnings de Kotlin
-dontwarn kotlin.**
-dontwarn kotlinx.**

## Mantener nombres de clases para debugging
-keepattributes SourceFile,LineNumberTable

## Optimizaciones
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

## Remover logs en release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
