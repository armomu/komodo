allprojects {
    repositories {
        maven {
            url 'https://storage.flutter-io.cn/download.flutter.io'
        }
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/public' }
    }
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

allprojects {
    tasks.withType<org.gradle.jvm.tasks.Jar>().configureEach {
        duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    }
    tasks.withType<org.gradle.api.tasks.Copy>().configureEach {
        duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
