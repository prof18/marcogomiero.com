---
layout: post
title:  "TODO KMP CI Android"
date:   2024-04-07
show_in_homepage: false
draft: true
---


## Keystore

copy the stuff


## Play Console service account json




https://github.com/prof18/feed-flow/blob/main/.github/workflows/android-alpha-release.yaml

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
          key: ${{ runner.os }}-v1-${{ hashFiles('*.gradle.kts') }}

      - name: Configure Keystore
        run: |
          echo '${{ secrets.KEYSTORE_FILE }}' > release.keystore.asc
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