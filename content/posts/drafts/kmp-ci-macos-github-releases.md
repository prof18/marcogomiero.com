---
layout: post
title:  "How to publish a Kotlin Multiplatform macOS app on GitHub Releases with GitHub Actions"
date:   2024-04-14
show_in_homepage: false
draft: true
---

> **SERIES: Publishing a Kotlin Multiplatform Android, iOS, and macOS app with GitHub Actions.**
>
> - Part 1: [How to publish a Kotlin Multiplatform Android app on Play Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-android)
> - Part 2: [How to publish a Kotlin Multiplatform iOS app on App Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-ios)
> - Part 3: How to publish a Kotlin Multiplatform macOS app on GitHub Releases with GitHub Actions
> - Part 4: How to publish a Kotlin Multiplatform macOS app on App Store with GitHub Actions - *Coming soon*

It's been almost a year since I started working on [FeedFlow](https://www.feedflow.dev/), an RSS Reader available on Android, iOS, and macOS, built with Jetpack Compose for the Android app, Compose Multiplatform for the desktop app, and SwiftUI for the iOS app.

To be faster and "machine-agnostic" with the deployments, I decided to have a CI (Continuous Integration) on GitHub Actions to quickly deploy my application to all the stores (Play Store, App Store for iOS and macOS, and on GitHub release for the macOS app).

