---
layout: post
title:  "How to build an XCFramework on Kotlin Multiplatform"
date:   2021-07-14
show_in_homepage: false
image: "/img/kmp-existing-projects/kmp-publish-arch.png"
---

{{< rawhtml >}}

<div id="banner" style="overflow: hidden;justify-content:space-around;">

    <div style="display: inline-block;margin-right: 10px;">
        <a href="https://androidweekly.net/issues/issue-475"><img style="margin: 0px;" src="https://androidweekly.net/issues/issue-475/badge" /></a>
    </div>

    <div style="display: inline-block;">
     <a href="https://mailchi.mp/kotlinweekly/kotlin-weekly-259"><img style="margin: 0px;" src="https://img.shields.io/badge/Featured%20in%20kotlinweekly.net-Issue%20%23259-%237874b4"/></a>
        
    </div>
</div>

{{< /rawhtml >}}

When you start integrating Kotlin Multiplatform (I’ll call it KMP in the rest of the article) in an existing project you most likely don’t have a mono-repo structure (and making a refactor to achieve this kind of architecture will not be easy). An example of architecture is the following, with a repository for every platform.  

{{< figure src="/img/kmp-existing-projects/kmp-publish-arch.png"  link="/img/kmp-existing-project/kmp-publish-arch.png" >}}

