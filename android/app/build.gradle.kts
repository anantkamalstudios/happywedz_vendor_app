import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.happy.happy_weds_vendors"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.happy.happy_weds_vendors"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 14
        versionName = "1.0.13"

        // Google Maps key comes from the gitignored key.properties rather than
        // living in AndroidManifest.xml, so it is not committed to the repo.
        // NOTE: it is still embedded in the built APK — that is unavoidable for
        // the Maps SDK. Restrict the key by package name + SHA-1 in Google
        // Cloud Console; that, not hiding it, is what stops misuse.
        manifestPlaceholders["MAPS_API_KEY"] =
            (keystoreProperties["MAPS_API_KEY"] as String?) ?: ""
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
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
