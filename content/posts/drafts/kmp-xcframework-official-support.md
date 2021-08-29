---
layout: post
title:  "Building an XCFramework on Kotlin Multiplatform from Kotlin 1.5.30"
date:   2021-08-28
show_in_homepage: true
draft: true
---

A few days ago, [Kotlin 1.5.30 has been released](https://kotlinlang.org/docs/whatsnew1530.html). One of the features contained in this release is the official support for XCFramework on Kotlin Multiplatform. 

[XCFramework](https://help.apple.com/xcode/mac/11.4/#/dev544efab96) is a binary that can contain multiple platform-specific variants (even for iOS and macOS at the same time). It has been introduced by Apple during the [WWDC 2019](https://developer.apple.com/videos/play/wwdc2019/416/) as a replacement for FatFrameworks.

Before Kotlin 1.5.30, an XCFramework could be created only by running the `xcrun` command that will pack the frameworks for every different required platform into an XCFramework. 

A few weeks ago, I wrote [an article](https://www.marcogomiero.com/posts/2021/build-xcframework-kmp/) to show how to build two Gradle task (`buildDebugXCFramework` and `buildReleaseXCFramework`) to automate the building of an XCFramework. With Kotlin 1.5.30 these tasks are not necessary anymore and in this article I will show you how to replace the custom task with the official one.

To start using XCFrameworks, it is necessary to create an XCFramework object inside the `kotlin` block of the `build.gradle.kts` file. Then, every Apple target should be added in that object.

```kotlin
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





---

New task added:

- assemble${libName}XCFramework
- assemble${libName}DebugXCFramework
- assemble${libName}ReleaseXCFramework

NEW THINGS TO DO. 




```bash
.
├── build
    ├── XCFrameworks
        ├── debug
        │   └── LibraryName.xcframework
        └── release
            └── LibraryName.xcframework
```



OLD CUSTOM TASK FOR DEBUG

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

OLD CUSTOM TASK FOR RELEASE

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

Here you can find the differeneces from the two build.gradle.kts file: 


https://github.com/prof18/kmp-xcframework-sample/commit/18fb4ec0fad6ec2b058a2a543c0c1de914c0a0c9#diff-c0dfa6bc7a8685217f70a860145fbdf416d449eaff052fa28352c5cec1a98c06


When you declare XCFrameworks, these new Gradle tasks will be registered:


https://github.com/prof18/kmp-xcframework-sample/tree/kotlin-1.5.30

You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episodes.