-keep class com.itfits.app.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

-keep class androidx.** { *; }
-dontwarn androidx.**

-keep class com.google.sign_in_with_apple.** { *; }
-keep class com.ittechai.flutter_image_compress.** { *; }
-keep class com.camerakit.** { *; }
-keep class io.flutter.plugins.camera.** { *; }

-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
