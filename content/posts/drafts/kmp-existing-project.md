---
layout: post
title:  "Introducing Kotlin Multiplatform in an existing project"
date:   2020-12-30
show_in_homepage: true
draft: true
tags: [Kotlin Multiplatform]
---

After discovering a new interesting technology or framework, you will probably start asking yourself how to integrate it in an existing project. That’s because, the possibility to start with a blank canvas is rare (not impossibile, but rare).

This is also the case for Kotlin Multiplatform (I’ll call it KMP in the rest of the article). 

When starting a new blank KMP project it is easier to have a mono-repo structure like this:

```
.
└── kmm-project
    ├── androidApp
    ├── iosApp
    └── shared
```

However existing projects most likely don’t have a mono-repo structure. And making a refactor to achieve this structure can be extremely difficult for time or management constraints. But Kotlin Multiplatform is built around the concept of sharing as much non-UI code as possible, and it is possibile to start sharing a little piece of tech stack. 

From where to start is really subjective and it depends on the specific project, but there are some part that better lend themselves to this topic. For example, all the code that is boring to write multiple times (constants, data models, DTOs, etc), because if is boring to write it is more error prone. Or could be a feature that centralizes the source of truth (i.e. if a field is nullable or not) because with a single source of truth there will also be a single point of failure. Or could be some utility or analytics helpers that every project have.

An important thing to take in mind is that all the features chosen for sharing must have the possibility to be extracted gradually. That’s because, during the evaluation process of KMP it is better to make a final decision without using too much time. For example, it is not a good idea to start sharing the entire network layer because you will risk to end up with a useless work if KMP is not the right solution for the project. Otherwise, starting with some small features like a DTO or a data model it will require less “extraction time” and it will leave enough time to work on the architecture needed to have a Kotlin Multiplatform library in an existing project.

