---
layout: post
title:  "The curious case of a weird VerifyError crash"
date:   2025-04-06
show_in_homepage: false
---

> This post can be considered as a journal entry. I had to clear my thoughts and vent off through writing after spending time debugging this issue. Maybe it will be helpful for future references or an example of the process to follow in such cases.

{{< figure src="/img/bug-hunting-story/coffe.jpeg"  link="/img/bug-hunting-story/coffe.jpeg" >}}

The other day I was doing the usual dependency update routine of [FeedFlow](https://www.feedflow.dev) when I discovered a runtime crash that happened in the release version (so with R8 enabled) after updating the Android Gradle Plugin (AGP, in the rest of the article) to version 8.7.

```
java.lang.VerifyError: Verifier rejected class t0.r: 
void t0.r.h(t0.r) failed to verify: void t0.r.h(t0.r): 
[0x5] register v0 has type Precise Reference: java.lang.Integer 
but expected Precise Reference: L0.j (declaration of 't0.r' 
appears in /data/app/~~_cXzOXLfk4yLcG5sVXzehg==/com.prof18.feedflow-D_r-DXHofuTMpeXekhA6iA==/base.apk)
```

Interesting.

A first good old web search didn’t bring up anything, and neither did asking LLMs, so down the rabbit hole I went to understand the issue.

First thought: it could be something weird happening with R8 (_spoiler: it is_). But I haven’t found anything interesting while checking AGP release notes.

I immediately thought, it must be some mess-up with Compose, Compose Multiplatform, Compose Compiler, or libraries that use Compose. (Yes, scars from the past, even though it should be less painful now with Kotlin 2.0 and the compiler being in the Kotlin repo).

Let’s double check every version and combination of libraries to be sure there’s no mess. Even after an analysis of transitive dependencies (`./gradlew androidApp:dependencies`), nothing suspicious came up.

All right, it must be an issue with the Kotlin version. Let’s try again with different combinations. *Nope, still crashing*.

At this point I decided to turn on the best debugger in town: _going for a walk_.

While strolling around, I came up with an attack plan: I’m gonna delete (temporarily, of course) all the code in the Android module, comment out all the dependencies, and only keep the `Application` class and the `MainActivity`.

With this plan in mind, I started. First, I tried to set up Compose again: it worked! So, Compose is not the issue anymore.

Next step: Koin. I added back the code that creates the dependency graph in the `Application` class and boom! The crash was back. Ok, then it must be some mess up with Koin and Compose versions. After trying all the combinations, the crash was still there.

All right, then it has to be something in the dependency graph. So I commented everything in the graph definition and started going step by step, uncommenting pieces one at a time. After a bunch of waiting, I got the suspect: `feedFetcherRepository.fetchFeeds()` is making the app crash!

Another deep dive with the same approach until I found a new suspect: `dateFormatter.getDateMillisFromString(pubDate)`.

In particular, the list with the `DateTimeFormat`  for parsing a date string with [kotlin-datetime](https://github.com/Kotlin/kotlinx-datetime) is causing the crash. Very weird!

```kotlin
private val formats = listOf<DateTimeFormat<DateTimeComponents>>(
    ISO_DATE_TIME_OFFSET,
    RFC_1123,

    // Tue, 5 Sep 2017 09:58:38 +0000
    Format {
        ..
	}
)	
```

After a search in the issues of the library, I found something similar! An issue that was closed because the problem could not be reproduced, both on  [JetBrains](https://github.com/Kotlin/kotlinx-datetime/issues/402) and [Google](https://issuetracker.google.com/issues/351858994) sides. But now [there's a reproducer!](https://github.com/prof18/DateTimeR8IssueRepro).

Apparently, the issue could be that R8 removes classes that are backing some properties with delegation.

Now that I’ve found the cause of this crash, I’m relieved and I can postpone updating AGP without overthinking.




