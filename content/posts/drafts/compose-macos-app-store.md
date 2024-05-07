---
layout: post
title:  "Publishing a Compose macOS app on App Store: architectures, sandboxing and native libraries"
date:   2024-04-20
show_in_homepage: false
draft: true
---

When I released [FeedFlow](https://www.feedflow.dev/) (an RSS Reader available on Android, iOS, and macOS, built with Jetpack Compose for the Android app, Compose Multiplatform for the desktop app, and SwiftUI for the iOS app), I decided to publish the macOS version outside the App Store. I went this path because publishing on the App Store has different requirements that I wanted to avoid tackling during the first launch.

> [How to publish a Kotlin Multiplatform macOS app on GitHub Releases with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-macos-github-releases)

A couple of months ago, I was ready for the challenge and decided it was time to publish FeedFlow on the macOS App Store.

## Certificates, Provisioning profiles and Entitlements

A different set of certificates for code signing is required to publish on the App Store. Also, a provisioning profile (which ensures that a trusted developer in the Apple Developer Program created and signed the app) and entitlements for the app and the JVM runtime are required.

All the necessary steps to fulfill such requirements are already covered in the Compose Multiplatform documentation:

> [Signing and notarizing distributions for macOS - Configuring Gradle](https://github.com/JetBrains/compose-multiplatform/blob/master/tutorials/Signing_and_notarization_on_macOS)

and in an article that I've written:

> [How to publish a Kotlin Multiplatform macOS app on App Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-macos-appstore)

## How to upload a macOS app

The format of a macOS app distributed in the App Store is `pkg`. The `packageReleasePkg` Gradle task can be used to build a `pkg`.

After building the `pkg`, it can be uploaded on [TestFlight](https://developer.apple.com/testflight/) without Xcode by using the [Transporter App](https://apps.apple.com/us/app/transporter/id1450874784?mt=12) (more info about Transporter can be found [in the official documentation](https://help.apple.com/itc/transporteruserguide/en.lproj/static.html#apd70774093eddb4)) or a [GitHub Action](https://www.marcogomiero.com/posts/2024/kmp-ci-macos-appstore).

## Publish an Apple Silicon-only app

The first upload led to a failure.

{{< figure src="/img/compose-macos-appstore/only-silicon.webp"  link="/img/compose-macos-appstore/only-silicon.webp" >}}

The error says the app bundle must support Apple Silicon's and Intel's architectures. The app must target macOS 12 to support only Apple Silicon.

After digging, I discovered that the Compose Multiplatform Gradle plugin was targeting by default macOS 10.13. So I modified the Gradle plugin to allow setting a custom `minimumSystemVersion` ([Here's the PR](https://github.com/JetBrains/compose-multiplatform/pull/4271), for reference).

The change is available from Compose Multiplatform 1.6.10.

```kotlin
compose {
    desktop {
        application {
            macOS {
                minimumSystemVersion = "12.0"
            }
        }
    }
}
```

With this change, I could publish my first build on TestFlight.

## App Sandbox

After publishing the first build on TestFlight, I tried to run it, and I got a mysterious error at runtime:

`"sqlite-3.44.1.0-af9d43dd-3c96-4be7-bb35-f75cc21ceafb-libsqlitejdbc.dylib" can't be
opened because Apple cannot check it for malicious software.`

{{< figure src="/img/compose-macos-appstore/native-lib.webp"  link="/img/compose-macos-appstore/native-lib.webp" >}}

After some research, I discovered that this issue is happening because of macOS "[App Sandbox](https://developer.apple.com/documentation/security/app_sandbox/protecting_user_data_with_app_sandbox)," a feature that is required for distributing an app on the App Store and that forbids certain activities by default, like accessing system resources and user data. This will limit what a malicious app can do and which data it can access.

One thing that is forbidden is loading native libraries that are not part of the app bundle. Some libraries, `sqlite` in this case, extract native libraries from the dependency `JAR`, place them inside an `OS` temporary folder, and load them. 

For the apps distributed outside the App Store that are not sandboxed, this folder is pointed by the `$TMPDIR` environmental variable; for example, on my machine, the value is the following:

```bash
➜  ~ echo $TMPDIR 
/var/folders/t8/25t7v371121b155qrxyb_cjc0000gn/T/
```

{{< figure src="/img/compose-macos-appstore/tmp-lib-folder.webp"  link="/img/compose-macos-appstore/tmp-lib-folder.webp" >}}

When running on a sandbox, the JVM tries to do the same; in this case, the native library is unpacked inside the Container that every sandboxed app has:

`/Users/mg/Library/Containers/com.prof18.feedflow/Data/tmp`

{{< figure src="/img/compose-macos-appstore/tmp-sandbox-lib-folder.webp"  link="/img/compose-macos-appstore/tmp-sandbox-lib-folder.webp" >}}

However, the loading fails because the native library was not part of the app bundle and was not signed, so Apple cannot verify if it's malicious.

To fix this issue, the native libraries must be included in the app bundle.

### Loading native libraries

The first step is to find the native library.

On FeedFlow, I'm using [SQLDelight](https://cashapp.github.io/sqldelight/). [The SQLDelight SQLite driver](https://github.com/cashapp/sqldelight/blob/master/drivers/sqlite-driver/build.gradle#L14) uses the [`SQLite JDBC Driver`](https://github.com/xerial/sqlite-jdbc) library as a dependency, and the native library that will be packaged in the JAR can be found [inside the repo](%20https://github.com/xerial/sqlite-jdbc/tree/master/src/main/resources/org/sqlite/native/Mac/aarch64) by architecture. 

{{< figure src="/img/compose-macos-appstore/native-lib-git.webp"  link="/img/compose-macos-appstore/native-lib-git.webp" >}}

In my case, I'm only interested in the version for Apple Silicon, so `aarch64`.

#### Include native libraries in the app bundle

[Compose Multiplatform lets you include assets](https://github.com/JetBrains/compose-multiplatform/blob/master/tutorials/Native_distributions_and_local_execution/README.md#adding-files-to-packaged-application), like a native library, inside the app bundle. Those assets can be placed in an OS-specific (`windows`, `macos`, `linux`) or OS and architecture-specific (for example, `macos-x64` and `macos-arm64`) folder. 

```bash
.
├── desktopApp
    ├── resources
        └── macos-arm64
            └── libsqlitejdbc.dylib
```

The path of the folders can then be configured in the `build.gradle.kts` file of the Compose Desktop app:

```kotlin
compose {
    desktop {
        application {
            val isAppStoreRelease = project.property("macOsAppStoreRelease").toString().toBoolean()

            nativeDistributions {
                outputBaseDir.set(layout.buildDirectory.asFile.get().resolve("release"))

                if (isAppStoreRelease) {
                    appResourcesRootDir.set(project.layout.projectDirectory.dir("resources"))
                }
            }
        }
    }
}
```

Since I only want to include the native libraries when I'm creating an app bundle for the App Store, I've created a custom Gradle property in the `gradle.properties` file that is set to `false` by default:

```properties
macOsAppStoreRelease=false
```

When I need to build a new version for the App Store, the property can be overridden and set to `true` from the command line:

```bash
./gradlew packageReleasePkg -PmacOsAppStoreRelease=true
```

#### Change native library path at startup

The last remaining step is changing the path from where the JVM can load the native library. This step must be done manually only if the app runs in the sandbox. 

It's possible to check if an app is sandboxed by checking if the value of the `APP_SANDBOX_CONTAINER_ID` environmental variable is not null. 

```kotlin
val isSandboxed = System.getenv("APP_SANDBOX_CONTAINER_ID") != null
```

To change the path, the `org.sqlite.lib.path` system property must be set. The path where the native libs are stored can be obtained from the `compose.application.resources.dir` system property. To avoid any possible issues, I've also manually set the library's name, in this case, `libsqlitejdbc.dylib`.

```kotlin
val isSandboxed = System.getenv("APP_SANDBOX_CONTAINER_ID") != null
if (isSandboxed) {
    val resourcesPath = System.getProperty("compose.application.resources.dir")

    System.setProperty("org.sqlite.lib.path", resourcesPath)
    System.setProperty("org.sqlite.lib.name", "libsqlitejdbc.dylib")
}
```

## Conclusions

And with those changes, FeedFlow is finally available on the [macOS App Store](https://apps.apple.com/it/app/feedflow-rss-reader/id6447210518?l=en-GB)

All the code mentioned in the article is available on [GitHub](https://github.com/prof18/feed-flow/tree/main/desktopApp). 
