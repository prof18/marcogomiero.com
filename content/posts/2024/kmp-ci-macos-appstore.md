---
layout: post
title:  "How to publish a Kotlin Multiplatform macOS app on the App Store with GitHub Actions"
date:   2024-05-20
show_in_homepage: false
---

> **SERIES: Publishing a Kotlin Multiplatform Android, iOS, and macOS app with GitHub Actions.**
>
> - Part 1: [How to publish a Kotlin Multiplatform Android app on Play Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-android)
> - Part 2: [How to publish a Kotlin Multiplatform iOS app on App Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-ios)
> - Part 3: [How to publish a Kotlin Multiplatform macOS app on GitHub Releases with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-macos-github-releases)
> - Part 4: How to publish a Kotlin Multiplatform macOS app on App Store with GitHub Actions

It's been almost a year since I started working on [FeedFlow](https://www.feedflow.dev/), an RSS Reader available on Android, iOS, and macOS, built with Jetpack Compose for the Android app, Compose Multiplatform for the desktop app, and SwiftUI for the iOS app.

To be faster and "machine-agnostic" with the deployments, I decided to have a CI (Continuous Integration) on GitHub Actions to quickly deploy my application to all the stores (Play Store, App Store for iOS and macOS, and on GitHub release for the macOS app).

In this post, I will show how to deploy a Kotlin Multiplatform macOS app on the macOS App Store. This post is part of a series dedicated to setting up a CI for deploying a Kotlin Multiplatform app on Google Play, Apple App Store for iOS and macOS, and GitHub releases for distributing a macOS app outside the App Store. To keep up to date, you can check out the other instances of the series in the index above or follow me on [Mastodon](https://androiddev.social/@marcogom) or [Twitter](https://twitter.com/marcoGomier).

This post won't cover the Gradle configuration required to create native distributions or any additional customizations necessary to deploy the app on the App Store.

More info is available on Compose Multiplatform documentation:

> [Native distributions & local execution](https://github.com/JetBrains/compose-multiplatform/blob/master/tutorials/Native_distributions_and_local_execution/README.md)

> [Signing and notarizing distributions for macOS - Configuring Gradle](https://github.com/JetBrains/compose-multiplatform/blob/master/tutorials/Signing_and_notarization_on_macOS/README.md#configuring-gradle)

and in another article where I cover all the necessary things required to publish a macOS Compose app on the macOS App Store:

> [Publishing a Compose macOS app on App Store: architectures, sandboxing and native libraries](https://www.marcogomiero.com/posts/2024/compose-macos-app-store)

For reference, you can also check [FeedFlow's Gradle configuration](https://github.com/prof18/feed-flow/blob/main/desktopApp/build.gradle.kts).

## Triggers

A trigger is necessary to trigger the GitHub Action. I've decided to trigger a new release when I add a tag that ends with the platform name, in this case, `-desktop`. So, for example, a tag would be `0.0.1-desktop`.

```yml
on:
  push:
    tags:
      - '*-desktop'
```

In this way, I can be more flexible when making platform-independent releases.

## Gradle and JDK setup

The first part of the pipeline involves cloning the repo and setting up the infrastructure: JDK and Gradle.

### Clone the repository

The `actions/checkout` action can be used to clone the repository:

```yml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
```

### JDK Setup

The `actions/setup-java` action can be used to set up a desired JDK. I want the `zulu` distribution and version 18 in this case.

```yml
- name: set up JDK
  uses: actions/setup-java@v4
  with:
    distribution: 'zulu'
    java-version: 18
```

### Gradle Setup

The `gradle/actions/setup-gradle` action can be used to set up Gradle with its cache.

In the action, I'm using two parameters: `gradle-home-cache-cleanup` and `cache-encryption-key`.

The `gradle-home-cache-cleanup` parameter will enable a feature that will try to delete any files in the Gradle User Home that were not used by Gradle during the GitHub Actions Workflow before saving the cache. In this way, some space can be saved. More info can be found [in the documentation](https://github.com/gradle/actions/blob/main/docs/setup-gradle.md#remove-unused-files-from-gradle-user-home-before-saving-to-the-cache).

Instead, the `cache-encryption-key` parameter provides an encryption key from the GitHub secrets to encrypt the configuration cache. The configuration cache might contain stored credentials and other secrets, so encrypting it before saving it on the GitHub cache is better. More info can be found [in the documentation](https://github.com/gradle/actions/blob/main/docs/setup-gradle.md#saving-configuration-cache-data).

```yml
- uses: gradle/actions/setup-gradle@v3
  with:
    gradle-home-cache-cleanup: true
    cache-encryption-key: ${{ secrets.GRADLE_CACHE_ENCRYPTION_KEY }}
```

### Kotlin Native setup

When compiling a Kotlin Multiplatform project that also targets Kotlin Native, some required components will be downloaded in the `$USER_HOME/.konan` directory. Kotlin Native will also create and use some cache in this directory.

```bash
├── .konan
│   ├── cache
│   ├── dependencies
│   └── kotlin-native-prebuilt-macos-aarch64-1.9.23
```

Caching that directory will avoid redownloading and unnecessary computation. The `actions/cache` action can be used to do so.

The action requires a key to identify the cache uniquely; in this case, the key will be a hash of the version catalog file since the Kotlin version number is stored there:

```yml
- name: Cache KMP tooling
  uses: actions/cache@v4
  with:
    path: |
      ~/.konan
    key: ${{ runner.os }}-v1-${{ hashFiles('*.versions.toml') }}
```

## Setup signing certificates

Every macOS application must be signed to be distributed in the app store. The certificates required to sign a macOS application for distribution are `Mac App Distribution` and `Mac Installer Distribution`. Those certificates can be generated and downloaded from [the Apple Developer website](https://developer.apple.com/account/resources/certificates/add) by uploading a Certificate Signing Request.

This request can be obtained from the Keychain app on macOS by opening the menu `Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority`. An email must be added to the form that will appear, and the `Save to disk` option must be selected. The CA Email address field can be blank because the request will be saved on the disk. More information can be found [in the Apple documentation](https://support.apple.com/en-am/guide/keychain-access/kyca2793/mac).

The certificates can be imported into GitHub Action by using the `p12` format, an archive file format for storing many cryptography objects as a single file ([Wikipedia](https://en.wikipedia.org/wiki/PKCS_12)). 

The Keychain app can be used to generate the `p12` file. After downloading the certificates, they must be imported into the Keychain app. Once imported, the certificates can be easily exported by selecting them in the Keychain, right-clicking, and selecting the `Export 2 items…` option. A password will be used to encrypt the `p12` file.

The `import-codesign-certs` action can be used to import the certificate in the `p12` format. To do so, the `p12` file must be encoded in `base64` (with the command `base64 -i myfile.extension`), and the content must be uploaded to GitHub secrets along with the decryption password.

```yml
- name: import certs
  uses: apple-actions/import-codesign-certs@v2
  with:
    p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
    p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}
```      
    
## Provision Profile

A provisioning profile is required to distribute a macOS app in addition to signing the app. The provisioning profile ensures that a trusted developer in the Apple Developer Program created and signed the app. This measure prevents unauthorized apps from being used because macOS validates the provisioning profile to ensure that it has been signed with a legitimate certificate from the developer's account.

Two provisioning profiles called `Mac App Store Connect` are required: one for the app and one for the JVM runtime that is included in the app binary. Those profiles can be created and downloaded on the [Apple Developer Website](https://developer.apple.com/account/resources/profiles/add).

The `App ID` is required to create a provisioning profile. It can be created on the [Apple Developer Website](https://developer.apple.com/account/resources/identifiers/add/bundleId). An additional `App ID` is necessary for the provisioning profile of the JVM runtime: this ID is composed of the `App ID` of the app, prepended by `com.oracle.java`. For example, if the `App ID` of the app is `com.yoursitename.yourappname`, the `App ID` of the runtime will be `com.oracle.java.com.yoursitename.yourappname`

The provisioning profiles are loaded in the project through Gradle properties set inside the desktop project's `build.gradle.kts`.

```koltin
macOS {
    provisioningProfile.set(project.file("embedded.provisionprofile"))
    runtimeProvisioningProfile.set(project.file("runtime.provisionprofile"))
}
```

The provisioning profiles can't be publicly released for security reasons, so a good approach is to encode them to `base64` (with the command `base64 -i myfile.extension`) and save them inside GitHub secrets.

```yml
- name: Create Embedded Provision Profile
  run: |
    echo "$EMBEDDED_PROVISION" > desktopApp/embedded.provisionprofile.b64
    base64 -d -i desktopApp/embedded.provisionprofile.b64 > desktopApp/embedded.provisionprofile
  env:
    EMBEDDED_PROVISION: ${{ secrets.EMBEDDED_PROVISION }}

- name: Create Runtime Provision Profile
  run: |
    echo "$RUNTIME_PROVISION" > desktopApp/runtime.provisionprofile.b64
    base64 -d -i desktopApp/runtime.provisionprofile.b64 > desktopApp/runtime.provisionprofile
  env:
    RUNTIME_PROVISION: ${{ secrets.RUNTIME_PROVISION }}
``` 

## Prepare variables for version and binary path

During the action, some information like the git tag, version name, and binary path are needed. That's why I've dedicated a step to compute and save them inside GitHub environmental variables.

The tag I use for releases comprises the version name and the platform type, such as `1.0.0-desktop`. Thus, the version name can be easily extracted from the tag that triggered the build.

The path of the application binary instead, it's `desktopApp/build/release/main-release/dmg/${name}`, where the name is the `packageName` of the app set on the `build.gradle.kts` file, followed by the version, in this case, `FeedFlow-1.0.0.dmg`     

```yml
- name: Create path variables
  id: path_variables
  run: |
    tag=$(git describe --tags --abbrev=0 --match "*-desktop")
    version=$(echo "$tag" | sed 's/-desktop$//')
    name="FeedFlow-${version}.dmg"
    path="desktopApp/build/release/main-release/dmg/${name}"
    echo "TAG=$tag" >> $GITHUB_ENV
    echo "VERSION=$version" >> $GITHUB_ENV
    echo "RELEASE_PATH=$path" >> $GITHUB_ENV
```

## Build the pkg

The format of a macOS app distributed in the App Store is `pkg`. The `packageReleasePkg` Gradle task can be used to build a `pkg`. The task also sets the Gradle property `macOsAppStoreRelease` to `true` because the Compose Multiplatform Gradle Plugin needs to know if the app will be distributed on or outside the App Store. This is a custom property that I've created to handle different configurations when bundling for the App Store.

```yml
- name: Create PKG
    run: ./gradlew packageReleasePkg -PmacOsAppStoreRelease=true
```

## Upload on TestFlight 

A macOS app can be uploaded to the App Store through [TestFlight](https://developer.apple.com/testflight/). The upload can be performed with the `upload-testflight-build` action.
    
As for the provisioning profile, this action uses the [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi) to communicate with TestFlight. For this reason, the action requires the same issuer ID, key ID, and private key used in the provisioning step. Additionally, it requires the path of the IPA archive, which can be provided by GitHub environmental variables and the app type: `osx`, in this case.

```yml
- uses: Apple-Actions/upload-testflight-build@v1
  with:
    app-type: 'osx'
    app-path: ${{ env.ipa_path }}
    issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
    api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
    api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

## Conclusions

And that's all the steps required to automatically publish a Kotlin Multiplatform macOS app on the App Store with a GitHub Action.

Here's the entire GitHub Action for reference:

```yml
name: Desktop MacOS Testflight Release
on:
  push:
    tags:
      - '*-desktop'

jobs:
  deploy:
    runs-on: macos-14
    timeout-minutes: 40

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: set up JDK
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: 18

      - uses: gradle/actions/setup-gradle@v3
        with:
          gradle-home-cache-cleanup: true
          cache-encryption-key: ${{ secrets.GRADLE_CACHE_ENCRYPTION_KEY }}                  

      - name: Cache KMP tooling
        uses: actions/cache@v4
        with:
          path: |
            ~/.konan
          key: ${{ runner.os }}-v1-${{ hashFiles('*.versions.toml') }}

      - name: Import Mac App Distribution and Installer certificate
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.MAC_APP_DISTRIBUTION_INSTALLER_CERTIFICATE }}
          p12-password: ${{ secrets.MAC_APP_DISTRIBUTION_INSTALLER_CERTIFICATE_PWD }}

      - name: Create Embedded Provision Profile
        run: |
          echo "$EMBEDDED_PROVISION" > desktopApp/embedded.provisionprofile.b64
          base64 -d -i desktopApp/embedded.provisionprofile.b64 > desktopApp/embedded.provisionprofile
        env:
          EMBEDDED_PROVISION: ${{ secrets.EMBEDDED_PROVISION }}

      - name: Create Runtime Provision Profile
        run: |
          echo "$RUNTIME_PROVISION" > desktopApp/runtime.provisionprofile.b64
          base64 -d -i desktopApp/runtime.provisionprofile.b64 > desktopApp/runtime.provisionprofile
        env:
          RUNTIME_PROVISION: ${{ secrets.RUNTIME_PROVISION }} 

      - name: Create path variables
        id: path_variables
        run: |
          tag=$(git describe --tags --abbrev=0 --match "*-desktop")
          version=$(echo "$tag" | sed 's/-desktop$//')
          name="FeedFlow-${version}.pkg"
          path="desktopApp/build/release/main-release/pkg/${name}"
          echo "TAG=$tag" >> $GITHUB_ENV
          echo "VERSION=$version" >> $GITHUB_ENV
          echo "RELEASE_PATH=$path" >> $GITHUB_ENV

      - name: Create PKG
        run: ./gradlew packageReleasePkg -PmacOsAppStoreRelease=true

      - uses: Apple-Actions/upload-testflight-build@v1
        with:
          app-type: 'osx'
          app-path: ${{ steps.path_variables.outputs.RELEASE_PATH }}
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

You can check the action [on GitHub](https://github.com/prof18/feed-flow/blob/main/.github/workflows/desktop-macos-testflight-release.yaml)