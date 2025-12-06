allprojects {
    repositories {
        // maven("https://jitpack.io")
        // maven("https://maven.aliyun.com/repository/release")
        // maven("https://maven.aliyun.com/repository/google")
        // maven("https://maven.aliyun.com/repository/central")
        // maven("https://maven.aliyun.com/repository/gradle-plugin")
        // maven("https://maven.aliyun.com/repository/public")
        maven("https://repo.huaweicloud.com/repository/maven/")
        google()
        mavenCentral()
    }
}

android {
    ndkVersion.set("27.0.12077973") // 注意这里使用 .set()
    // ... 其他现有配置
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
