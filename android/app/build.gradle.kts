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

val storeFilePath = keystoreProperties.getProperty("storeFile")?.takeIf { it.isNotBlank() }
val storePassword = keystoreProperties.getProperty("storePassword")?.takeIf { it.isNotBlank() }
val keyAlias = keystoreProperties.getProperty("keyAlias")?.takeIf { it.isNotBlank() }
val keyPassword = keystoreProperties.getProperty("keyPassword")?.takeIf { it.isNotBlank() }
val releaseKeystoreFile = storeFilePath?.let { File(rootProject.rootDir, it) }

val hasReleaseKeystore =
    releaseKeystoreFile?.exists() == true &&
        storePassword != null &&
        keyAlias != null &&
        keyPassword != null

android {
    namespace = "com.example.weather_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = releaseKeystoreFile
                storePassword = storePassword
                keyAlias = keyAlias
                keyPassword = keyPassword
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
            // Prefer the release keystore when CI or local secrets provide it, otherwise use debug signing.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
