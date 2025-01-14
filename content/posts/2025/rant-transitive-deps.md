---
layout: post
title:  "Watch out for transitive dependencies: an “obvious” rant"
date:   2025-01-14
show_in_homepage: false
---

>  This article is just a short "rant" and a "therapy session" to remind and warn my future self.

I was recently debugging a weird crash affecting some users. The issue was related to navigation, fragments, and backstacks.

After weeks spent trying to reproduce it, reading online reports, and cross-referencing previous libraries and SDK updates, I finally had an illuminating moment after reading about a similar behavior in the [Google Issue Tracker](https://issuetracker.google.com/issues/340202276#comment3). It made me wonder: Could something have changed in the Android Manifest?

{{< figure src="/img/rant-transitive-deps/manifest.jpeg" link="/img/rant-transitive-deps/manifest.jpeg" >}}

And yes, that change was coming to an external library.

The learning here is simple and perhaps obvious, but it's something we tend to forget:

> Always double-check what changes are being introduced when updating a library! 

There might be hidden bugs or unexpected behaviors lurking beneath the surface.