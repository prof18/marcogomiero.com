---
layout: post
title:  "TODO KMP CI iOS"
date:   2024-04-07
show_in_homepage: false
draft: true
---



Other stuff for the CI

## Signing Certificated

Certificates for code sign. Use the import-codesign-certs action to import certificate exported in base 64 in the p12 format. The p12 format requires a password to unpack the certificate
    

    Create a new certificate:
    
    - Apple development 
    - Apple distribution

To create the certificate, you need a Certificate Signing Request. You can create it from the keychain

https://support.apple.com/guide/keychain-access/request-a-certificate-authority-kyca2793/mac

put your email and select the "Saved to disk" option. Leave the CA Email Address field empty.

On the apple website, https://developer.apple.com/account/resources/certificates/add you can upload the request and create the certificates you need. 

    
download then, add in the macos keychain and then export both of them. Select them, right click, "Export 2 items..", store it on you device and give them a password that you will use next also on the Ci
    
transform the certificates to base64 with 
`base64 -i certificate.p12`
    

## Provision profiles

use the download-provisioning-profiles action


> the profile verifies that the app is built by a legitimate developer enrolled in the Apple Developer Program. This helps prevent unauthorized apps from running on iPhones and iPads. iOS checks the provisioning profile to confirm it's signed with a valid certificate from your developer account. This ensures the app's integrity and authenticity.

used with the app store connect api, you need 
 *App Store Connect API* https://appstoreconnect.apple.com/access/integrations/api
 
 . Store Issuer ID in GitHub Secret: `APPSTORE_ISSUER_ID`
1. Generate API Key with Access `App Manager`
1. Store Key ID in GitHub Secret: `APPSTORE_KEY_ID`
1. Store Private Key in GitHub Secret: `APPSTORE_PRIVATE_KEY`

you need also app id of the app, you can find it 

Create Identifier for *App IDs* https://developer.apple.com/account/resources/identifiers/list

Create `iOS App Development` Provisioning Profile: https://developer.apple.com/account/resources/profiles/add

Store the name of the provisioning profile in GitHub Secret: `DEV_PROVISIONING_PROFILE_NAME`

Create `App Store Connect` Provisioning Profile: https://developer.apple.com/account/resources/profiles/add

 Store the name of the provisioning profile in GitHub Secret: `DIST_PROVISIONING_PROFILE_NAME`
 
 
## Build the thing

just copy the command


## Need ExportOptions.plist

specifies how the app should be exported. export method, team ID, and provisioning profiles.

## Export archive and generate IPA

just copy the command  

    
## Upload on testflight    
    
to upload on testflight, need stuff created on the provision step
     
     
    
https://github.com/prof18/feed-flow/blob/main/.github/workflows/ios-testflight-release.yaml    
    
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
        env:
          PROJECT_DIR: iosApp
          SCHEME: FeedFlow
          CONFIGURATION: Release
          SDK: iphoneos
        run: |
          cd ${PROJECT_DIR}
          
          xcrun xcodebuild \
            -scheme "${SCHEME}" \
            -configuration "${CONFIGURATION}" \
            -sdk "${SDK}" \
            -parallelizeTargets \
            -showBuildTimingSummary \
            -disableAutomaticPackageResolution \
            -derivedDataPath "${RUNNER_TEMP}/Build/DerivedData" \
            -archivePath "${RUNNER_TEMP}/Build/Archives/${SCHEME}.xcarchive" \
            -resultBundlePath "${RUNNER_TEMP}/Build/Artifacts/${SCHEME}.xcresult" \
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
        env:
          SCHEME: FeedFlow
        run: |
          xcrun xcodebuild \
            -exportArchive \
            -exportOptionsPlist "${RUNNER_TEMP}/Build/ExportOptions.plist" \
            -archivePath "${RUNNER_TEMP}/Build/Archives/${SCHEME}.xcarchive" \
            -exportPath "${RUNNER_TEMP}/Build/Archives/${SCHEME}.xcarchive/${SCHEME}.ipa" \
            PRODUCT_BUNDLE_IDENTIFIER="${{ secrets.BUNDLE_ID }}"
          
          echo "ipa_path=${RUNNER_TEMP}/Build/Archives/${SCHEME}.xcarchive/${SCHEME}.ipa/${SCHEME}.ipa" >> $GITHUB_OUTPUT

      - uses: Apple-Actions/upload-testflight-build@v1
        with:
          app-path: ${{ steps.export_archive.outputs.ipa_path }}
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```
     
     