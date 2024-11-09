---
layout: post
title:  "Publishing a Kotlin Multiplatform Android, iOS, and macOS app with GitHub Actions"
date:   2024-05-21
show_in_homepage: true
---

It's been almost a year since I started working on [FeedFlow](https://www.feedflow.dev/), an RSS Reader available on Android, iOS, and macOS built with Jetpack Compose for the Android app, Compose Multiplatform for the desktop app, and SwiftUI for the iOS app.

To be faster and "machine-agnostic" with the deployments, I decided to have a CI (Continuous Integration) on GitHub Actions to quickly deploy my application to all the stores (Play Store, App Store for iOS and macOS, and on GitHub release for the macOS app).

I wrote a series of posts covering how to set up such CI. 

The first post shows how to deploy the Android app on Google Play. 

> [How to publish a Kotlin Multiplatform Android app on Play Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-android)

The second post shows how to deploy the iOS app on the iOS App Store.

> [How to publish a Kotlin Multiplatform iOS app on App Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-ios)

The third post shows how to deploy the macOS app outside the App Store using GitHub Releases.

> [How to publish a Kotlin Multiplatform macOS app on GitHub Releases with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-macos-github-releases)

The last post shows how to deploy a Kotlin Multiplatform macOS app on the App Store.

> [How to publish a Kotlin Multiplatform macOS app on App Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-macos-appstore)

FeedFlow is open source, so the GitHub Actions configuration can be checked [on GitHub](https://github.com/prof18/feed-flow/tree/main/.github/workflows).
