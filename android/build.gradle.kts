plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.syg.syg_materiales_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ CAMBIO: Subimos a Java 17 para evitar warnings de "obsolete"
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // ✅ CAMBIO: Coincidir con la versión de Java de arriba
        jvmTarget = "17"
    }

    flavorDimensions += listOf("env")

    productFlavors {
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "S&G Materiales")
        }

        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "S&G Dev")
        }
    }

    defaultConfig {
        applicationId = "com.syg.syg_materiales_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ IMPORTANTE: Habilitar multidex si no está
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Mantener desugaring para soporte de APIs nuevas en Android viejos
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}