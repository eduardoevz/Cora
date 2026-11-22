import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val envStoreFile = System.getenv("CORA_UPLOAD_STORE_FILE")
val envKeyAlias = System.getenv("CORA_UPLOAD_KEY_ALIAS")
val envStorePassword = System.getenv("CORA_UPLOAD_STORE_PASSWORD")
val envKeyPassword = System.getenv("CORA_UPLOAD_KEY_PASSWORD")
val hasEnvSigning = !envStoreFile.isNullOrBlank() &&
    !envKeyAlias.isNullOrBlank() &&
    !envStorePassword.isNullOrBlank() &&
    !envKeyPassword.isNullOrBlank()
val hasReleaseSigning = keystorePropertiesFile.exists() || hasEnvSigning

android {
    namespace = "com.cora.health.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.cora.health.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            } else if (hasEnvSigning) {
                keyAlias = envKeyAlias
                keyPassword = envKeyPassword
                storeFile = rootProject.file(envStoreFile!!)
                storePassword = envStorePassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else if (project.hasProperty("requireReleaseSigning")) {
                throw GradleException(
                    "Production release signing requires mobile/android/key.properties or CORA_UPLOAD_* environment variables."
                )
            } else {
                logger.warn("WARNING: Signing release build with debug keystore (key.properties not found).")
                signingConfig = signingConfigs.getByName("debug")
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
