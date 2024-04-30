---
layout: post
title: "How to publish a Kotlin Multiplatform Android app on Play Store with GitHub Actions"
date:   2024-04-30
show_in_homepage: true
---

> **SERIES: Publishing a Kotlin Multiplatform Android, iOS, and macOS app with GitHub Actions.**
>
> - Part 1: How to publish a Kotlin Multiplatform Android app on Play Store with GitHub Actions
> - Part 2: How to publish a Kotlin Multiplatform iOS app on App Store with GitHub Actions - *Coming soon* 
> - Part 3: How to publish a Kotlin Multiplatform macOS app on GitHub Releases with GitHub Actions - *Coming soon* 
> - Part 4: How to publish a Kotlin Multiplatform macOS app on App Store with GitHub Actions - *Coming soon*


It's been almost a year since I started working on [FeedFlow](https://www.feedflow.dev/), a RSS Reader available on Android, iOS, and macOS, built with Jetpack Compose for the Android app, Compose Multiplatform for the desktop app, and SwiftUI for the iOS app.

To be faster and "machine-agnostic" with the deployments, I decided to have a CI (Continuous Integration) on GitHub Actions to quickly deploy my application to all the stores (Play Store, App Store for iOS and macOS, and on GitHub release for the macOS app).

Today, I decided to start a series of posts dedicated to setting up a CI for deploying a Kotlin Multiplatform app on Google Play, Apple App Store for iOS and macOS, and on GitHub releases for distributing a macOS app outside the App Store.

