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

However existing projects most likely don’t have a mono-repo structure. And making a refactor to achieve this structure can be extremely difficult for time or management constraints. But Kotlin Multiplatform is built around the concept of sharing as much non-UI code as possible, and it is possibile to start sharing a little piece of tech stack. Then, this “little piece of tech stack” will be served to the existing projects as a library. 

From where to start is really subjective and it depends on the specific project, but there are some part that better lend themselves to this topic. For example, all the code that is boring to write multiple times (constants, data models, DTOs, etc), because if is boring to write it is more error prone. Or could be a feature that centralizes the source of truth (i.e. if a field is nullable or not) because with a single source of truth there will also be a single point of failure. Or could be some utility or analytics helpers that every project have.

An important thing to take in mind is that all the features chosen for sharing must have the possibility to be extracted gradually. That’s because, during the evaluation process of KMP it is better to make a final decision without using too much time. For example, it is not a good idea to start sharing the entire network layer because you will risk to end up with a useless work if KMP is not the right solution for the project. Otherwise, starting with some small features like a DTO or a data model it will require less “extraction time” and it will leave enough time to work on the architecture needed to have a Kotlin Multiplatform library in an existing project.

For example, at [Uniwhere](https://www.uniwhere.com/) we have decided to start with some DTOs and after validating the process, we have migrated all the others.  

## Publishing Architecture

The architecture of an existing project with Kotlin Multiplatform will look like this:

{{< figure src="/img/kmp-existing-projects/kmp-publish-arch.png"  link="/img/kmp-existing-project/kmp-publish-arch.png" >}}

There is a repository for every platform:

- a repository for the KMP library;
- a repository for the Backend;
- a repository for the Android app;
- a repository for the iOs app. 

As mentioned early on, the KMP code is served as a library. The compiler generates a *.jar* for the JVM, an *.aar* for Android and a *Framework* for iOs. The *.jar* and the *.aar* can be published in a *Maven* repository. A *Framework* can be published in different places: for example in a *[CocoaPods](https://cocoapods.org/)* repository, in the [Swift Package Manager](https://swift.org/package-manager/) or with [Carthage](https://github.com/Carthage/Carthage). Since I’m familiar with CocoaPods (and because we are using it at Uniwhere), I’ve decided to stick with it.

### Publishing for Android and the JVM

The amount of work needed to publish a JVM and an Android library to Maven is pretty straightforward, thanks to the [Maven Publish Plugin](https://docs.gradle.org/current/userguide/publishing_maven.html). 
Only a few lines of configuration on the *build.gradle.kts* file are necessary (here I’m assuming that you have already configured a Maven repository since it’s not the scope of the article to explain how. Otherwise you can use a local Maven repository on your computer that does not required any kind of configuration):

```kotlin
plugins {
    //...
    id("maven-publish")
}

group = "<your-group-id>"
artifactId = "<your-library-name>" // If not specified, it will use the name of the project
version = "<version-name>"

// This block is only needed to publish on a online maven repo
publishing {
    repositories {
        maven{
            credentials {
                username = "<username>"
                password = "<pwd>"
            }
            url = url("https://mymavenrepo.com")
        }
    }
}

```

After that it is possible to build and publish the KMP library with the `./gradlew publish` command (or with `./gradlew publishToMavenLocal`). 

Then, it is possible to pull the library on Android:

```kotlin
implementation("<your-group-id>:<your-library-name>-android:<version-name>")
``` 

and on the JVM:

```kotlin
implementation("<your-group-id>:<your-library-name>-jvm:<version-name>")
``` 


### Publishing for iOs

> On iOs things are harder. 

#### Pack for Xcode

On newly created KMP projects, there is a gradle task, named **`packForXcode`**, that automatically builds the framework and place it in a specific build folder. 

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

This task is automatically called by Xcode when the iOs (or macOs) application is built.

{{< figure src="/img/kmp-existing-projects/build-script-xcode.png"  link="/img/kmp-existing-projects/build-script-xcode.png" >}}

The task uses the configuration of the iOs project to define the build mode and the target architecture.


```kotlin
val mode = System.getenv("CONFIGURATION") ?: "DEBUG"
val sdkName = System.getenv("SDK_NAME") ?: "iphonesimulator"
val targetName = "ios" + if (sdkName.startsWith("iphoneos")) "Arm64" else "X64"
```

The build mode can be `RELEASE` or `DEBUG` while the target name depends on the architecture which we are building for. The real devices use the *Arm64* architecture, while the simulator uses the host computer architecture which in most of the cases is *X64* (at least until when Apple Silicon is sufficiently spread). 

And this is the problem of this task!

Since then aim is to publish a framework to be used by an existing project, it’s impossible to know a priori which architecture is necessary or the build mode. 

#### CocoaPods Gradle Plugin

Another way to build a framework from the KMP code is using the [CocoaPods Gradle Plugin](https://kotlinlang.org/docs/reference/native/cocoapods.html). This plugin builds the framework and places it inside a CocoaPods repository that will be added as depencency on Xcode (The plugin can be used also to add other Pod libraries on the native target).

To start using the plugin, some configurations are necessary:

```kotlin
plugins {
     kotlin("multiplatform") version "1.4.10"
     kotlin("native.cocoapods") version "1.4.10"
 }

 // CocoaPods requires the podspec to have a version.
 version = "1.0"

 kotlin {
     cocoapods {
         // Configure fields required by CocoaPods.
         summary = "Some description for a Kotlin/Native module"
         homepage = "Link to a Kotlin/Native module homepage"

         // You can change the name of the produced framework.
         // By default, it is the name of the Gradle project.
         frameworkName = "<framework-name>"
     }
 }
```

Then, during the build the [Podspec file](https://guides.cocoapods.org/syntax/podspec.html) (a file that describes the Pod library - it contains name, version, and description, where the source should be fetched from, what files to use, the build settings to apply, etc) is generated starting from the informations provided in the `cocoapods` block. 

The Podspec contains also a script that is automatically added as a build script, called every time the iOs application is built, like `packForXcode`.

```ruby
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
Unfortunately this script has the same problems of `packForXcode`, because the configuration and the target architecture are computed during the build phase. 

```ruby
-Pkotlin.native.cocoapods.target=$KOTLIN_TARGET \
-Pkotlin.native.cocoapods.configuration=$CONFIGURATION \
```

So, also the CocoaPods Gradle Plugin can’t be used.


#### Fat Framework

The solution is to use a Fat Framework that contains the code for every required architecture. To build it, there is a gradle task named `FatFrameworkTask` that can be customized to meet the specific needs.  

The first step is building a custom gradle task to build a debug version of the Fat Framework.

```kotlin
tasks {
    register("universalFrameworkDebug", org.jetbrains.kotlin.gradle.tasks.FatFrameworkTask::class) {
        baseName = libName
        from(
            iosArm64().binaries.getFramework("<your-library-name>", "Debug"),
            iosX64().binaries.getFramework("<your-library-name>", "Debug")
        )
        destinationDir = buildDir.resolve("<fat-framework-destination>")
        group = "<your-library-name>"
        description = "Create the debug fat framework for iOs"
        dependsOn("link<your-library-name>DebugFrameworkIosArm64")
        dependsOn("link<your-library-name>DebugFrameworkIosX64")
    }
}        
```

This custom gradle task, named `universalFrameworkDebug` is necessary to provide some customizations to the `FatFrameworkTask`. After some cosmetic info, like the name and the group of the Framework, the required architectures and configurations must be provided. In this case, the required architectures are *x64* for the simulator and *arm64* for the real devices. The configuration instead is `Debug`.

```kotlin
from(
    iosArm64().binaries.getFramework("<your-library-name>", "Debug"),
    iosX64().binaries.getFramework("<your-library-name>", "Debug")
)
```

The last needed information is the destination of the framework. 


```kotlin
destinationDir = buildDir.resolve("<fat-framework-destination")
```

The destination will be a CocoaPods repository that at the end is a git repository that contains the framework, the debug symbols and a Podspec file. 

{{< figure src="/img/kmp-existing-projects/cocoa-repo-git.png"  link="/img/kmp-existing-projects/cocoa-repo-git.png" caption="An example of a CocoaPod repo hosted on a git repo" >}}

The git repository uses branches and tagging for handling debug and release versions. The debug versions of the Framework are pushed directly to the develop branch without any tagging. The release version instead is pushed on master and tagged. 

For more information about setting up a private CocoaPod repo, I suggest you give a look to the [official documentation](https://guides.cocoapods.org/making/private-cocoapods.html).

After pushing the changes on git, the Pod library is ready to be pulled by XCode. On the `Podfile` of the iOs project, is necessary to specify the Pod library with the informations about the source and the version. 

For debug releases, it is enough to specify to pull the latest version from the `develop` branch

```ruby
pod '<your-library-name>', :git => "git@github.com:<git-username>/<repo-name>.git", :branch => 'develop'
```

For production releases instead, it is better to specify the required version number.

```ruby
pod '<your-library-name>', :git => "git@github.com:<git-username>/<repo-name>.git", :tag => '<version-number>'
```

The last step is building another gradle task, to build a release version of the Fat Framework.

```kotlin
tasks {
    register("universalFrameworkRelease", org.jetbrains.kotlin.gradle.tasks.FatFrameworkTask::class) {
        baseName = libName
        from(
            iosArm64().binaries.getFramework("<your-library-name>", "Release"),
            iosX64().binaries.getFramework("<your-library-name>", "Release")
        )
        destinationDir = buildDir.resolve("<fat-framework-destination>")
        group = "<your-library-name>"
        description = "Create the debug fat framework for iOs"
        dependsOn("link<your-library-name>ReleaseFrameworkIosArm64")
        dependsOn("link<your-library-name>ReleaseFrameworkIosX64")
    }
}        
``` 

The script is basically the same of the previous one, with the exception that the target is changed from `Debug` to `Release`.

And that’s it! Finally it is possibile to start using the KMP library on iOs as well. 

—-

However there is room for improvement, blablabla....


——- 

### iOs

Publish task

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


