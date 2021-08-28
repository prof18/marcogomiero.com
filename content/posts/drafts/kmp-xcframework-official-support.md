---
layout: post
title:  "Building an XCFramework on Kotlin Multiplatform from Kotlin 1.5.30"
date:   2021-08-28
show_in_homepage: true
draft: true
---


---

I wrote how to build xcframework without official support saying that the official support will arrive. Well, that time has arrived with Kotlin 1.5.30

https://www.marcogomiero.com/posts/2021/build-xcframework-kmp/

https://kotlinlang.org/docs/whatsnew1530.html?utm_source=pocket_mylist#support-for-xcframeworks

https://github.com/prof18/kmp-xcframework-sample/tree/kotlin-1.5.30

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

New task added:

- assemble${libName}XCFramework
- assemble${libName}DebugXCFramework
- assemble${libName}ReleaseXCFramework

NEW THINGS TO DO. 




```kotlin
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

```bash
.
├── build
    ├── XCFrameworks
        ├── debug
        │   └── LibraryName.xcframework
        └── release
            └── LibraryName.xcframework
```


Here you can find the differeneces from the two build.gradle.kts file: 


https://github.com/prof18/kmp-xcframework-sample/commit/18fb4ec0fad6ec2b058a2a543c0c1de914c0a0c9#diff-c0dfa6bc7a8685217f70a860145fbdf416d449eaff052fa28352c5cec1a98c06


When you declare XCFrameworks, these new Gradle tasks will be registered:




You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episodes.