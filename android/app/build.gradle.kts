plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.syg.syg_materiales_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    productFlavors {
        create("dev") {
            // Define el ApplicationId para el entorno de desarrollo
            applicationIdSuffix = ".dev"
            // El ID final será com.syg.syg_materiales_flutter.dev
            // NOTA: Esto debe coincidir con el que registrarás en Firebase (Paso 1.1)
        }
        create("prod")
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    // INICIO CONFIGURACIÓN FLAVORS
    flavorDimensions += listOf("env")

    productFlavors {
        create("prod") {
            dimension = "env"
            // Hereda el ID original. Busca credenciales en src/prod/
            resValue("string", "app_name", "S&G Materiales")
        }
        create("dev") {
            dimension = "env"
            // Agrega .dev al ID. Busca credenciales en src/dev/
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "S&G Dev")
        }
    }
// FIN CONFIGURACIÓN FLAVORS

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.syg.syg_materiales_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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

flutter {
    source = "../.."
}
