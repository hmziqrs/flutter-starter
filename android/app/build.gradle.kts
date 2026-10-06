plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.starter"
    // flutter_local_notifications 23.x, permission_handler, and androidx.core
    // 1.19 all require API 37; Flutter 3.44.7's default is still 36.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications' AAR metadata requires core library
        // desugaring; the desugared JDK stubs backfill the java.time / java.util
        // APIs it uses on older API levels.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.starter"
        // Android 8.0 (API 26) floor: a modern starter baseline covering ~98%
        // of devices; every dependency accepts far less, so this is a choice,
        // not a requirement.
        minSdk = 26
        // API 36 is the Flutter 3.44 toolchain's validated target and meets
        // Google Play's current target-API policy; leave 37 for compile only
        // until the engine ships a 37 target recommendation.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
