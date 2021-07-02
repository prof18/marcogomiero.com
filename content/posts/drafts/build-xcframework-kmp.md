---
layout: post
title:  "How to build an XCFramework on Kotlin Multiplatform"
date:   2021-06-27
show_in_homepage: true
draft: true
tags: [Kotlin Multiplatform]
---

When you start integrating Kotlin Multiplatform (I’ll call it KMP in the rest of the article) in an existing project you most likely don’t have a mono-repo structure (and making a refactor to achieve this kind of architecture will not be easy). An example of architecture is the following, with a repository for every platform.  

{{< figure src="/img/kmp-existing-projects/kmp-publish-arch.png"  link="/img/kmp-existing-project/kmp-publish-arch.png" >}}

> To understand how to integrate KMP into existing code, give a look to my previous article: [“Introducing Kotlin Multiplatform in an existing project”](https://www.marcogomiero.com/posts/2021/kmp-existing-project/)

KMP code will be served as a library: the compiler generates a .jar for the JVM, a .aar for Android, and a Framework for iOS. 

For iOS, the Framework will be a FatFramework, because it is necessary to have in the same package the architecture for the simulator and the real device. In [a past article](https://www.marcogomiero.com/posts/2021/kmp-existing-project/), I’ve explained how to generate a FatFramework and how to distribute it in a CocoaPod repo. It is possibile with some Gradle tasks or with the [KMP FatFramework Cocoa](https://github.com/prof18/kmp-fatframework-cocoa) Gradle plugin that I wrote.

However, FatFrameworks seems not to be the “current state of the art” solution to distribute multiple architectures at the same time. In fact, Apple during [WWDC 2019](https://developer.apple.com/videos/play/wwdc2019/416/) has introduced [XCFramework](https://help.apple.com/xcode/mac/11.4/#/dev544efab96), a binary that can contains multiple platform-specific variants (even for iOS and macOS at the same time). 

Apple is pushing toward the use of XCFrameworks and you could encounter errors like the following one that happened to [Sam Edwards](https://twitter.com/handstandsam).

{{< tweet 1403456462689550345 >}}

Sam [followed the same approach](https://handstandsam.com/2021/06/11/kotlin-multiplatform-building-a-fat-ios-framework-for-iosarm64-and-iosx64/) I’ve followed but I never encounter the error! And the reason could be the following:

{{< tweet 1403673057487687682 >}}

Unfortunately there isn’t native support for XCFrameworks on Kotlin Multiplatform yet (it should come hopefully with Kotlin 1.5.30) and to generate a XCFramework, you have to create manually an XCFramework starting from the different frameworks built by KMP.

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


```kotlin
dependsOn("link${libName}DebugFrameworkIosArm64")
dependsOn("link${libName}DebugFrameworkIosX64")
```

```bash
build
└── bin
    ├── iosArm64
    │   ├── LibraryNameDebugFramework
    │   │   ├── LibraryName.framework
    │   │   └── LibraryName.framework.dSYM
    │   └── LibraryNameReleaseFramework
    │       ├── LibraryName.framework
    │       └── LibraryName.framework.dSYM
    └── iosX64
        ├── LibraryNameDebugFramework
        │   ├── LibraryName.framework
        │   └── LibraryName.framework.dSYM
        └── LibraryNameReleaseFramework
            ├── LibraryName.framework
            └── LibraryName.framework.dSYM
```


```kotlin
executable = "xcodebuild"
args(mutableListOf<String>().apply {
    add("-create-xcframework")
    add("-output")
    …
}    

```

```kotlin
doFirst {
    xcFrameworkDest.deleteRecursively()
}
```

———

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

```kotlin
register("publishDevFramework") {
    description = "Publish iOs framework to the Cocoa Repo"

    project.exec {
        workingDir = File("$rootDir/../kmp-xcframework-dest")
        commandLine("git", "checkout", "develop").standardOutput
    }

    dependsOn("buildDebugXCFramework")
    
    … 
}
```

```kotlin
register("publishFramework") {
    description = "Publish iOs framework to the Cocoa Repo"

    project.exec {
        workingDir = File("$rootDir/../kmp-xcframework-dest")
        commandLine("git", "checkout", "master").standardOutput
    }
    dependsOn("buildReleaseXCFramework")
    
    …
}
```

// TODO: add a custom Gradle script to do the job

This is boring to repeat every time, so I decided [to update](https://github.com/prof18/kmp-fatframework-cocoa/releases/tag/0.2.1) the KMP FatFramework Cocoa Gradle plugin and add the support for XCFrameworks. 

To enable to usage of XCFrameworks, it is necessary to enable the `useXCFramework` flag in the `fatFrameworkCocoaConfig` block. 

```kotlin
fatFrameworkCocoaConfig {
    frameworkName = "LibraryName"
    outputPath = "$rootDir/../test-dest"
    versionName = "1.0"
    useXCFramework = true
}
```


With the plugin you can still use a CocoaPod repository and use the same tasks.

Se the flags

If you want to just build an XCFramework and manage the publication yourself, you can call the following tasks:

`buildDebugXCFramework` that creates a XCFramework with the Debug target

`buildReleaseXCFramework` that creates a XCFramework with the Release target.

If you want to automatically build the XCFramework and publish it in a CocoaPod repo, that you can use the following tasks:

`publishDebugXCFramework` that publishes the Debug version of the XCFramework in the CocoaPod repository. 

`publishReleaseXCFramework` that publishes the Release version of the XCFramework in the CocoaPod repository.  

To show all the details -> https://github.com/prof18/kmp-fatframework-cocoa

Instead if your pipeline uses the Swift Package Manager instead of CocoaPod, I suggest you to use this Gradle plugin: 


{{< smalltext >}} // Thanks to <a href="https://giansegato.com/">Gian</a> for helping me review the post {{< /smalltext >}}

Thanks to Sam Sam Edwards did (https://twitter.com/handstandsam).

You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episode