---
layout: post
title:  "How to publish a Kotlin Multiplatform iOS app on the App Store with GitHub Actions"
date:   2024-04-07
show_in_homepage: false
draft: true
---

> **SERIES: Publishing a Kotlin Multiplatform Android, iOS, and macOS app with GitHub Actions.**
>
> - Part 1: [How to publish a Kotlin Multiplatform Android app on the Play Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-android)
> - Part 2: How to publish a Kotlin Multiplatform iOS app on the App Store with GitHub Actions
> - Part 3: How to publish a Kotlin Multiplatform macOS app on the App Store with GitHub Actions - *Coming soon*
> - Part 4: How to publish a Kotlin Multiplatform macOS app outside the App Store with GitHub Actions - *Coming soon*

It's been almost a year since I started working on [FeedFlow](https://www.feedflow.dev/), an RSS Reader available on Android, iOS, and macOS, built with Jetpack Compose for the Android app, Compose Multiplatform for the desktop app, and SwiftUI for the iOS app.

To be faster and "machine-agnostic" with the deployments, I decided to have a CI (Continuous Integration) on GitHub Actions to quickly deploy my application to all the stores (Play Store, App Store for iOS and macOS, and on GitHub release for the macOS app).

In this post, I will show how to deploy a Kotlin Multiplatform iOS app on the iOS App Store. This post is part of a series dedicated to setting up a CI for deploying a Kotlin Multiplatform app on Google Play, Apple App Store for iOS and macOS, and on GitHub releases for distributing a macOS app outside the App Store. To keep up to date, you can check out the other instances of the series in the index above or follow me on [Mastodon](https://androiddev.social/@marcogom) or [Twitter](https://twitter.com/marcoGomier).

## Triggers

A trigger is necessary to trigger the GitHub Action. I've decided to trigger a new release when I add a tag that ends with the platform name, in this case, `-ios`. So, for example, a tag would be `0.0.1-ios`.

```yml
on:
  push:
    tags:
      - '*-ios'
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

### Set Xcode version 

The `maxim-lobanov/setup-xcode` action can be used to set the Xcode version:

```yml
  - uses: maxim-lobanov/setup-xcode@v1
    with:
      xcode-version: latest-stable
```

I prefer to explicitly set the version to ensure that I am prepared for any future changes that may require a specific version different from the default provided by GitHub runners.

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

## [Optional] Firebase configuration or other secrets

GitHub secrets can be leveraged to store any sensitive stuff or configuration that can't be exposed to version control.

To do so, any file can be encoded with `base64` and saved inside a GitHub secret.

```bash
base64 -i myfile.extension
```

Then, the GitHub action can decode the content and create the file. For example, here's the step for the Firebase plist configuration:

```yml
  - name: Create Firebase Plist
    run: |
      echo "$FIREBASE_PLIST" > iosApp/GoogleService-Info.plist.b64
      base64 -d -i iosApp/GoogleService-Info.plist.b64 > iosApp/GoogleService-Info.plist
    env:
      FIREBASE_PLIST: ${{ secrets.FIREBASE_PLIST }}
```

## Setup signing certificates

Every iOS application must be signed to be distributed in the app store. The certificates required to sign an iOS application for distribution are called `Apple development` and `Apple distribution`. Those certificates can be generated and downloaded from [the Apple Developer website](https://developer.apple.com/account/resources/certificates/add) by uploading a Certificate Signing Request. 

This request can be obtained from the Keychain app on macOS by opening the menu `Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority`. In the form that will appear, an email must be added, and the `Save to disk` option must be selected. The CA Email address field can be blank instead because the request will be saved on the disk. More information can be found [in the Apple documentation](https://support.apple.com/en-am/guide/keychain-access/kyca2793/mac).

The certificates can be imported into GitHub Action by using the `p12` format, an archive file format for storing many cryptography objects as a single file ([Wikipedia](https://en.wikipedia.org/wiki/PKCS_12)). 

The Keychain app can be used to generate the `p12` file. After downloading the certificates, they must be imported into the Keychain app. Once imported, the certificates can be easily exported by selecting them in the Keychain, right-clicking, and selecting the `Export 2 items…` option. A password will be used to encrypt the `p12` file.

The `import-codesign-certs` action can be used to import the certificate in the `p12` format. To do so, the `p12` file must be encoded in `base64` (as described in the section above) and uploaded into GitHub secrets along with the decryption password.

```yml
  - name: import certs
    uses: apple-actions/import-codesign-certs@v2
    with:
      p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
      p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}
