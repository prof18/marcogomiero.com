---
layout: post
title:  "TODO KMP CI macOS Private dist"
date:   2024-04-07
show_in_homepage: false
draft: true
---

Do not write step by step stuff, but link the jetbrains doc, if required.

## Signing Certificates

Certificates for code sign. Use the import-codesign-certs action to import certificate exported in base 64 in the p12 format. The p12 format requires a password to unpack the certificate
    

 Create a new certificate:
    
 - Developer ID Application

To create the certificate, you need a Certificate Signing Request. You can create it from the keychain

https://support.apple.com/guide/keychain-access/request-a-certificate-authority-kyca2793/mac

put your email and select the "Saved to disk" option. Leave the CA Email Address field empty.

On the apple website, https://developer.apple.com/account/resources/certificates/add you can upload the request and create the certificates you need. 

    
download, add in the macos keychain and then export it Select them, right click, "Export", store it on you device and give them a password that you will use next also on the Ci
    
transform the certificates to base64 with 
`base64 -i certificate.p12`
    
    
## APP id
    

Create Identifier for *App IDs* https://developer.apple.com/account/resources/identifiers/list

## Build stuff:

copy what's needed

## Notarization

 Apple scans the app for malicious content using an automated system
 macOS uses Gatekeeper, a security feature that restricts app installation by default. Notarization can help bypass Gatekeeper warnings for identified developers, making installation smoother.By default, Gatekeeper helps ensure that all downloaded software has been signed by the App Store or signed by a registered developer and notarized by Apple. Both the App Store review process and the notarization pipeline are designed to ensure that apps contain no known malware. 

An app specific pwd is required:
https://support.apple.com/en-us/102654

https://appleid.apple.com/account/manage/section/security

copy the command here for notarization


## Distribute the stuff whenever you want

Show the example on uploading stuff on github releases





https://github.com/prof18/feed-flow/blob/main/.github/workflows/desktop-macos-release.yaml

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
          key: ${{ runner.os }}-v1-${{ hashFiles('*.gradle.kts') }}

      # Developer ID Application
      - name: Import signing certificate
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.SIGNING_CERTIFICATE_P12_DATA_MACOS }}
          p12-password: ${{ secrets.SIGNING_CERTIFICATE_PASSWORD_MACOS }}

      - name: Update Licenses file
        run: ./gradlew desktopApp:exportLibraryDefinitions -PaboutLibraries.exportPath=src/main/resources/

      - name: Create path variables
        id: path_variables
        run: |
          tag=$(git describe --tags --abbrev=0 --match "*-desktop")
          version=$(echo "$tag" | sed 's/-desktop$//')
          name="FeedFlow-${version}.dmg"
          path="desktopApp/build/release/main-release/dmg/${name}"
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

      - name: Create DMG
        run: ./gradlew packageReleaseDmg

      - name: Upload reports
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: reports
          path: |
            **/build/compose/logs/*  

      - name: Notarization
        run: |
          xcrun notarytool submit $RELEASE_PATH --apple-id $APPLE_ID_NOTARIZATION --password $NOTARIZATION_PWD --team-id $APPSTORE_TEAM_ID --wait
          xcrun stapler staple $RELEASE_PATH
        env:
          APPLE_ID_NOTARIZATION: ${{ secrets.APPLE_ID_NOTARIZATION }}
          APPSTORE_TEAM_ID: ${{ secrets.APPSTORE_TEAM_ID }}
          NOTARIZATION_PWD: ${{ secrets.NOTARIZATION_PWD }}
          RELEASE_PATH: ${{ steps.path_variables.outputs.RELEASE_PATH }}

      - name: Upload binaries to release
        uses: svenstaro/upload-release-action@v2
        with:
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          file: ${{ steps.path_variables.outputs.RELEASE_PATH }}
          tag: ${{ steps.path_variables.outputs.TAG }}
          overwrite: true
          draft: true
          body: "Release ${{ steps.path_variables.outputs.VERSION }}"


```