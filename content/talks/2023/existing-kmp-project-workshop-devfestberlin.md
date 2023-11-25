---
date: 2023-11-24T15:45:00Z
title: "Introducing Kotlin Multiplatform in an existing mobile app - Workshop Edition"
location: "DevFest Berlin"
performDate: 2023-11-25
eventUrl: https://devfest.berlin/schedule/2023-11-25?sessionId=127
summary: "After discovering a new interesting technology or framework, you will probably start asking yourself how to integrate it into an existing project. That's because, the possibility of starting with a blank canvas is rare (not impossible, but rare).
<br><br>
This is also the case for Kotlin Multiplatform, which is getting more and more hype every day. And now, that the technology has become stable, it's the perfect time to start using it!
In this hands-on session, we will start with an existing Android and iOS application that \"lives\" in separate repositories, we will extract the business logic from the Android app and share it between the two apps with a Kotlin Multiplatform library. We will also cover how to distribute the library to the existing applications.
By the end of this workshop, you'll have a better understanding of what is needed to start using Kotlin Multiplatform in your existing projects.
<br><br>
To follow along in the workshop you will need:
- Android Studio with the <a href="https://plugins.jetbrains.com/plugin/14936-kotlin-multiplatform-mobile">Kotlin Multiplatform Mobile</a> plugin
- Xcode"
speakerDeck: 9e417dbcac0c4d099522c07710501b0b
---

## Workshop material

- [GitHub Project](https://github.com/prof18/kmp-existing-project-workshop)

The GitHub project contains a start folder with an initial workspace for the workshop:

- [Start folder](https://github.com/prof18/kmp-existing-project-workshop/tree/main/start)

and an end folder with two final workspaces: one that deploy the Kotlin Multiplatform locally and one that deploy it on GitHub packages.

- [End folder](https://github.com/prof18/kmp-existing-project-workshop/tree/main/end)
- [Local Deployment](https://github.com/prof18/kmp-existing-project-workshop/tree/main/end/local-spm)
- [Github Package Deployment](https://github.com/prof18/kmp-existing-project-workshop/tree/main/end/kmmbridge)

## Resources: 

- **Creating a multiplatform binary framework bundle**\
    https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle

- **Binary Frameworks in Swift**\
    https://developer.apple.com/videos/play/wwdc2019/416/

- **Binary Frameworks in Swift**\
    https://devstreaming-cdn.apple.com/videos/wwdc/2019/416h8485aty341c2/416/416_binary_frameworks_in_swift.pdf

- **Build final native binaries**\
    https://kotlinlang.org/docs/multiplatform-build-native-binaries.html#build-xcframeworks

- **Distributing binary frameworks as Swift packages**\
    https://developer.apple.com/documentation/xcode/distributing-binary-frameworks-as-swift-packages

- **KMP-NativeCoroutines**\
    https://github.com/rickclephas/KMP-NativeCoroutines

- **SKIE**\
    https://skie.touchlab.co/

- **multiplatform-swiftpackage**\
    https://github.com/luca992/multiplatform-swiftpackage

- **KMMBridge**\
    https://github.com/touchlab/KMMBridge

- **Xcode 13.3 supports SPM binary dependency in private GitHub release**\
    https://medium.com/geekculture/xcode-13-3-supports-spm-binary-dependency-in-private-github-release-8d60a47d5e45
