plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()

// 1. 기존 로컬 릴리즈용 설정 파일 경로 (유지)
val localReleasePropFile = rootProject.file("../../build/android/key.properties")
val hasLocalReleaseKeystore = localReleasePropFile.exists()

// 2. GitHub Actions 디버그용 설정 파일 경로 (추가)
val actionDebugPropFile = rootProject.file("key.properties")
val hasActionDebugKeystore = actionDebugPropFile.exists()

// 상황에 맞게 properties 로드
if (hasLocalReleaseKeystore) {
    keystoreProperties.load(FileInputStream(localReleasePropFile))
} else if (hasActionDebugKeystore) {
    keystoreProperties.load(FileInputStream(actionDebugPropFile))
} else {
    println("⚠️ [Warning] key.properties 파일을 찾을 수 없습니다. 서명이 실패할 수 있습니다.")
}

android {
    namespace = "com.toyapps.base.flutter_base"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.toyapps.base.flutter_base"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // 👇 [기존 유지] 파일이 있을 때만 release 서명 설정을 만듭니다.
        if (hasLocalReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
        
        // 👇 [추가] GitHub Actions용 디버그 서명 덮어쓰기
        if (hasActionDebugKeystore) {
            getByName("debug") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // 디버그 키스토어 파일 경로는 rootProject(android 폴더) 기준으로 찾습니다.
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) } 
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // 👇 [추가] 디버그 빌드에 덮어쓴 debug 서명 설정 적용
            if (hasActionDebugKeystore) {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
        
        release {
            // 👇 [기존 유지] 릴리즈 빌드 서명 및 최적화 설정
            if (hasLocalReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
            
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}