allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    if (project.name == "app") {
        // Keep app build dir under the main build dir so Flutter can find the APK
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    } else {
        // Use short path for plugin builds to avoid Windows MAX_PATH issues
        val shortBuildDir: Directory = layout.projectDirectory.dir("C:/tb_build")
        val newSubprojectBuildDir: Directory = shortBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
