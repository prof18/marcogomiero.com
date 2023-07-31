---
layout: post
title:  "Introducing FeedFlow, a minimalistic and opinionated RSS Reader"
date:   2023-07-31
show_in_homepage: false
---

After months of work, I can finally announce the release of [**FeedFlow**](https://www.feedflow.dev/), a minimalistic and opinionated RSS Reader that I've built for myself and that's now available on [Android](https://play.google.com/store/apps/details?id=com.prof18.feedflow), [iOS](https://apps.apple.com/us/app/feedflow-rss-reader/id6447210518), and [macOS](https://github.com/prof18/feed-flow/releases/latest).

## Motivation

I've started (again) to stay up to date by building my own feed instead of relying on feeds ordered and decided by someone else. But I wasn't completely satisfied with the readers already out there ("I can build a better one"™️). What I want for an RSS reader is the possibility of easily going through my feed and being able to open the article that I want to read on the respective website. Yes, you read it right.

There are different reasons:
- the majority of websites with an RSS feed don't share the article's full content because they want you to go on their website;
- if an article is worth a long read and I want to save it, I'm using a read-it-later app ([Omnivore](https://omnivore.app));
- I want to use a "disposable" browser and not my main one for reading, where I can nuke navigation data or auto-handle cookie banners (DuckDuckGo or Firefox Focus).

Another motivation for creating my own reader is that I'm developing and maintaining since a while [RSSParser](https://github.com/prof18/RSS-Parser), an Android library for parsing RSS feeds (yes, I'm a fan of that). So, with an RSS Reader, I could have a perfect product for dogfooding my own library.

With that in mind, I decided to start the development.

## Features

FeedFlow offers a minimalistic feeds list and it opens the articles on their respective websites. The browser where to open the articles can be chosen on mobile. For example, you can open an article on DuckDuckGo or Firefox Focus with all the trackers disabled and then just kill all the navigation data. In this way, the reading experience is separated from your main browser instance.

FeedFlow also supports importing your existing RSS collection through OPML files so you don't have to start from scratch.

If some features are missing, feel free to suggest them!

## Some tech details

As mentioned above, FeedFlow is backed by [RSSParser](https://github.com/prof18/RSS-Parser) and RSSParser is now multiplatform! The support is still in alpha and not yet merged, but you can check the [open PR](https://github.com/prof18/RSS-Parser/pull/116) and try the alpha artifacts.

FeedFlow is built with Jetpack Compose for the Android app, Compose Multiplatform for the desktop app, and SwiftUI for the iOS app. All the logic (even the ViewModel) is shared using Kotlin Multiplatform. I will write in the future some articles that will go in deep about the architecture, so stay tuned for more details!

In the meantime, you can check the code on [Github](https://github.com/prof18/feed-flow), because FeedFlow is open source.

## Conclusions

From today, FeedFlow is available on Android, iOS, and macOS. Feel free to try it out and report any bugs! Feel free also to suggest any feature that could be missing.

- [Google Play](https://play.google.com/store/apps/details?id=com.prof18.feedflow)
- [Apple Store](https://apps.apple.com/us/app/feedflow-rss-reader/id6447210518)
- [macOS latest release](https://github.com/prof18/feed-flow/releases/latest)
- [Github](https://github.com/prof18/feed-flow)
- [Website](https://www.feedflow.dev/)
