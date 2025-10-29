---
date: 2025-10-28T08:45:00Z
title: "From Kotlin to Native and back: accessing native macOS API in Compose Multiplatform"
location: "Berlindroid"
performDate: 2025-10-29
eventUrl: https://www.meetup.com/berlindroid/events/311661598/?eventOrigin=notifications&notificationId=%3Cinbox%3E%21225987715-1761759736511
summary: "Compose Multiplatform makes it easy to build cross-platform desktop apps with Kotlin and Compose, but what about native APIs, like iCloud on macOS? Accessing such APIs isn't possible through the regular Compose Multiplatform toolchain. However, with a bit of \"magic\", we can turn dreams (or feature requests) into reality.
<br><br>
In this talk, we'll explore how to combine Kotlin/Native and the JNI (Java Native Interface) to bridge the gap between a JVM-based UI and native system features. We'll write Kotlin code, compile it into a native library, and call it back from Kotlin.
<br><br>
You'll learn how to build Kotlin/Native code into a native macOS dynamic library and integrate it into a Compose Multiplatform desktop app, unlocking access to iCloud and enabling features like backup and restore for your app’s data."
speakerDeck: 0e87f1aea3d7434b8aa2e36a08a61e39
---

## Resources:

- **FeedFlow**\
    https://feedflow.dev/

- **Java Native Interface**\
    https://docs.oracle.com/javase/8/docs/technotes/guides/jni/

- **Java Native Access (JNA)**\
    https://github.com/java-native-access/jna

- **Project Panama: Interconnecting JVM and native code**\
    https://openjdk.org/projects/panama/

- **Kevin Galligan's post**\
    https://bsky.app/profile/kpgalligan.bsky.social/post/3lcgoc32zf22c

- **NSFileManager**\
    https://developer.apple.com/documentation/foundation/filemanager?language=objc

- **URLsForDirectory:inDomains:**\
    https://developer.apple.com/documentation/foundation/filemanager/urls(for:in:)?language=objc

- **Definition file**\
    https://kotlinlang.org/docs/native-definition-file.html

- **Native distributions - Adding files to packaged application**\
    https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-native-distribution.html#adding-files-to-packaged-application

- **Accessing native macOS API in Compose Multiplatform**\
    https://www.marcogomiero.com/posts/2025/compose-desktop-macos-api-jni/


