---
date: 2023-08-11T17:45:00Z
title: "FeedFlow"
type: "Android, iOS and macOS App"
github: https://github.com/prof18/feed-flow
playStore: https://play.google.com/store/apps/details?id=com.prof18.feedflow
appStore: https://apps.apple.com/us/app/feedflow-rss-reader/id6447210518
---

FeedFlow is a minimalistic and opinionated RSS Reader that's available on Android, iOS, and macOS.

The majority of websites with an RSS feed don't share the article's content because they want you to go on their website. For this reason, FeedFlow always opens the original website, but the browser can be chosen (on mobile). For example, an article can be opened on DuckDuckGo or Firefox Focus with all the trackers disabled and then just kill all the navigation data. In this way, the reading experience is separated from the main browser instance.

An existing RSS collection can be easily imported: FeedFlow offers full and easy import and export capabilities through OPML files.

FeedFlow is built with Jetpack Compose, Compose Multiplatform, and SwiftUI. All the logic is shared using Kotlin Multiplatform.

FeedFlow uses [RSSParser](https://github.com/prof18/RSS-Parser), an RSS parsing library that I've built for Android and that now is Multiplatform!