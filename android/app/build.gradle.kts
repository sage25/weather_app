import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
// Support key.properties located at project root or inside android/ (CI and local variations)
val candidateKeystoreFiles = listOf(rootProject.file("key.properties"), rootProject.file("android/key.properties"))
val keystorePropertiesFile = candidateKeystoreFiles.firstOrNull { it.exists() } ?: rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val storeFilePath = keystoreProperties.getProperty("storeFile")
val releaseKeystoreFile = storeFilePath?.let { File(rootProject.rootDir, it) }

val hasReleaseKeystore = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
).all { keystoreProperties.getProperty(it).isNullOrBlank().not() } && releaseKeystoreFile?.exists() == true

android {
    namespace = "com.example.weather_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = releaseKeystoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.weather_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use safe lookup: prefer `release` if present, otherwise fall back to `debug` if available.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.findByName("debug")
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
