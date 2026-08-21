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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some third-party plugins (e.g. screen_protector) ship with an internal
// mismatch between their Java and Kotlin compile targets under newer Kotlin
// Gradle Plugin versions. Force every subproject to the same JVM target so
// the build doesn't fail on plugin code we don't control.
// The app module already declares consistent Java/Kotlin targets itself
// (see android/app/build.gradle.kts) — only third-party plugin modules need
// this alignment, since some (e.g. screen_protector) ship with an internal
// mismatch under newer Kotlin Gradle Plugin versions.
subprojects {
    if (project.name == "app") return@subprojects
    val alignJvmTarget: () -> Unit = {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
    if (project.state.executed) alignJvmTarget() else afterEvaluate { alignJvmTarget() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