```      


## Setup Provisioning profile

A provisioning profile is required to distribute an iOS app besides signing the app. The provisioning profile ensures that a trusted developer in the Apple Developer Program created and signed the app. This measure prevents unauthorized apps from being used because iOS validates the provisioning profile to ensure that it has been signed with a legitimate certificate from the developer's account. 


use the download-provisioning-profiles action


> the profile verifies that the app is built by a legitimate developer enrolled in the Apple Developer Program. This helps prevent unauthorized apps from running on iPhones and iPads. iOS checks the provisioning profile to confirm it's signed with a valid certificate from your developer account. This ensures the app's integrity and authenticity.

used with the app store connect api, you need 
 *App Store Connect API* https://appstoreconnect.apple.com/access/integrations/api
 
1. Store Issuer ID in GitHub Secret: `APPSTORE_ISSUER_ID`
2. Generate API Key with Access `App Manager`
3. Store Key ID in GitHub Secret: `APPSTORE_KEY_ID`
4. Store Private Key in GitHub Secret: `APPSTORE_PRIVATE_KEY`

you need also app id of the app, you can find it 

Create Identifier for *App IDs* https://developer.apple.com/account/resources/identifiers/list

Create `iOS App Development` Provisioning Profile: https://developer.apple.com/account/resources/profiles/add

Store the name of the provisioning profile in GitHub Secret: `DEV_PROVISIONING_PROFILE_NAME`

Create `App Store Connect` Provisioning Profile: https://developer.apple.com/account/resources/profiles/add

 Store the name of the provisioning profile in GitHub Secret: `DIST_PROVISIONING_PROFILE_NAME`
 
 
```yml
  - name: download provisioning profiles
    uses: apple-actions/download-provisioning-profiles@v2
    with:
      bundle-id: ${{ secrets.BUNDLE_ID }}
      issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
      api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
      api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```
 
## Build the thing

just copy the command


```yml
  - name: build archive
    run: |
      cd iosApp
      
      xcrun xcodebuild \
        -scheme "FeedFlow" \
        -configuration "Release" \
        -sdk "iphoneos" \
        -parallelizeTargets \
        -showBuildTimingSummary \
        -disableAutomaticPackageResolution \
        -derivedDataPath "${RUNNER_TEMP}/Build/DerivedData" \
        -archivePath "${RUNNER_TEMP}/Build/Archives/FeedFlow.xcarchive" \
        -resultBundlePath "${RUNNER_TEMP}/Build/Artifacts/FeedFlow.xcresult" \
        -destination "generic/platform=iOS" \
        DEVELOPMENT_TEAM="${{ secrets.APPSTORE_TEAM_ID }}" \
        PRODUCT_BUNDLE_IDENTIFIER="${{ secrets.BUNDLE_ID }}" \
        CODE_SIGN_STYLE="Manual" \
        PROVISIONING_PROFILE_SPECIFIER="${{ secrets.DEV_PROVISIONING_PROFILE_NAME }}" \
        archive
```


## Generate export options plist file

To produce the application archive, specific parameters, such as the export method, team ID, and provisioning profiles, must be defined. These parameters can be provided through a `plist` file. To prevent these details from being included directly in the source control, the `plist` file can be generated dynamically by incorporating the necessary data from GitHub secrets. The file will be saved in the directory where the compiled code is stored, as specified in the previous section. In this case, `${RUNNER_TEMP}/Build`.

```yml
  - name: "Generate ExportOptions.plist"
    run: |
      cat <<EOF > ${RUNNER_TEMP}/Build/ExportOptions.plist
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>destination</key>
          <string>export</string>
          <key>method</key>
          <string>app-store</string>
          <key>signingStyle</key>
          <string>manual</string>
          <key>generateAppStoreInformation</key>
          <true/>
          <key>stripSwiftSymbols</key>
          <true/>
          <key>teamID</key>
          <string>${{ secrets.APPSTORE_TEAM_ID }}</string>
          <key>uploadSymbols</key>
          <true/>
          <key>provisioningProfiles</key>
          <dict>
            <key>${{ secrets.BUNDLE_ID }}</key>
            <string>${{ secrets.DIST_PROVISIONING_PROFILE_NAME }}</string>
          </dict>
        </dict>
      </plist>
      EOF
```

## Export archive and generate IPA

just copy the command  

    
```yml
  - id: export_archive
    name: export archive
    run: |
      xcrun xcodebuild \
        -exportArchive \
        -exportOptionsPlist "${RUNNER_TEMP}/Build/ExportOptions.plist" \
        -archivePath "${RUNNER_TEMP}/Build/Archives/FeedFlow.xcarchive" \
        -exportPath "${RUNNER_TEMP}/Build/Archives/FeedFlow.xcarchive" \
        PRODUCT_BUNDLE_IDENTIFIER="${{ secrets.BUNDLE_ID }}"
      
      echo "ipa_path=${RUNNER_TEMP}/Build/Archives/FeedFlow.xcarchive/FeedFlow.ipa" >> $GITHUB_ENV
