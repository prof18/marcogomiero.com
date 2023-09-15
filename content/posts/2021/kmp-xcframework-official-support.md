---
layout: post
title:  "Building an XCFramework on Kotlin Multiplatform from Kotlin 1.5.30"
date:   2021-08-30
show_in_homepage: true
---

{{< rawhtml >}}

<div class="post-award-container">
     <a href="https://mailchi.mp/kotlinweekly/kotlin-weekly-266"><img style="margin: 0px;" src="https://img.shields.io/badge/Featured%20in%20kotlinweekly.net-Issue%20%23266-%237874b4"/></a>
</div>

{{< /rawhtml >}}


A few days ago, [Kotlin 1.5.30 has been released](https://kotlinlang.org/docs/whatsnew1530.html). One of the features contained in the release is the official support for XCFrameworks on Kotlin Multiplatform.

[XCFramework](https://help.apple.com/xcode/mac/11.4/#/dev544efab96) is a binary that can contain multiple platform-specific variants (even for iOS and macOS at the same time). It has been introduced by Apple during the [WWDC 2019](https://developer.apple.com/videos/play/wwdc2019/416/) as a replacement for FatFrameworks.

Before Kotlin 1.5.30, an XCFramework could be created only by running the `xcrun` command that will pack the frameworks for every different required platform into an XCFramework.

A few weeks ago, I wrote [an article](https://www.marcogomiero.com/posts/2021/build-xcframework-kmp/) to show how to create two Gradle tasks (`buildDebugXCFramework` and `buildReleaseXCFramework`) to automate the building of an XCFramework. With Kotlin 1.5.30 these tasks are not necessary anymore and in this article, I will show you how to replace the custom tasks with the official ones.

## Build an XCFramework with Kotlin 1.5.30

To start using XCFrameworks, it is necessary to create an XCFramework object inside the `kotlin` block of the `build.gradle.kts` file. Then, every Apple target should be added to that object.

```kotlin
import org.jetbrains.kotlin.gradle.plugin.mpp.apple.XCFramework

val libName = “LibraryName”

kotlin {
    val xcFramework = XCFramework(libName)

    ios {
        binaries.framework(libName) {
            xcFramework.add(this)
        }
    }
    
    ...
}
```

After declaring the XCFramework object, three new tasks are added:

- assemble${libName}XCFramework
- assemble${libName}DebugXCFramework
- assemble${libName}ReleaseXCFramework

The first one will create both the release and the debug version of the XCFramework, while the others will create only the requested variant.

The XCFrameworks are located in the `XCFrameworks` folder inside the `build` folder. There will be a subfolder for each of the built variants.

```bash
.
├── build
    ├── XCFrameworks
        ├── debug
        │   └── LibraryName.xcframework
        └── release
            └── LibraryName.xcframework
```

## Publish an XCFramework

The newly built XCFramework can now be distributed. The distribution can be archived in different ways: for example in a *[CocoaPods](https://cocoapods.org/)* repository, in the [Swift Package Manager](https://swift.org/package-manager/) or with [Carthage](https://github.com/Carthage/Carthage). Since I’m familiar with CocoaPods, that’s what I’ve always used.

To make the publishing process as streamlined as possible, I’ve written a bunch of Gradle tasks to automatically build and publish through git the Debug and Release version of the XCFramework. For the details and to understand how the task works, I suggest you give a look at [this article](https://www.marcogomiero.com/posts/2021/kmp-existing-project/) that I wrote a few months ago. 

These tasks are the same used in [the article](https://www.marcogomiero.com/posts/2021/build-xcframework-kmp/) that I wrote a few weeks ago about XCFrameworks. But they must be updated, since the tasks to build the XCFramework are changed. 

**<ins>Publish Debug Version<ins>**:

```kotlin 
register("publishDevFramework") {
    description = "Publish iOs framework to the Cocoa Repo"

    project.exec {
        workingDir = File("$rootDir/../kmp-xcframework-dest")
        commandLine("git", "checkout", "develop").standardOutput
    }

    dependsOn("assemble${libName}DebugXCFramework")

    doLast {

        copy {
            from("$buildDir/XCFrameworks/debug")
            into("$rootDir/../kmp-xcframework-dest")
        }

        val dir = File("$rootDir/../kmp-xcframework-dest/$libName.podspec")
        val tempFile = File("$rootDir/../kmp-xcframework-dest/$libName.podspec.new")

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
                workingDir = File("$rootDir/../kmp-xcframework-dest")
                commandLine(
                    "git",
                    "add",
                    "."
                ).standardOutput
            }

            val dateFormatter = SimpleDateFormat("dd/MM/yyyy - HH:mm", Locale.getDefault())
            project.exec {
                workingDir = File("$rootDir/../kmp-xcframework-dest")
                commandLine(
                    "git",
                    "commit",
                    "-m",
                    "\"New dev release: ${libVersionName}-${dateFormatter.format(Date())}\""
                ).standardOutput
            }

            project.exec {
                workingDir = File("$rootDir/../kmp-xcframework-dest")
                commandLine("git", "push", "origin", "develop").standardOutput
            }
        }
    }
}
```

The task now depends on the `assemble${libName}DebugXCFramework` task, which is officially provided by Kotlin. Then, the only thing to do is to move the XCFramework from the `build` folder to the CocoaPod repository.

```kotlin
copy {
    from("$buildDir/XCFrameworks/debug")
    into("$rootDir/../kmp-xcframework-dest")
}
```

The task that publishes the release version of the XCFramework is pretty much the same as the debug one, except for the task to build the framework, that is `assemble${libName}ReleaseXCFramework`, and the location in the `build` folder:

```kotlin
register("publishFramework") {
    description = "Publish iOs framework to the Cocoa Repo"

    project.exec {
        workingDir = File("$rootDir/../kmp-xcframework-dest")
        commandLine("git", "checkout", "master").standardOutput
    }

    // Create Release Framework for Xcode
    dependsOn("assemble${libName}ReleaseXCFramework")

    // Replace
    doLast {

        copy {
            from("$buildDir/XCFrameworks/release")
            into("$rootDir/../kmp-xcframework-dest")
        }

        val dir = File("$rootDir/../kmp-xcframework-dest/$libName.podspec")
        val tempFile = File("$rootDir/../kmp-xcframework-dest/$libName.podspec.new")

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
                workingDir = File("$rootDir/../kmp-xcframework-dest")
                commandLine(
                    "git",
                    "add",
                    "."
                ).standardOutput
            }

            project.exec {
                workingDir = File("$rootDir/../kmp-xcframework-dest")
                commandLine("git", "commit", "-m", "\"New release: ${libVersionName}\"").standardOutput
            }

            project.exec {
                workingDir = File("$rootDir/../kmp-xcframework-dest")
                commandLine("git", "tag", libVersionName).standardOutput
            }

            project.exec {
                workingDir = File("$rootDir/../kmp-xcframework-dest")
                commandLine("git", "push", "origin", "master", "--tags").standardOutput
            }
        }
    }
}
```

And that’s it! With these little modifications, it is possible to use the official Kotlin support for XCFrameworks and automatically publish them in a CocoaPod repository.

On GitHub, I’ve updated the sample project with the new tasks on the [kotlin-1.5.30 branch](https://github.com/prof18/kmp-xcframework-sample/tree/kotlin-1.5.30). Instead, if you are interested in XCFramework support before Kotlin 1.5.30, you can look at the [pre-kotlin-1.5.30](https://github.com/prof18/kmp-xcframework-sample/tree/pre-kotlin-1.5.30) branch. And to see what are the changes between the two branches, you can look [at this commit](https://github.com/prof18/kmp-xcframework-sample/commit/18fb4ec0fad6ec2b058a2a543c0c1de914c0a0c9#diff-c0dfa6bc7a8685217f70a860145fbdf416d449eaff052fa28352c5cec1a98c06).