> To understand how to integrate KMP into existing code, give a look at my previous article: [“Introducing Kotlin Multiplatform in an existing project”](https://www.marcogomiero.com/posts/2021/kmp-existing-project/)

KMP code will be served as a library: the compiler generates a .jar for the JVM, a .aar for Android, and a Framework for iOS. 

For iOS, the Framework will be a FatFramework, because it is necessary to have in the same package the architecture for the simulator and the real device. In [a past article](https://www.marcogomiero.com/posts/2021/kmp-existing-project/), I’ve explained how to generate a FatFramework and how to distribute it in a CocoaPod repo. It is possible with some Gradle tasks or with the [KMP FatFramework Cocoa](https://github.com/prof18/kmp-fatframework-cocoa) Gradle plugin that I wrote.

However, FatFrameworks seems not to be the “current state of the art” solution to distribute multiple architectures at the same time. In fact, Apple during [WWDC 2019](https://developer.apple.com/videos/play/wwdc2019/416/) has introduced [XCFramework](https://help.apple.com/xcode/mac/11.4/#/dev544efab96), a binary that can contain multiple platform-specific variants (even for iOS and macOS at the same time). 

Apple is pushing toward the use of XCFrameworks and you could encounter errors like the following one that happened to [Sam Edwards](https://twitter.com/handstandsam).

{{< tweet 1403456462689550345 >}}

Sam [followed the same approach](https://handstandsam.com/2021/06/11/kotlin-multiplatform-building-a-fat-ios-framework-for-iosarm64-and-iosx64/) I’ve followed but I never encounter the error! And the reason could be the following:

{{< tweet 1403673057487687682 >}}

Unfortunately, there isn’t native support for XCFrameworks on Kotlin Multiplatform yet (it should come hopefully with Kotlin 1.5.30) and to generate an XCFramework, you have to create manually an XCFramework starting from the different frameworks built by KMP.

> From Kotlin 1.5.30, XCFrameworks are officialy supported. I wrote another article on how to replace the custom gradle tasks, that are showcased below, with the official ones. [Building an XCFramework on Kotlin Multiplatform from Kotlin 1.5.30](https://www.marcogomiero.com/posts/2021/kmp-xcframework-official-support.md/).

```bash
xcrun xcodebuild -create-xcframework \
    -framework /path/to/device.framework \
    -debug-symbols /path/to/device.DSYM \
    -framework /path/to/simulator.framework \
    -debug-symbols /path/to/simulator.DSYM \
    -output frameworkName.xcframework
```

This is a boring thing to do manually every time, so there’s room for some scripting. 

The first step is building a custom Gradle task, named `buildDebugXCFramework` to build a debug version of the XCFramework. 

```kotlin
val libName = “LibraryName”
 
register("buildDebugXCFramework", Exec::class.java) {
    description = "Create a Debug XCFramework"

    dependsOn("link${libName}DebugFrameworkIosArm64")
    dependsOn("link${libName}DebugFrameworkIosX64")

    val arm64FrameworkPath = "$rootDir/build/bin/iosArm64/${libName}DebugFramework/${libName}.framework"
    val arm64DebugSymbolsPath = "$rootDir/build/bin/iosArm64/${libName}DebugFramework/${libName}.framework.dSYM"

    val x64FrameworkPath = "$rootDir/build/bin/iosX64/${libName}DebugFramework/${libName}.framework"
    val x64DebugSymbolsPath = "$rootDir/build/bin/iosX64/${libName}DebugFramework/${libName}.framework.dSYM"

    val xcFrameworkDest = File("$rootDir/../kmp-xcframework-dest/$libName.xcframework")
    executable = "xcodebuild"
    args(mutableListOf<String>().apply {
        add("-create-xcframework")
        add("-output")
        add(xcFrameworkDest.path)

        // Real Device
        add("-framework")
        add(arm64FrameworkPath)
        add("-debug-symbols")
        add(arm64DebugSymbolsPath)

        // Simulator
        add("-framework")
        add(x64FrameworkPath)
        add("-debug-symbols")
        add(x64DebugSymbolsPath)
    })

    doFirst {
        xcFrameworkDest.deleteRecursively()
    }
}
```

The first thing to do is building the frameworks for the required architectures: arm64 for the “real” device and X64 for the simulator. The build process can be triggered with the `link` task, in this case for the `Debug` variant of the framework.  

```kotlin
dependsOn("link${libName}DebugFrameworkIosArm64")
dependsOn("link${libName}DebugFrameworkIosX64")
```

The frameworks will be saved in the `build/bin` folder of the project:

```bash
build
└── bin
    ├── iosArm64
    │   ├── LibraryNameDebugFramework
    │   │   ├── LibraryName.framework
    │   │   └── LibraryName.framework.dSYM
    └── iosX64
        ├── LibraryNameDebugFramework
        │   ├── LibraryName.framework
        │   └── LibraryName.framework.dSYM
```

At this point, it is necessary to provide to the task all the parameters required by `xcodebuild` command. 

```kotlin
executable = "xcodebuild"
args(mutableListOf<String>().apply {
    add("-create-xcframework")
    add("-output")
    …
}    
```

Before executing the task, it’s better to clear the files inside the XCFramework destination, because the `xcodebuild` command will not replace the old artifacts. 

```kotlin
doFirst {
    xcFrameworkDest.deleteRecursively()
}
```

And that’s it! Now there is a Debug XCFramework ready to be distributed.

The steps required to build a Release version of the framework are very similar. 

First of all, it is necessary to build the frameworks for both the required architectures:

```kotlin
 dependsOn("link${libName}ReleaseFrameworkIosArm64")
 dependsOn("link${libName}ReleaseFrameworkIosX64")
```

The frameworks will be saved in the `build/bin` folder like for the Debug version:

```bash
build
└── bin
    ├── iosArm64
    │   └── LibraryNameReleaseFramework
    │       ├── LibraryName.framework
    │       └── LibraryName.framework.dSYM
    └── iosX64
        └── LibraryNameReleaseFramework
            ├── LibraryName.framework
            └── LibraryName.framework.dSYM
```

The parameters for the `xcodebuild` command will be the same, except for the path. 

```kotlin
 register("buildReleaseXCFramework", Exec::class.java) {
    description = "Create a Release XCFramework"

    dependsOn("link${libName}ReleaseFrameworkIosArm64")
    dependsOn("link${libName}ReleaseFrameworkIosX64")

    val arm64FrameworkPath = "$rootDir/build/bin/iosArm64/${libName}ReleaseFramework/${libName}.framework"
    val arm64DebugSymbolsPath =
        "$rootDir/build/bin/iosArm64/${libName}ReleaseFramework/${libName}.framework.dSYM"

    val x64FrameworkPath = "$rootDir/build/bin/iosX64/${libName}ReleaseFramework/${libName}.framework"
    val x64DebugSymbolsPath = "$rootDir/build/bin/iosX64/${libName}ReleaseFramework/${libName}.framework.dSYM"

    val xcFrameworkDest = File("$rootDir/../kmp-xcframework-dest/$libName.xcframework")
    executable = "xcodebuild"
    args(mutableListOf<String>().apply {
        add("-create-xcframework")
        add("-output")
        add(xcFrameworkDest.path)

        // Real Device
        add("-framework")
        add(arm64FrameworkPath)
        add("-debug-symbols")
        add(arm64DebugSymbolsPath)

        // Simulator
        add("-framework")
        add(x64FrameworkPath)
        add("-debug-symbols")
        add(x64DebugSymbolsPath)
    })

    doFirst {
        xcFrameworkDest.deleteRecursively()
    }
}
```

The newly built XCFramework can now be distributed. The distribution can be archived in different ways: for example in a *[CocoaPods](https://cocoapods.org/)* repository, in the [Swift Package Manager](https://swift.org/package-manager/) or with [Carthage](https://github.com/Carthage/Carthage). Since I’m familiar with CocoaPods, that’s what I’m using.

To make the publishing process as streamlined as possible, I’ve written a bunch of Gradle tasks to automatically build and publish through git the Debug and Release version of the XCFramework. For the details and to understand how the task works, I suggest you give a look at [this article](https://www.marcogomiero.com/posts/2021/kmp-existing-project/) that I wrote a few months ago. 

**<ins>Publish Debug Version<ins>**:

```kotlin
register("publishDevFramework") {
    description = "Publish Debug XCFramework to the Cocoa Repo"

    project.exec {
        workingDir = File("$rootDir/../kmp-xcframework-dest")
        commandLine("git", "checkout", "develop").standardOutput
    }

    dependsOn("buildDebugXCFramework")
    
    doLast {
        val dir = File("<framework-destination>/<your-library-name>.podspec")
        val tempFile = File("<framework-destination>/<your-library-name>.podspec.new")

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
                workingDir = File("<framework-destination>")
                commandLine("git", "commit", "-a", "-m", "\"New dev release: ${libVersionName}-${dateFormatter.format(Date())}\"").standardOutput
            }

            project.exec {
                workingDir = File("<framework-destination>")
                commandLine("git", "push", "origin", "develop").standardOutput
            }
        }
    }
}
```

**<ins>Publish Release Version<ins>**:

```kotlin
register("publishFramework") {
    description = "Publish Release XCFramework to the Cocoa Repo"

    project.exec {
        workingDir = File("$rootDir/../kmp-xcframework-dest")
        commandLine("git", "checkout", "master").standardOutput
    }
    dependsOn("buildReleaseXCFramework")
    
    doLast {
        val dir = File("<framework-destination>/<your-library-name>.podspec")
        val tempFile = File("<framework-destination>/<your-library-name>.podspec.new")

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
                workingDir = File("<framework-destination>")
                commandLine("git", "commit", "-a", "-m", "\"New release: ${libVersionName}\"").standardOutput
            }

            project.exec {
                workingDir = File("<framework-destination>")
                commandLine("git", "tag", libVersionName).standardOutput
            }

            project.exec {
                workingDir = File("<framework-destination>")
                commandLine("git", "push", "origin", "master", "--tags").standardOutput
            }
        }
    }
}
```

All the tasks mentioned in the article are available in the [KMP FatFramework Cocoa Gradle plugin](https://github.com/prof18/kmp-fatframework-cocoa) that I wrote. The support for XCFrameworks has been added since [version 0.2.1](https://github.com/prof18/kmp-fatframework-cocoa/releases/tag/0.2.1).

On GitHub, I’ve published [a sample project](https://github.com/prof18/kmp-xcframework-sample) to showcase the usage of the task. In the [pre-kotlin-1.5.30](https://github.com/prof18/kmp-xcframework-sample/tree/pre-kotlin-1.5.30) branch the tasks are manually added in the [build.gradle.kts](https://github.com/prof18/kmp-xcframework-sample/blob/pre-kotlin-1.5.30/build.gradle.kts) file. In the [pre-kotlin-1.5.30-with-plugin](https://github.com/prof18/kmp-xcframework-sample/tree/pre-kotlin-1.5.30-with-plugin) branch instead, the KMP FatFramework Cocoa plugin is used. 

You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when there will be some update of the plugin (and this is a spoiler! :))

{{< smalltext >}} 
// Thanks to <a href="https://twitter.com/handstandsam">Sam Edwards</a> for mentioning my article and “trigger” the creation of this one.
{{< /smalltext >}}