For example, at [Uniwhere](https://www.uniwhere.com/) we have decided to start with some DTOs and after validating the process, we have migrated all the others.  

——- 

## Publishing


{{< figure src="/img/kmp-existing-projects/kmp-publish-arch.png"  link="/img/kmp-existing-project/kmp-publish-arch.png" >}}

### JVM

Android -> Maven Publish -> easy description
Backend -> Maven Publish -> easy description

Setup a Maven repository to share the artifacts

```kotlin
plugins {
    //...
    id("maven-publish")
}

group = "com.prof18.hn.foundation"
version = "1.0"

publishing {
    repositories {
        maven{
            credentials {
                username = "username"
                password = "pwd"
            }
            url = url("https://mymavenrepo.it")
        }
    }
}

```

`./gradlew publish`

Android
`implementation("com.prof18.hn.foundation:hn-foundation-android:1.0.0")`

JVM
`implementation("com.prof18.hn.foundation:hn-foundation-jvm:1.0.0")`

### iOs

iOs -> fat framework -> all the story. pack for XCode, etc.

Pack for Xcode

```kotlin
val packForXcode by tasks.creating(Sync::class) {
    group = "build"
    val mode = System.getenv("CONFIGURATION") ?: "DEBUG"
    val sdkName = System.getenv("SDK_NAME") ?: "iphonesimulator"
    val targetName = "ios" + if (sdkName.startsWith("iphoneos")) "Arm64" else "X64"
    val framework = kotlin.targets.getByName<KotlinNativeTarget>(targetName).binaries.getFramework(mode)
    inputs.property("mode", mode)
    dependsOn(framework.linkTask)
    val targetDir = File(buildDir, "xcode-frameworks")
    from({ framework.outputDirectory })
    into(targetDir)
}
tasks.getByName("build").dependsOn(packForXcode)

```

CocoaPod plugin
https://kotlinlang.org/docs/reference/native/cocoapods.html

```kotlin

plugins {
     kotlin("multiplatform") version "1.4.10"
     kotlin("native.cocoapods") version "1.4.10"
 }

 // CocoaPods requires the podspec to have a version.
 version = "1.0"
A
 kotlin {
     cocoapods {
         // Configure fields required by CocoaPods.
         summary = "Some description for a Kotlin/Native module"
         homepage = "Link to a Kotlin/Native module homepage"

         // You can change the name of the produced framework.
         // By default, it is the name of the Gradle project.
         frameworkName = "my_framework"
     }
 }

spec.pod_target_xcconfig = {
    'KOTLIN_TARGET[sdk=iphonesimulator*]' => 'ios_x64',
    'KOTLIN_TARGET[sdk=iphoneos*]' => 'ios_arm',
    'KOTLIN_TARGET[sdk=watchsimulator*]' => 'watchos_x86',
    'KOTLIN_TARGET[sdk=watchos*]' => 'watchos_arm',
    'KOTLIN_TARGET[sdk=appletvsimulator*]' => 'tvos_x64',
    'KOTLIN_TARGET[sdk=appletvos*]' => 'tvos_arm64',
    'KOTLIN_TARGET[sdk=macosx*]' => 'macos_x64'
}

spec.script_phases = [
    {
        :name => 'Build shared',
        :execution_position => :before_compile,
        :shell_path => '/bin/sh',
        :script => <<-SCRIPT
            set -ev
            REPO_ROOT="$PODS_TARGET_SRCROOT"
            "$REPO_ROOT/../gradlew" -p "$REPO_ROOT" :shared:syncFramework \
                -Pkotlin.native.cocoapods.target=$KOTLIN_TARGET \
                -Pkotlin.native.cocoapods.configuration=$CONFIGURATION \
                -Pkotlin.native.cocoapods.cflags="$OTHER_CFLAGS" \
                -Pkotlin.native.cocoapods.paths.headers="$HEADER_SEARCH_PATHS" \
                -Pkotlin.native.cocoapods.paths.frameworks="$FRAMEWORK_SEARCH_PATHS"
        SCRIPT
    }
]

```

Fat framework

Custom Gradle Task: universalFrameworkDebug

https://github.com/prof18/shared-hn-android-ios-backend/blob/master/hn-foundation/build.gradle.kts#L100

```kotlin
val libName = "HNFoundation"

tasks {
           register("universalFrameworkDebug", org.jetbrains.kotlin.gradle.tasks.FatFrameworkTask::class) {
            baseName = libName
            from(
                iosArm64().binaries.getFramework(libName, "Debug"),
                iosX64().binaries.getFramework(libName, "Debug")
            )
            destinationDir = buildDir.resolve("$rootDir/../../hn-foundation-cocoa")
            group = libName
            description = "Create the debug framework for iOs"
            dependsOn("linkHNFoundationDebugFrameworkIosArm64")
            dependsOn("linkHNFoundationDebugFrameworkIosX64")
        }

        register("universalFrameworkRelease", org.jetbrains.kotlin.gradle.tasks.FatFrameworkTask::class) {
            baseName = libName
            from(
                iosArm64().binaries.getFramework(libName, "Release"),
                iosX64().binaries.getFramework(libName, "Release")
            )
            destinationDir = buildDir.resolve("$rootDir/../../hn-foundation-cocoa")
            group = libName
            description = "Create the release framework for iOs"
            dependsOn("linkHNFoundationReleaseFrameworkIosArm64")
            dependsOn("linkHNFoundationReleaseFrameworkIosX64")
        }
}


```

pod spec
https://github.com/prof18/hn-foundation-cocoa/blob/master/HNFoundation.podspec

```ruby
Pod::Spec.new do |s|
# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #
s.name          = "HNFoundation"
s.version       = "1.0.0"
s.summary       = "HNFoundation KMP library"
s.homepage      = "https://github.com/prof18/hn-foundation-cocoa"
s.description   = "The framework of the HNFoundation library"
s.license       = "UNLICENSED"
s.author        = { "Marco Gomiero" => "mg@mail.it" }
s.platform      = :ios, "10.0"
s.ios.vendored_frameworks = 'HNFoundation.framework'
# s.swift_version = "4.1"
s.source        = { :git => "git@github.com:prof18/hn-foundation-cocoa.git", :tag => "#{s.version}" }
s.exclude_files = "Classes/Exclude"
end

```

Private cocoa pod repository
https://guides.cocoapods.org/making/private-cocoapods.html

Podfile XCode

```ruby
# For develop releases:
pod 'HNFoundation', :git => "git@github.com:prof18/hn-foundation-cocoa.git", :branch => 'develop'

# For stable releases
pod 'HNFoundation', :git => "git@github.com:prof18/hn-foundation-cocoa.git", :tag => '1.0.0'

```

Publish task

https://github.com/prof18/shared-hn-android-ios-backend/blob/master/hn-foundation/build.gradle.kts#L132

```kotlin 

val libName = "HNFoundation"

tasks {
 register("publishDevFramework") {
            description = "Publish iOs framweork to the Cocoa Repo"

            project.exec {
                workingDir = File("$rootDir/../../hn-foundation-cocoa")
                commandLine("git", "checkout", "develop").standardOutput
            }

            // Create Release Framework for Xcode
            dependsOn("universalFrameworkDebug")

            // Replace
            doLast {
                val dir = File("$rootDir/../../hn-foundation-cocoa/HNFoundation.podspec")
                val tempFile = File("$rootDir/../../hn-foundation-cocoa/HNFoundation.podspec.new")

                val reader = dir.bufferedReader()
                val writer = tempFile.bufferedWriter()
                var currentLine: String?

                while (reader.readLine().also { currLine -> currentLine = currLine } != null) {
                    if (currentLine?.startsWith("s.version") == true) {
                        writer.write("s.version       = \"${libVersionName}\"" + System.lineSeparator())
                    } else {
                        writer.write(currentLine + System.lineSeparator())
                    }
                }
                writer.close()
                reader.close()
                val successful = tempFile.renameTo(dir)

                if (successful) {

                    val dateFormatter = SimpleDateFormat("dd/MM/yyyy - HH:mm", Locale.getDefault())
                    project.exec {
                        workingDir = File("$rootDir/../../hn-foundation-cocoa")
                        commandLine(
                            "git",
                            "commit",
                            "-a",
                            "-m",
                            "\"New dev release: ${libVersionName}-${dateFormatter.format(Date())}\""
                        ).standardOutput
                    }

                    project.exec {
                        workingDir = File("$rootDir/../../hn-foundation-cocoa")
                        commandLine("git", "push", "origin", "develop").standardOutput
                    }
                }
            }
        }

        register("publishFramework") {
            description = "Publish iOs framework to the Cocoa Repo"

            project.exec {
                workingDir = File("$rootDir/../../hn-foundation-cocoa")
                commandLine("git", "checkout", "master").standardOutput
            }

            // Create Release Framework for Xcode
            dependsOn("universalFrameworkRelease")

            // Replace
            doLast {
                val dir = File("$rootDir/../../hn-foundation-cocoa/HNFoundation.podspec")
                val tempFile = File("$rootDir/../../hn-foundation-cocoa/HNFoundation.podspec.new")

                val reader = dir.bufferedReader()
                val writer = tempFile.bufferedWriter()
                var currentLine: String?

                while (reader.readLine().also { currLine -> currentLine = currLine } != null) {
                    if (currentLine?.startsWith("s.version") == true) {
                        writer.write("s.version       = \"${libVersionName}\"" + System.lineSeparator())
                    } else {
                        writer.write(currentLine + System.lineSeparator())
                    }
                }
                writer.close()
                reader.close()
                val successful = tempFile.renameTo(dir)

                if (successful) {

                    project.exec {
                        workingDir = File("$rootDir/../../hn-foundation-cocoa")
                        commandLine("git", "commit", "-a", "-m", "\"New release: ${libVersionName}\"").standardOutput
                    }

                    project.exec {
                        workingDir = File("$rootDir/../../hn-foundation-cocoa")
                        commandLine("git", "tag", libVersionName).standardOutput
                    }

                    project.exec {
                        workingDir = File("$rootDir/../../hn-foundation-cocoa")
                        commandLine("git", "push", "origin", "master", "--tags").standardOutput
                    }
                }
            }
        }
}

```


## Conclusions 

better to start little and then go bigger 

Start little then go bigger
 
We have validated the process with “little” effort
Now we can go bigger and share more “features”
For example the data layer → write SQL once for all