```    
    
## Upload on testflight    
    
to upload on testflight, need stuff created on the provision step

```yml
  - uses: Apple-Actions/upload-testflight-build@v1
    with:
      app-path: ${{ env.ipa_path }}
      issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
      api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
      api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```     
     
    
## Conclusions

And that's all the steps required to automatically publish a Kotlin Multiplatform iOS app on TestFlight with a GitHub Action.

Here's the entire GitHub Action for reference:
    
```yml
name: iOS TestFlight Release
on:
  push:
    tags:
      - '*-ios'

jobs:
  deploy:
    runs-on: macos-14
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Setup Gradle
        uses: ./.github/actions/setup-gradle
        with:
          gradle-cache-encryption-key: ${{ secrets.GRADLE_CACHE_ENCRYPTION_KEY }}

      - name: Create Firebase Plist
        run: |
          echo "$FIREBASE_PLIST" > iosApp/GoogleService-Info.plist.b64
          base64 -d -i iosApp/GoogleService-Info.plist.b64 > iosApp/GoogleService-Info.plist
        env:
          FIREBASE_PLIST: ${{ secrets.FIREBASE_PLIST }}

      - name: import certs
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}

      - name: download provisioning profiles
        uses: apple-actions/download-provisioning-profiles@v2
        with:
          bundle-id: ${{ secrets.BUNDLE_ID }}
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}

      - name: build archive
        run: |
          cd iosApp
          
          xcrun xcodebuild \
            -scheme "FeedFlow" \
            -configuration "Release" \
            -sdk "iphoneos" \
            -parallelizeTargets \
            -showBuildTimingSummary \
            -disableAutomaticPackageResolution \
            -derivedDataPath "${RUNNER_TEMP}/Build/DerivedData" \
            -archivePath "${RUNNER_TEMP}/Build/Archives/FeedFlow.xcarchive" \
            -resultBundlePath "${RUNNER_TEMP}/Build/Artifacts/FeedFlow.xcresult" \
            -destination "generic/platform=iOS" \
            DEVELOPMENT_TEAM="${{ secrets.APPSTORE_TEAM_ID }}" \
            PRODUCT_BUNDLE_IDENTIFIER="${{ secrets.BUNDLE_ID }}" \
            CODE_SIGN_STYLE="Manual" \
            PROVISIONING_PROFILE_SPECIFIER="${{ secrets.DEV_PROVISIONING_PROFILE_NAME }}" \
            archive

      - name: "Generate ExportOptions.plist"
        run: |
          cat <<EOF > ${RUNNER_TEMP}/Build/ExportOptions.plist
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
            <dict>
              <key>destination</key>
              <string>export</string>
              <key>method</key>
              <string>app-store</string>
              <key>signingStyle</key>
              <string>manual</string>
              <key>generateAppStoreInformation</key>
              <true/>
              <key>stripSwiftSymbols</key>
              <true/>
              <key>teamID</key>
              <string>${{ secrets.APPSTORE_TEAM_ID }}</string>
              <key>uploadSymbols</key>
              <true/>
              <key>provisioningProfiles</key>
              <dict>
                <key>${{ secrets.BUNDLE_ID }}</key>
                <string>${{ secrets.DIST_PROVISIONING_PROFILE_NAME }}</string>
              </dict>
            </dict>
          </plist>
          EOF

      - id: export_archive
        name: export archive
        run: |
          xcrun xcodebuild \
            -exportArchive \
            -exportOptionsPlist "${RUNNER_TEMP}/Build/ExportOptions.plist" \
            -archivePath "${RUNNER_TEMP}/Build/Archives/FeedFlow.xcarchive" \
            -exportPath "${RUNNER_TEMP}/Build/Archives/FeedFlow.xcarchive" \
            PRODUCT_BUNDLE_IDENTIFIER="${{ secrets.BUNDLE_ID }}"
          
          echo "ipa_path=${RUNNER_TEMP}/Build/Archives/FeedFlow.xcarchive/FeedFlow.ipa" >> $GITHUB_ENV

      - uses: Apple-Actions/upload-testflight-build@v1
        with:
          app-path: ${{ env.ipa_path }}
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```
     
You can check the action [on GitHub](https://github.com/prof18/feed-flow/blob/main/.github/workflows/ios-testflight-release.yaml)     