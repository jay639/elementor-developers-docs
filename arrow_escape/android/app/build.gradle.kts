import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing and per-environment ids live in android/key.properties,
// which is git-ignored (see README). Environment variables work too (CI).
val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun secret(name: String): String? = keyProperties.getProperty(name) ?: System.getenv(name)

// Google's public test app id; real ids come from key.properties / env.
val testAdmobAppId = "ca-app-pub-3940256099942544~3347511713"

// Firebase is optional: without google-services.json the app runs offline.
val hasGoogleServices = listOf(
    "google-services.json",
    "src/dev/google-services.json",
    "src/prod/google-services.json",
).any { file(it).exists() }
if (hasGoogleServices) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

android {
    namespace = "com.arrowescape.arrow_escape"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // AGP 9 turns these off by default; flavors set their app name with
    // resValue.
    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.arrowescape.arrow_escape"
        // Firebase, Google Mobile Ads and the mediation adapters need 23+.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = testAdmobAppId
    }

    signingConfigs {
        create("release") {
            val storeFilePath = secret("ANDROID_KEYSTORE_PATH")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = secret("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = secret("ANDROID_KEY_ALIAS")
                keyPassword = secret("ANDROID_KEY_PASSWORD")
            }
        }
    }

    // flutter run --flavor dev -t lib/main_dev.dart
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Arrow Escape Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Arrow Escape")
            manifestPlaceholders["admobAppId"] =
                secret("ADMOB_APP_ID_ANDROID") ?: testAdmobAppId
        }
    }

    buildTypes {
        release {
            // Falls back to debug signing so `flutter build apk` works on a
            // fresh checkout; store builds must provide key.properties.
            signingConfig = if (secret("ANDROID_KEYSTORE_PATH") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
