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

// Meta (Facebook) app events. The app id and client token are public
// identifiers that ship inside every APK (Meta designed the client token
// for that); the App Secret is never used in the app.
val metaAppId = secret("META_APP_ID") ?: "1108495851794971"
val metaClientToken = secret("META_CLIENT_TOKEN") ?: "c2c67631672a90cb0ab1486f7a49d6aa"

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
    namespace = "com.riseivo.arrow.escape.game"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // AGP 9 turns these off by default; flavors set their app name with
    // resValue.
    buildFeatures {
        resValues = true
        // BuildConfig.FLAVOR: MainActivity turns on Meta debug logs in dev.
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.riseivo.arrow.escape.game"
        // Firebase, Google Mobile Ads and the mediation adapters need 23+.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = testAdmobAppId
        resValue("string", "facebook_app_id", metaAppId)
        resValue("string", "facebook_client_token", metaClientToken)
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

dependencies {
    // Same SDK the facebook_app_events plugin uses; needed here only to
    // turn on Meta debug logging in dev builds (MainActivity).
    implementation("com.facebook.android:facebook-core:[19.0,20.0)")
}
