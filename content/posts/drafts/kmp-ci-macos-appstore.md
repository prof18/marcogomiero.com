---
layout: post
title:  "How to publish a Kotlin Multiplatform macOS app on the App Store with GitHub Actions"
date:   2024-04-07
show_in_homepage: false
draft: true
---

## Signing Certificated

Certificates for code sign. Use the import-codesign-certs action to import certificate exported in base 64 in the p12 format. The p12 format requires a password to unpack the certificate
    

    Create a new certificate:
    
    - Mac App Distribution
    - Mac Installer Distribution

To create the certificate, you need a Certificate Signing Request. You can create it from the keychain

https://support.apple.com/guide/keychain-access/request-a-certificate-authority-kyca2793/mac

put your email and select the "Saved to disk" option. Leave the CA Email Address field empty.

On the apple website, https://developer.apple.com/account/resources/certificates/add you can upload the request and create the certificates you need. 

    
download then, add in the macos keychain and then export both of them. Select them, right click, "Export 2 items..", store it on you device and give them a password that you will use next also on the Ci
    
transform the certificates to base64 with 
`base64 -i certificate.p12`
    
## Provision Profile

Required if you want to publish on test flight and app store

two app ids are required

 one for your app, and another one for the JVM runtime. 

App ID for app: com.yoursitename.yourappname (format: YOURBUNDLEID)
App ID for runtime: com.oracle.java.com.yoursitename.yourappname (format: com.oracle.java.YOURBUNDLEID)


Create two provision profile, one for the app id for the app and one for the runtime

Go Distribution > Mac App Store Connect

Create the two provision profiles, download them and 


Make sure to rename your provisioning profile you created earlier to embedded.provisionprofile and the provisioning profile for the JVM runtime to runtime.provisionprofile.

Do not create a guide on how to create them, but how to use them and point to the jetbrains docs

https://github.com/JetBrains/compose-multiplatform/blob/master/tutorials/Signing_and_notarization_on_macOS/README.md

maybe link also the article about sandboxing and stuff. 

## Build the pkg

copy the code on how to build the thing

## Upload to testflight 

used with the app store connect api, you need 
 *App Store Connect API* https://appstoreconnect.apple.com/access/integrations/api
 
 . Store Issuer ID in GitHub Secret: `APPSTORE_ISSUER_ID`
1. Generate API Key with Access `App Manager`
2. Store Key ID in GitHub Secret: `APPSTORE_KEY_ID`
3. Store Private Key in GitHub Secret: `APPSTORE_PRIVATE_KEY`







https://github.com/prof18/feed-flow/blob/main/.github/workflows/desktop-macos-testflight-release.yaml



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

      - name: Update Licenses file
        run: ./gradlew desktopApp:exportLibraryDefinitions -PaboutLibraries.exportPath=src/main/resources/

      - name: Create path variables
        id: path_variables
        run: |
          tag=$(git describe --tags --abbrev=0 --match "*-desktop")
          version=$(echo "$tag" | sed 's/-desktop$//')
          name="FeedFlow-${version}.pkg"
          path="desktopApp/build/release/main-release/pkg/${name}"
          echo "TAG=$tag" >> $GITHUB_OUTPUT
          echo "VERSION=$version" >> $GITHUB_OUTPUT
          echo "RELEASE_PATH=$path" >> $GITHUB_OUTPUT

      - name: Create Properties file
        run: |
          echo "is_release=true" >> desktopApp/src/jvmMain/resources/props.properties
          echo "sentry_dns=$SENTRY_DNS" >> desktopApp/src/jvmMain/resources/props.properties
          echo "version=$VERSION" >> desktopApp/src/jvmMain/resources/props.properties
        env:
          SENTRY_DNS: ${{ secrets.SENTRY_DNS }}
          VERSION: ${{ steps.path_variables.outputs.VERSION }}

      - name: Create PKG
        run: ./gradlew packageReleasePkg -PmacOsAppStoreRelease=true

      - name: Upload reports
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: reports
          path: |
            **/build/compose/logs/*  

      - uses: Apple-Actions/upload-testflight-build@v1
        with:
          app-type: 'osx'
          app-path: ${{ steps.path_variables.outputs.RELEASE_PATH }}
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}

```