import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releasePropertiesFile = rootProject.file("key.properties")
val releaseProperties = Properties()
if (releasePropertiesFile.exists()) {
    releasePropertiesFile.inputStream().use(releaseProperties::load)
}

val releaseBuildRequested =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("release", ignoreCase = true)
    }

val requiredReleaseProperties = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingReleaseProperties = requiredReleaseProperties.filter { key ->
    releaseProperties.getProperty(key).isNullOrBlank()
}
val releaseSigningConfigured =
    releasePropertiesFile.exists() && missingReleaseProperties.isEmpty()

if (releaseBuildRequested && !releasePropertiesFile.exists()) {
    throw GradleException(
        "Release signing is not configured. Copy key.properties.example to " +
            "key.properties and supply the private release values.",
    )
}

if (releaseBuildRequested && missingReleaseProperties.isNotEmpty()) {
    throw GradleException(
        "Release signing is missing: ${missingReleaseProperties.joinToString()}.",
    )
}

gradle.taskGraph.whenReady {
    val includesAppReleaseTask = allTasks.any { task ->
        task.path.startsWith(":app:") && task.name.contains("release", ignoreCase = true)
    }
    if (includesAppReleaseTask && !releasePropertiesFile.exists()) {
        throw GradleException(
            "Release signing is not configured. Copy key.properties.example to " +
                "key.properties and supply the private release values.",
        )
    }
    if (includesAppReleaseTask && missingReleaseProperties.isNotEmpty()) {
        throw GradleException(
            "Release signing is missing: ${missingReleaseProperties.joinToString()}.",
        )
    }
}

android {
    namespace = "com.chants.chants"
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
        applicationId = "com.chants.chants"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
                storeFile = file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
