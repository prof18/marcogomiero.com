---
layout: post
title: "Sliding Doors: ten years of RSS-Parser"
date: 2026-06-17
show_in_homepage: false
---

Today marks ten years since the first commit of [**RSS-Parser**](https://github.com/prof18/RSS-Parser). *TEN YEARS*.

I want to use this opportunity to reflect on the journey of this library, the sliding doors moments along the way, and the chain of events that made RSS-Parser an important part of my career.

The bare bones of the library started earlier, though; it was 2015 when I wrote my first app that I’ve published to the Play Store. This app was for reading the articles of the tech blog that I was collaborating with (for a while I was reviewing apps, phones, consumer tech - that’s when I fell in love with mobile). The blog was built (of course) with the good old WordPress, and at the time I discovered that you can have the published articles formatted in XML - yes, I discovered the existence of RSS.

<div style="display: flex; justify-content: center;">
  <figure style="margin: 0; text-align: center;">
    <img src="/img/rss-parser-ten-years/app-early-1.webp" alt="Early iteration of the app" style="max-width: 300px; border-radius: 8px;" />
    <figcaption><em>That's an early iteration of the app</em></figcaption>
  </figure>
</div>

<br>

<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <figure style="margin: 0; flex: 1; text-align: center;">
    <img src="/img/rss-parser-ten-years/app-early-2.webp" alt="Early iteration of the app" style="max-width: 100%; border-radius: 8px;" />
    <figcaption><em>Another early iteration</em></figcaption>
  </figure>
  <figure style="margin: 0; flex: 1; text-align: center;">
    <a href="/img/rss-parser-ten-years/app-final.webp">
      <img src="/img/rss-parser-ten-years/app-final.webp" alt="Final shape of the app" style="max-width: 100%; border-radius: 8px;" />
    </a>
    <figcaption><em>And that's the final shape</em></figcaption>
  </figure>
</div>

It took a couple of years to realize (and to actually learn) that some parts of my app could be extracted and made available for other developers to use. So I decided to go for it and published the first version of RSS-Parser. And at the time, I went with JCenter because publishing to Maven Central was too complicated for the young me.

It was a very good learning experience: still with Java, AsyncTasks and more - good old days!

During the summer of the release in 2017, the first *sliding door* happened: I met with [Gian Segato](https://giansegato.com/) to chat about starting to collaborate at Uniwhere. Having a library developed and published early in my career gave my pedigree “more points.” This led to my first job, the foundation and the “trampoline” of my career, and to knowing amazing people who became close friends.

The year after, I decided it was time to convert it to Kotlin and Coroutines: another great learning experience that I’ve shared in an article.

Fast forward to 2022. During this period, my original app disappeared, but that doesn’t mean RSS-Parser *disappeared*: I kept improving and fixing it.

Coincidentally, during the 2022 Christmas break, I decided it was enough to keep up with the news and stuff on social media and various websites, so I planned to come back to RSS daily. But I didn’t find an app that fully satisfied me across all platforms (I use daily Android, iOS, and macOS). So I started ~~mumbling and complaining~~ chatting with Gian as usual, and I thought that maybe I could build an RSS app: *“How hard can it be?”*™️.

That was the perfect idea (and the perfect Christmas break project); I could build the app I wanted while also dogfooding RSS-Parser and improving it. And *that’s* how [**FeedFlow**]() was born.

I started with Android, and in February 2023 I had the first (ugly) version running.

<div style="display: flex; justify-content: center;">
  <figure style="margin: 0; text-align: center;">
    <a href="/img/rss-parser-ten-years/feedflow-android-first.webp">
      <img src="/img/rss-parser-ten-years/feedflow-android-first.webp" alt="First Android version of FeedFlow" style="max-width: 300px; border-radius: 8px;" />
    </a>
    <figcaption><em>First Android version</em></figcaption>
  </figure>
</div>

Now it was time for iOS and macOS, but this meant making RSS-Parser multiplatform with Kotlin Multiplatform. This was another interesting challenge. I had the first dev version supporting iOS and the JVM in March, so I could proceed with FeedFlow development and have the first version I could use myself.

<div style="display: flex; justify-content: center;">
  <figure style="margin: 0; text-align: center;">
    <a href="/img/rss-parser-ten-years/feedflow-ios-first.webp">
      <img src="/img/rss-parser-ten-years/feedflow-ios-first.webp" alt="First iOS version of FeedFlow" style="max-width: 300px; border-radius: 8px;" />
    </a>
    <figcaption><em>First iOS version</em></figcaption>
  </figure>
</div>

After [the public launch](https://www.marcogomiero.com/posts/2023/introducing-feed-flow/) of FeedFlow on July 31, 2023, it was time to go back into finalizing the stable version of the multiplatform version of RSS-Parser. The stable version officially [landed in August](https://github.com/prof18/RSS-Parser/releases/tag/6.0.0).

This was a huge effort that required some refactoring to change some patterns and ease the introduction of Kotlin Multiplatform. Also, I took the opportunity to fix some wrong decisions the young me made; it was the perfect occasion to introduce breaking changes. I wrote down all the learnings [into a blog post](https://www.marcogomiero.com/posts/2025/android-lib-to-kmp/).

Making RSS-Parser Multiplatform and creating FeedFlow were other *sliding doors* to amazing opportunities.

In 2024, I got the chance to talk about the release process of FeedFlow [at KotlinConf](https://www.youtube.com/watch?v=JRlR4NWX-nc).

<div style="display: flex; justify-content: center;">
  <figure style="margin: 0; text-align: center; width: 100%;">
    <a href="/img/rss-parser-ten-years/kotlinconf-2024.webp">
      <img src="/img/rss-parser-ten-years/kotlinconf-2024.webp" alt="Talking at KotlinConf 2024" style="max-width: min(600px, 100%); width: 100%; height: auto; max-height: unset; border-radius: 8px;" />
    </a>
    <figcaption><em>Talking at KotlinConf 2024</em></figcaption>
  </figure>
</div>


And in 2025, I got the “golden ticket” to join WWDC live at Apple Park in Cupertino.

<div style="display: flex; justify-content: center;">
  <figure style="margin: 0; text-align: center; width: 100%;">
    <a href="/img/rss-parser-ten-years/wwdc-keynote.webp">
      <img src="/img/rss-parser-ten-years/wwdc-keynote.webp" alt="WWDC Keynote" style="max-width: min(600px, 100%); width: 100%; height: auto; max-height: unset; border-radius: 8px;" />
    </a>
    <figcaption><em>WWDC Keynote</em></figcaption>
  </figure>
</div>

Seeing the FeedFlow icon on the big screen at WWDC was astonishing.

<div style="display: flex; justify-content: center;">
  <figure style="margin: 0; text-align: center; width: 100%;">
    <a href="/img/rss-parser-ten-years/feedflow-wwdc.webp">
      <img src="/img/rss-parser-ten-years/feedflow-wwdc.webp" alt="FeedFlow icon at WWDC" style="max-width: min(600px, 100%); width: 100%; height: auto; max-height: unset; border-radius: 8px;" />
    </a>
    <figcaption><em>FeedFlow icon at WWDC</em></figcaption>
  </figure>
</div>

With FeedFlow running in the wild, I could observe RSS-Parser working with a whole different set of feeds and scenarios, which made me keep improving the library with new fixes, more edge cases covered, and so on.  

Next, I added support for more platforms, including macOS, tvOS, watchOS, and even JS and Wasm, and the library was featured [in the official Kotlin docs](https://kotlinlang.org/docs/multiplatform/migrate-from-android.html#migrate-to-multiplatform-libraries]) on migrating advanced Android apps to Kotlin Multiplatform.

And now RSS-Parser is powering more than 2K daily users through FeedFlow across Android, iOS, macOS, Linux, and Windows, something I could never have imagined 10 years ago.

That’s a crazy journey. 
Thank you to everyone who opened an issue, sent a PR, or reported a feed that broke the parser in the most creative ways; you made this library better than I could have on my own.

I will always be grateful to that little library I decided to publish ten years ago.

**To ten more years and beyond!**