In this post, I will show how to deploy a Kotlin Multiplatform Android app on Google Play. To keep up to date, you can check out the other instances of the series in the index above or follow me on [Mastodon](https://androiddev.social/@marcogom) or [Twitter](https://twitter.com/marcoGomier).

## Triggers

A trigger is necessary to trigger the GitHub Action. I've decided to trigger a new release when I add a tag that ends with the platform name, in this case, `-android`. So, for example, a tag would be `0.0.1-android`.

```yml
on:
  push:
    tags:
      - '*-android'
```

In this way, I can be more flexible when making platform-independent releases.

## Gradle and JDK setup

The first part of the pipeline involves cloning the repo and setting up the infrastructure.

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

Instead, the `cache-encryption-key` parameter provides an encryption key from GitHub secrets to encrypt the configuration cache. The configuration cache might contain stored credentials and other secrets, so encrypting it before saving it on the GitHub cache is better. More info can be found [in the documentation](https://github.com/gradle/actions/blob/main/docs/setup-gradle.md#saving-configuration-cache-data).

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

## Setup Keystore

Every release version of an Android app needs to be signed with a developer key. For security reasons, the [keystore](https://developer.android.com/studio/publish/app-signing#certificates-keystores) that contains certificates and private keys can't be publicly released, so a good approach is to save it inside GitHub secrets.

A keystore, to be saved inside the secrets, needs to be in a "shareable and encrypted" format (ASCII-armor encrypted). This format can be generated with the following command and by providing a passphrase:

```bash
gpg -c --armor your-keystore
```

The output of the previous command can now be uploaded on GitHub secrets, alongside the passphrase and decrypted with the following command:

```bash
echo '${{ secrets.KEYSTORE_FILE }}'> release.keystore.asc
gpg -d --passphrase '${{ secrets.KEYSTORE_PASSPHRASE }}' --batch release.keystore.asc > androidApp/release.keystore
```

In addition to the keystore file, some other info is required to successfully sign the app, like the key alias, the key password, and the keystore password. This info is provided in the signing configuration of the app in the `app/build.gradle.kts` file:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = ..
        keyPassword = ..
        storeFile = ..
        storePassword = ..
    }
}
```

The `keyAlias`, `keyPassword`, and `storePassword` can be saved in the GitHub secrets and provided to Gradle through a `properties` file that the GitHub Action will create:

```kotlin
val local = Properties()
val localProperties: File = rootProject.file("keystore.properties")
if (localProperties.exists()) {
    localProperties.inputStream().use { local.load(it) }
}

signingConfigs {
    create("release") {
        keyAlias = local.getProperty("keyAlias")
        keyPassword = local.getProperty("keyPassword")
        storeFile = file(local.getProperty("storeFile") ?: "NOT_FOUND")
        storePassword = local.getProperty("storePassword")
    }
}
```

Here's the complete step, with the keystore decrypting and the properties file creation:

```yml
- name: Configure Keystore
  run: |
    echo '${{ secrets.KEYSTORE_FILE }}'> release.keystore.asc
    gpg -d --passphrase '${{ secrets.KEYSTORE_PASSPHRASE }}' --batch release.keystore.asc > androidApp/release.keystore
    echo "storeFile=release.keystore" >> keystore.properties
    echo "keyAlias=$KEYSTORE_KEY_ALIAS" >> keystore.properties
    echo "storePassword=$KEYSTORE_STORE_PASSWORD" >> keystore.properties
    echo "keyPassword=$KEYSTORE_KEY_PASSWORD" >> keystore.properties
  env:
    KEYSTORE_KEY_ALIAS: ${{ secrets.KEYSTORE_KEY_ALIAS }}
    KEYSTORE_KEY_PASSWORD: ${{ secrets.KEYSTORE_KEY_PASSWORD }}
    KEYSTORE_STORE_PASSWORD: ${{ secrets.KEYSTORE_STORE_PASSWORD }}
```

## [Optional] Firebase configuration or other secrets

GitHub secrets can be leveraged to store any sensitive stuff or configuration that can't be exposed to version control.

To do so, any file can be encoded with `base64` and saved inside a GitHub secret.

```bash
base64 -i myfile.extension
```

Then, the GitHub action can decode the content and create the file. For example, here's the step for the Firebase JSON configuration:

```yml
- name: Create Firebase json
  run: |
    echo "$FIREBASE_JSON" > androidApp/google-services.json.b64
    base64 -d -i androidApp/google-services.json.b64 > androidApp/google-services.json
  env:
    FIREBASE_JSON: ${{ secrets.FIREBASE_JSON }}
```

## Publish on Google Play Console

To publish the APK or AAB to the Play Console, I'm using the [Gradle Play Publisher plugin](https://github.com/Triple-T/gradle-play-publisher).

To communicate and authenticate with the Play Console, the plugin requires a [Service Account](https://cloud.google.com/iam/docs/service-account-overview). The steps needed to create a Service Account for the Play Console are well described [in the plugin documentation](https://github.com/Triple-T/gradle-play-publisher#service-account). All the information required for the authentication will be contained in a JSON file that needs to be provided to the Gradle plugin:

```kotlin
play {
    serviceAccountCredentials.set(file("../play_config.json"))
    track.set("alpha")
}
```

In the plugin configuration, I also specify that I want to upload the APK on the Alpha track of the Play Console. The plugin is very customizable, and all the possibilities can be found [in the documentation](https://github.com/Triple-T/gradle-play-publisher?tab=readme-ov-file#common-configuration).

> N.B. The first version on the Play Console needs to be manually uploaded before using any automation.

To provide the JSON in the GitHub Action, the method described [in the previous section](#optional-firebase-configuration-or-other-secrets) can be used: the content of the JSON will be stored in the GitHub secrets encoded in base64.

```yml
- name: Create Google Play Config file
  run: |
    echo "$PLAY_CONFIG_JSON" > play_config.json.b64
    base64 -d -i play_config.json.b64 > play_config.json
  env:
    PLAY_CONFIG_JSON: ${{ secrets.PLAY_CONFIG }}
```

The `publishBundle` Gradle command can be used to upload the app on the Play Console:

```yml
- name: Distribute app to Alpha track
  run: ./gradlew :androidApp:bundleRelease :androidApp:publishBundle
```

## Conclusions

And that's all the steps required to automatically publish a Kotlin Multiplatform Android app on the Play Console with a GitHub Action.

Here's the entire GitHub Action for reference:

```yml
name: Android Alpha Release

on:
  push:
    tags:
      - '*-android'

jobs:
  deploy:
    runs-on: ubuntu-latest

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

      - name: Configure Keystore
        run: |
          echo '${{ secrets.KEYSTORE_FILE }}'> release.keystore.asc
          gpg -d --passphrase '${{ secrets.KEYSTORE_PASSPHRASE }}' --batch release.keystore.asc > androidApp/release.keystore
          echo "storeFile=release.keystore" >> keystore.properties
          echo "keyAlias=$KEYSTORE_KEY_ALIAS" >> keystore.properties
          echo "storePassword=$KEYSTORE_STORE_PASSWORD" >> keystore.properties
          echo "keyPassword=$KEYSTORE_KEY_PASSWORD" >> keystore.properties
        env:
          KEYSTORE_KEY_ALIAS: ${{ secrets.KEYSTORE_KEY_ALIAS }}
          KEYSTORE_KEY_PASSWORD: ${{ secrets.KEYSTORE_KEY_PASSWORD }}
          KEYSTORE_STORE_PASSWORD: ${{ secrets.KEYSTORE_STORE_PASSWORD }}

      - name: Create Firebase json
        run: |
          echo "$FIREBASE_JSON" > androidApp/google-services.json.b64
          base64 -d -i androidApp/google-services.json.b64 > androidApp/google-services.json
        env:
          FIREBASE_JSON: ${{ secrets.FIREBASE_JSON }}

      - name: Create Google Play Config file
        run: |
          echo "$PLAY_CONFIG_JSON" > play_config.json.b64
          base64 -d -i play_config.json.b64 > play_config.json
        env:
          PLAY_CONFIG_JSON: ${{ secrets.PLAY_CONFIG }}

      - name: Distribute app to Alpha track
        run: ./gradlew :androidApp:bundleRelease :androidApp:publishBundle
```

You can check the action [on GitHub](https://github.com/prof18/feed-flow/blob/main/.github/workflows/android-alpha-release.yaml)