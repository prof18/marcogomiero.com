---
layout: post
title: "Sunsetting spoton: Android 16 killed the hotspot toggle trick"
date: 2025-12-16
show_in_homepage: false
---

[**spoton**](https://play.google.com/store/apps/details?id=com.prof18.spoton&hl=en-US) is getting sunset.

I started this project because I had a very specific (and very lazy) problem: I wanted to enable my phone hotspot without taking my phone out of my pocket. I do it often when I’m travelling or working somewhere without stable Wi-Fi, and every time it was the same ritual: unlock phone, quick settings, find the hotspot tile, toggle, put phone away.

At some point, I thought: *“This should be a button on my wrist.”*

That idea turned into *spoton*: a tiny Wear OS app plus a companion phone app that let me toggle the hotspot from my watch. It was fun to research and build, and (to my surprise) it even got featured by Android Police.

> [This smartwatch app puts a button on your wrist that toggles your phone's hotspot](https://www.androidpolice.com/spoton-app-toggle-hotspot-from-wear-os-smartwatch/)

{{< youtube bunQ0YLxVQQ >}}

But with Android 16, Google changed the rules in a way that makes spoton’s core trick impossible for a third-party Play Store app.

This post is a short explanation of what the app was doing under the hood, how the watch and phone were talking to each other, and what I tried to make it work on Android 16 anyway.

## The “hack”

spoton never used a public Android API to enable the hotspot, because there isn’t one that works for normal third-party apps.

Instead, the phone app uses reflection to call hidden tethering APIs. The core logic lives in a class I called [HotspotManager](https://github.com/prof18/spoton/blob/main/app/src/main/java/com/prof18/spoton/HotspotManager.kt).

In short:

- To start tethering, it looks up `ConnectivityManager.startTethering(...)` via reflection and invokes it.
- That hidden method requires an instance of `ConnectivityManager$OnStartTetheringCallback`.
- Since that callback is hidden as well, I used `ProxyBuilder` from the [Dexmaker library](https://github.com/linkedin/dexmaker) to dynamically create an instance at runtime.
- To stop tethering, it calls (again via reflection) `ConnectivityManager.stopTethering(...)`.
- To read the hotspot status, it calls (also via reflection) `WifiManager.isWifiApEnabled()`.

Here’s the full method, for convenience:

```kotlin
internal fun startTethering(ctx: Context) {
    try {
        val outputDir = ctx.codeCacheDir
        val proxy = ProxyBuilder.forClass(getOnStartTetheringCallbackClass())
            .dexCache(outputDir)
            .handler { proxy, method, args ->
                when (method.name) {
                    "onTetheringStarted" -> {
                        Log.v(TAG, "onTetheringStarted")
                    }
                    "onTetheringFailed" -> {
                        Log.v(TAG, "onTetheringFailed")
                    }
                    else -> {
                        ProxyBuilder.callSuper(proxy, method, args)
                    }
                }
            }
            .build()

        val connMng =
            ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        for (method in connMng.javaClass.methods) {
            if (method.name == "startTethering" && method.parameterCount == 3) {
                Log.v(TAG, "Invoking startTethering method.")
                method.invoke(connMng, 0, false, proxy)
                isHotspotEnabledFlow.update { true }
                Messenger.sendMessage(status = true, context = ctx)
            }
        }
    } catch (e: Throwable) {
        Log.e(TAG, "Error while starting tethering", e)
    }
}
```

## How the phone talked to the watch

Communication with the Wear OS app was very simple: just passing a few booleans around using the Data Layer API. You can check the official docs for more information here:  
[Handle Data Layer events on Wear](https://developer.android.com/training/wearables/data/events).

## What changed in Android 16

With Android 16, the hidden `startTethering` / `stopTethering` methods now has been officially moved to the `TetheringManager` class and they also require the `TETHER_PRIVILEGED` permission, which is only granted to system apps (pre-installed or signed by the OEM). For a Play Store app, that’s a hard stop.

Even if you reach the API via reflection, the framework now enforces permissions in a way that you can’t bypass without system privileges. In my experiments, the outcome was consistently the same: tethering simply fails with  
`TETHER_ERROR_NO_CHANGE_TETHERING_PERMISSION (Error 14)`.

At that point, continuing would mean requiring root access or doing some weird manual tinkering, which is not what I want.

## What happens now

- spoton still works on Android 15 and below, and it will remain on the [Play Store](https://play.google.com/store/apps/details?id=com.prof18.spoton&hl=en-US) (until some random policy change won't make me update it anymore).
- spoton does not work on Android 16+ as a normal Play Store app.
- I’m sunsetting the project rather than keeping it half-broken.
- The project is [now open source](https://github.com/prof18/spoton), so if someone wants to explore it or play with it, it’s all there.

I built spoton for myself first, and it delivered exactly what I wanted for a good while. It was also a great excuse to play with Wear OS, tiles, complications, and a very small “do one thing well” app.

Android evolves, and sometimes that means the end of a hack. This is one of those times.

If you used spoton: thanks. That’s genuinely the coolest outcome a tiny weekend hack can get.
