plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dabbler.dabblerapp"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.dabbler.dabblerapp"
        minSdk = flutter.minSdkVersion
        targetSdk = 35  // or 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    signingConfigs {
        create("release") {
            storeFile = file("upload-keystore.jks")
            storePassword = "mo3taz51024."
            keyAlias = "upload"
            keyPassword = "mo3taz51024."
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