In this post, I will show how to deploy a Kotlin Multiplatform macOS app outside the Mac App Store using GitHub Releases. This post is part of a series dedicated to setting up a CI for deploying a Kotlin Multiplatform app on Google Play, Apple App Store for iOS and macOS, and GitHub releases for distributing a macOS app outside the App Store. To keep up to date, you can check out the other instances of the series in the index above or follow me on [Mastodon](https://androiddev.social/@marcogom) or [Twitter](https://twitter.com/marcoGomier).

This post won't cover the Gradle configuration required to create and customize native distributions. More info is available on Compose Multiplatform documentation:

> [Native distributions & local execution](https://github.com/JetBrains/compose-multiplatform/blob/master/tutorials/Native_distributions_and_local_execution/README.md)

> [Signing and notarizing distributions for macOS - Configuring Gradle](https://github.com/JetBrains/compose-multiplatform/blob/master/tutorials/Signing_and_notarization_on_macOS/README.md#configuring-gradle)

For reference, you can also check [FeedFlow's Gradle configuration](https://github.com/prof18/feed-flow/blob/main/desktopApp/build.gradle.kts).

## Triggers

A trigger is necessary to trigger the GitHub Action. I've decided to trigger a new release on GitHub Releases only when the deployment to the macOS App Store is done.  

```yml
on:
  workflow_run:
    workflows: ["Desktop MacOS Testflight Release"]
    types:
      - completed
```

This way, if something goes wrong with the App Store release and I need to redo it with the same version tag, this job won't be triggered again.

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

The `actions/setup-java` action can be used to set up a desired JDK. In this case, I want the `zulu` distribution and version 18.

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

The `cache-encryption-key` parameter provides an encryption key from the GitHub secrets to encrypt the configuration cache. The configuration cache might contain stored credentials and other secrets, so encrypting it before saving it on the GitHub cache is better. More info can be found [in the documentation](https://github.com/gradle/actions/blob/main/docs/setup-gradle.md#saving-configuration-cache-data).

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

## Signing Certificates

Every macOS application must be signed to be distributed, even outside the app store. The certificate required to sign a macOS application for distribution outside the app store is called `Developer ID Application`. This certificate can be generated and downloaded from [the Apple Developer website](https://developer.apple.com/account/resources/certificates/add) by uploading a Certificate Signing Request. 

This request can be obtained from the Keychain app on macOS by opening the menu `Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority`. An email must be added in the form that will appear, and the `Save to disk` option must be selected. The CA Email address field can be blank instead because the request will be saved on the disk. More information can be found [in the Apple documentation](https://support.apple.com/en-am/guide/keychain-access/kyca2793/mac).

The certificate can be imported into GitHub Action by using the `p12` format, an archive file format for storing many cryptography objects as a single file ([Wikipedia](https://en.wikipedia.org/wiki/PKCS_12)). 

The Keychain app can generate the `p12` file. After downloading the certificate, it must be imported into the Keychain app. Once imported, the certificate can be easily exported by selecting it in the Keychain, right-clicking, and selecting the `Export 2 items…` option. A password will be used to encrypt the `p12` file.

The `import-codesign-certs` action can be used to import the certificate in the `p12` format. To do so, the `p12` file must be encoded in `base64` (with the command `base64 -i myfile.extension`), and the content must be uploaded into GitHub secrets along with the decryption password.

```yml
- name: import certs
  uses: apple-actions/import-codesign-certs@v2
  with:
    p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
    p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}
```      
    
## Prepare variables for version and binary path

During the action, some information like the git tag, version name, and the path of the binary are needed. That's why I've dedicated a step to compute and save them inside GitHub environmental variables. 

The tag I use for releases is composed of the version name and the platform type, such as `1.0.0-desktop`. Thus, the version name can be easily extracted by the tag that triggered the build. 

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

## Build the app:

The format of a macOS app distributed outside the App Store is `dmg`. The `packageReleaseDmg` Gradle task can be used to build a' dmg'.

```yml
- name: Create DMG
  run: ./gradlew packageReleaseDmg
```

## Notarization

[Notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution) is a mandatory step for distributing a macOS application outside the App Store. 
 
In this process, Apple automatically scans the app's content to ensure it does not contain malware or malicious content. It also checks for any code-signing issues to ensure that a registered developer has signed the app.

Notarization can be done with the `notarytool` command-line tool:

```bash
xcrun notarytool submit $RELEASE_PATH --apple-id $APPLE_ID_NOTARIZATION --password $NOTARIZATION_PWD --team-id $APPSTORE_TEAM_ID --wait
```

The command requires some arguments that can be hardcoded directly or provided through GitHub secrets, depending on the level of sensitivity:

- `$RELEASE_PATH`: the path of the `dmg`;
- `apple-id`: the Apple ID, i.e., the email associated with the developer account
- `password`: an [app-specific password](https://support.apple.com/en-us/102654) to log in with the Apple ID; it can be created in the [Apple ID account page](https://appleid.apple.com/account/manage/section/security);
- `team-id`: team ID;
- `wait`: this argument will make the command wait until the notarization process is done. 

The notarization process will usually take between one and three minutes. With the `--wait` arguments passed to the command-line tool, the execution will be paused until a successful response from Apple.

After a successful notarization step, the notary service generates a "ticket" that can be stapled to the app. The "ticket" is also published online, and when the user first installs or runs the app, Gatekeeper ([a macOS security feature](https://support.apple.com/en-am/guide/security/sec5599b66df/web) that restricts app installation by default) will know that the application is secure and legitimate. 

The "stapling" of the "ticket" can be done with the `stapler` command-line tool. The only argument required is the path of the application `dmg`.

```bash
xcrun stapler staple $RELEASE_PATH
```

Here's the complete step that performs Notarization:

```yml
- name: Notarization
  run: |
    xcrun notarytool submit $RELEASE_PATH --apple-id $APPLE_ID_NOTARIZATION --password $NOTARIZATION_PWD --team-id $APPSTORE_TEAM_ID --wait
    xcrun stapler staple $RELEASE_PATH
  env:
    APPLE_ID_NOTARIZATION: ${{ secrets.APPLE_ID_NOTARIZATION }}
    APPSTORE_TEAM_ID: ${{ secrets.APPSTORE_TEAM_ID }}
    NOTARIZATION_PWD: ${{ secrets.NOTARIZATION_PWD }}
    RELEASE_PATH: ${{ env.RELEASE_PATH }}
```

## Distribute the app with Github Releases

After the notarization process, the app can be distributed to users. The `svenstaro/upload-release-action` can be used to upload the app to GitHub Releases.

The action requires some parameters, such as the git tag, the app binary path, and an optional body for the release notes. In my case, I publish the release as a draft so I can manually add some final touches to the release notes before the publication. 

```yml
- name: Upload binaries to release
  uses: svenstaro/upload-release-action@v2
  with:
    repo_token: ${{ secrets.GITHUB_TOKEN }}
    file: ${{ env.RELEASE_PATH }}
    tag: ${{ env.TAG }}
    overwrite: true
    draft: true
    body: "Release ${{ env.VERSION }}"
```

The latest release on GitHub can be opened with a link in the following format: https://github.com/USERNAME/REPO-NAME/releases/latest/ (e.g. [https://github.com/prof18/feed-flow/releases](https://github.com/prof18/feed-flow/releases));

The latest release's binary can instead be downloaded from a link in the following format: https://github.com/USERNAME/REPO-NAME/releases/latest/download/FILENAME.extension (e.g., [https://github.com/prof18/feed-flow/releases/latest/download/FeedFlow-1.0.56.dmg](https://github.com/prof18/feed-flow/releases/latest/download/FeedFlow-1.0.56.dmg)).

## Conclusions

And that's all the steps required to automatically publish a Kotlin Multiplatform macOS app on GitHub Releases with a GitHub Action.

Here's the entire GitHub Action for reference:

```yml
name: Desktop MacOS Release
on:
  workflow_run:
    workflows: ["Desktop MacOS Testflight Release"]
    types:
      - completed

jobs:
  deploy:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: macos-14
    timeout-minutes: 40
    permissions:
      contents: write

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

      # Developer ID Application
      - name: Import signing certificate
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.SIGNING_CERTIFICATE_P12_DATA_MACOS }}
          p12-password: ${{ secrets.SIGNING_CERTIFICATE_PASSWORD_MACOS }}

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

      - name: Create DMG
        run: ./gradlew packageReleaseDmg

      - name: Notarization
        run: |
          xcrun notarytool submit $RELEASE_PATH --apple-id $APPLE_ID_NOTARIZATION --password $NOTARIZATION_PWD --team-id $APPSTORE_TEAM_ID --wait
          xcrun stapler staple $RELEASE_PATH
        env:
          APPLE_ID_NOTARIZATION: ${{ secrets.APPLE_ID_NOTARIZATION }}
          APPSTORE_TEAM_ID: ${{ secrets.APPSTORE_TEAM_ID }}
          NOTARIZATION_PWD: ${{ secrets.NOTARIZATION_PWD }}
          RELEASE_PATH: ${{ env.RELEASE_PATH }}

      - name: Upload binaries to release
        uses: svenstaro/upload-release-action@v2
        with:
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          file: ${{ env.RELEASE_PATH }}
          tag: ${{ env.TAG }}
          overwrite: true
          draft: true
          body: "Release ${{ env.VERSION }}"
```

You can check the action [on GitHub](https://github.com/prof18/feed-flow/blob/main/.github/workflows/desktop-macos-release.yaml)