// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    compileSdk = 33 // Kotlin DSL用=赋值，而非Groovy的:
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8" // 字符串用双引号
    }

    defaultConfig {
        applicationId = "com.yourpackage.triggeo" // 替换为你的实际包名
        minSdk = 21
        targetSdk = 33
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") { // Kotlin DSL用getByName获取构建类型
            signingConfig = signingConfigs.getByName("debug") // 测试用debug签名，正式发布需替换
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    // 引用根项目的kotlin_version
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:${rootProject.extra["kotlin_version"]}")
}

flutter {
    source = file("../..")
}