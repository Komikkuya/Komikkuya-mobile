allprojects {
    repositories {
        google()
        mavenCentral()
        // Alternative mirrors for Maven Central (in case of 403 errors)
        maven { url = uri("https://repo1.maven.org/maven2/") }
        maven { url = uri("https://oss.sonatype.org/content/repositories/public/") }
        maven { url = uri("https://jitpack.io") }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
