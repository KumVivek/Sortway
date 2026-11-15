import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase is optional at build time: the Google Services and Crashlytics
// plugins are applied only once `flutterfire configure` has produced a
// google-services.json, so a fresh checkout still builds.
val hasGoogleServices = listOf(
    "google-services.json",
    "src/dev/google-services.json",
    "src/prod/google-services.json",
).any { file(it).exists() }
if (hasGoogleServices) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

// Release signing comes from android/key.properties (never committed).
val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

// Google's public sample AdMob app id. Set ADMOB_APP_ID_ANDROID in
// android/gradle.properties (or -P on the command line) for prod builds.
val sampleAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
val prodAdMobAppId =
    (project.findProperty("ADMOB_APP_ID_ANDROID") as String?) ?: sampleAdMobAppId

android {
    namespace = "com.flowsort.flow_sort"
    compileSdk = flutter.compileSdkVersion
    // Highest NDK the plugins ask for (they are backward compatible).
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.flowsort.flow_sort"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appName"] = "Flow Sort Dev"
            manifestPlaceholders["admobAppId"] = sampleAdMobAppId
        }
        create("prod") {
            dimension = "env"
            manifestPlaceholders["appName"] = "Flow Sort"
            manifestPlaceholders["admobAppId"] = prodAdMobAppId
        }
    }

    signingConfigs {
        if (keyProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to debug keys so `flutter run --release` works
            // before a keystore exists. Store uploads need key.properties.
            signingConfig =
                signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
