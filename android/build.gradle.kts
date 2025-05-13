// build.gradle.kts (nivel raíz del proyecto)

buildscript {
    dependencies {
        // Plugin de Google Services para Firebase
        classpath("com.google.gms:google-services:4.4.0")
    }
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configuración personalizada del directorio build (usada por Flutter)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Flutter requiere esta dependencia entre proyectos
subprojects {
    project.evaluationDependsOn(":app")
}

// Tarea clean personalizada
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
