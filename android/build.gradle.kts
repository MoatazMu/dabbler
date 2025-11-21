allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileSdkVersion(36)
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    project.pluginManager.withPlugin("com.android.library") {
        project.extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileSdk = 36
        }
    }
    project.pluginManager.withPlugin("com.android.application") {
        project.extensions.configure<com.android.build.gradle.AppExtension> {
            compileSdkVersion(36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
