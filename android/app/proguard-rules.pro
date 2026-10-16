# Flutter wrapper keeps
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play services (used by google_sign_in)
-keep class com.google.android.gms.** { *; }

# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Play Core (referenced by Flutter deferred components, not bundled)
-dontwarn com.google.android.play.core.**
