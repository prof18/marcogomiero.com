---
date: 2024-04-25T15:45:00Z
title: "Introducing Kotlin Multiplatform in an existing mobile app - Workshop Edition"
location: "AndroidMakers Paris"
performDate: 2024-04-26
eventUrl: https://androidmakers.droidcon.com/marco-gomiero/
summary: "After discovering a new interesting technology or framework, you will probably start asking yourself how to integrate it into an existing project. That's because, the possibility of starting with a blank canvas is rare (not impossible, but rare).
<br><br>
This is also the case for Kotlin Multiplatform, which is getting more and more hype every day. And now, that the technology has become stable, it's the perfect time to start using it!
In this hands-on session, we will start with an existing Android and iOS application that \"lives\" in separate repositories, we will extract the business logic from the Android app and share it between the two apps with a Kotlin Multiplatform library. We will also cover how to distribute the library to the existing applications.
By the end of this workshop, you'll have a better understanding of what is needed to start using Kotlin Multiplatform in your existing projects."
speakerDeck: f3ecc43fc65d4c98bdf5211ccc49cbfb
---

## Workshop material

- [Step by step instructions](https://www.marcogomiero.com/workshops/introducing-kotlin-multiplatform-in-an-existing-mobile-app/#0)

- [GitHub Project](https://github.com/prof18/kmp-existing-project-workshop)

The GitHub project contains a start folder with an initial workspace for the workshop:

- [Start folder](https://github.com/prof18/kmp-existing-project-workshop/tree/main/start)

and an end folder with two final workspaces: one that "manually" deploys the KMP library on GitHub and one that it deploys it with KMMBridge.

- [End folder](https://github.com/prof18/kmp-existing-project-workshop/tree/main/end)
- ["Manual" Deployment on GitHub](https://github.com/prof18/kmp-existing-project-workshop/tree/main/end/self-publish)
- [KMMBridge](https://github.com/prof18/kmp-existing-project-workshop/tree/main/end/kmmbridge)

## Resources: 

- **Publishing Java packages with Gradle**\
    https://docs.github.com/en/actions/publishing-packages/publishing-java-packages-with-gradle

- **Gradle Maven deploy failing with 422 Unprocessable Entity #26328**\
    https://github.com/orgs/community/discussions/26328#discussioncomment-3251485

- **How to allow unauthorised read access to GitHub packages maven repository? #26634**\
    https://github.com/orgs/community/discussions/26634    

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

- **SKIE Migration Guide**\
    https://touchlab.co/skie-migration?ti=4B0F129C5D944E54B60B31FE35

- **Interoperability with Swift/Objective-C**\
    https://kotlinlang.org/docs/native-objc-interop.html
​
​- **Kotlin/Native as an Apple framework**\
    https://kotlinlang.org/docs/apple-framework.html

- **Kotlin-Swift interopedia**\
    https://github.com/kotlin-hands-on/kotlin-swift-interopedia    

- **Writing Swift-friendly Kotlin Multiplatform APIs**\
    https://medium.com/@aoriani/list/writing-swiftfriendly-kotlin-multiplatform-apis-c51c2b317fce

- **Dependency Management in iOS**\
    https://blog.devgenius.io/dependancy-management-for-ios-27dd681d7ea0

- **multiplatform-swiftpackage**\
    https://github.com/luca992/multiplatform-swiftpackage

- **KMMBridge**\
    https://github.com/touchlab/KMMBridge

- **KMMBridge Quick Start**\
    https://touchlab.co/kmmbridge-quick-start

- **Xcode 13.3 supports SPM binary dependency in private GitHub release**\
    https://medium.com/geekculture/xcode-13-3-supports-spm-binary-dependency-in-private-github-release-8d60a47d5e45

- **Xcode Kotlin - Xcode support for Kotlin browsing and debugging**\
    https://touchlab.co/xcodekotlin

- **Swift package export setup**\
    https://kotlinlang.org/docs/native-spm.html
        