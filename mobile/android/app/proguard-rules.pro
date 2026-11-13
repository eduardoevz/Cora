# Proguard rules for Cora Mobile (Drift SQLite & Models)

# Preserve Flutter Wrapper and Plugin Registrant
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve SQLite3 C-bindings (sqlite3_flutter_libs & Drift)
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**
-keep class com.simonhmartin.drift.** { *; }
