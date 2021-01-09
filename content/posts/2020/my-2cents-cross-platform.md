---
layout: post
title:  "My 2 Cents about cross-platform"
date:   2020-08-04
show_in_homepage: true
tags: [Cross Platform]
---

During my journey as a mobile developer, I had the chance to try and give a look at some cross-platform solutions both for work and fun reasons. Today, I want to share my thoughts and considerations about them and why/when you should use cross-platform. I hope that these thoughts will be helpful to anyone that is in the process of choosing the right solution for their product.

> **Disclaimer**: in this article, I will share some opinions based on my experience and they can apply to your situation or not. If you want to share your considerations, feel free to reach me out on Twitter [@marcoGomier](https://twitter.com/marcoGomier).

## Possible solutions

Out in the wild, there are plenty of different cross-platform solutions. However, in this post, I will focus only on the most used (that are also ones that provide an experience as much close as the native one) and the most promising. 

{{< figure src="/img/2cents-cross/google-trend-cross.png" alt="image" caption="Google Trends for the past 12 months. *Last update July 2020*" >}}

First of all, I've excluded all the solutions that use web technologies to render the app in a WebView (like [Cordova](https://cordova.apache.org/) or [Ionic](https://ionicframework.com/)) because they don't have adequate performances (And I haven't used them for this reason). The solutions on which I will focus are: React Native, Flutter, and Kotlin Multiplatform. (yes, there is also Xamarin but I never used it and it seems not so appealing in the community).

### React Native
I've used React Native in a production brownfield (a yet existing app with some feature developed with React Native. More info about brownfield: [Wikipedia](https://en.wikipedia.org/wiki/Brownfield_(software_development))) app ([Uniwhere](https://www.uniwhere.com/) and we ditched it for performance reasons). I don't like it because I don't like Javascript and I prefer statically typed languages (yes I could use Typescript, but I prefer a nominative type system rather than a structural one).

### Flutter: 
I've used Flutter in both pet projects ([Friends Tournament](https://github.com/prof18/Friends-Tournament)) and production apps. Flutter has better performances with complex layouts and UIs (For a complete comparison between Flutter and React Native, you can look [to the series of articles that I've written](https://www.marcogomiero.com/posts/2020/rn-flutter-dilemma-series/)) and uses Dart as language. Dart is a strongly typed language but the type can also be inferred. In just two words, I can say that Dart is a mixture of Javascript and an Object-Oriented language. So (as you may guess), if I have to choose between Flutter and React Native I will choose Flutter. 

### Kotlin Multiplatform
I've used Kotlin Multiplatform in both pet projects (not yet released) and production app ([Uniwhere](https://www.uniwhere.com/)). Even if it is an experimental feature, it is stable enough to be used in production applications. Kotlin Multiplatform has a completely different approach to code sharing with respect to React Native and Flutter. Later on, I will explain why, but for the time being, all you need to know is that, with Kotlin Multiplatform, you will not share between the platform all the code but only some parts (for example the business logic, the network layer, the persistence layer, etc.)

## Issue with cross-platform solutions

The real bottleneck of every cross-platform framework is the UI code. Every solution tries to unify the UI declaration between two (or more) platforms that works differently under the hood. 

React Native uses a "bridge" to create a connection between the native part of the application and the Javascript one, so it can be possible to call native code from the javascript part of the application and vice-versa. In this way, a React Component (for example a `<Text>`) will be mapped to a native component (a `TextView` on Android and `UILabel` on iOs). 

Flutter instead draws the widgets by itself on a canvas, using Skia (an open-source 2D graphic library managed by Google and used by Chrome, Chrome OS, Android, Firefox, and many others). 

> For a comparison of how Flutter and React Native works, you can look [to the third episode of the comparison series](https://www.marcogomiero.com/posts/2020/rn-flutter-dilemma-3-under-hood/). 

These approaches (of course) has pros and cons. 

With the "**React Native solution**", the pro is that the framework is transparent to OS changes: if Google or Apple decides to tweak the appearance of an existential widget, everything will work (or better, should) without any changes. The con instead is that there will be some delay due to the bridge initialization and the runtime translation needed to enable the communication between the Javascript part and the native one (you'll notice it with complex layouts).

With **Flutter** instead, everything is faster because there is not the time for the translation and the widgets are drawn in a canvas by Skia. The con is that the widgets are not the system one. Visually are the same but they are not the same. And if there will be new native widgets from Google and Apple we have to wait that the Flutter team adds them.

And that's why **Kotlin Multiplatform** is interesting. As stated in the [documentation](https://kotlinlang.org/docs/reference/multiplatform.html):

> "multiplatform is not about compiling all code for all platforms"

In fact, every platform has its uniqueness, different behaviors and it's very difficult to find a common pattern that "unifies the differences". So the solution that Kotlin Multiplatform provides is the possibility to share some part of the code, for example, the business logic, the data persistence layer, the network layer, etc. 

> tl;dr; share as much [NO UI] code as possible. 

But, if you need to access platform-specific code (and it happens in the business logic, for example, the SQL driver), you can use the [_expected/actual_](https://kotlinlang.org/docs/reference/platform-specific-declarations.html) mechanism. In this way, a common module can define expected declarations, and a platform module can provide actual declarations corresponding to the expected ones. 

So, since the solution to the cross-platform problem is not to share UI code, do I need to ditch solutions like React Native and Flutter?

## What to use now? 

Well Well, no. 

> _Every solution can be used and it's useful in different situations_. 

For example, for a short span application, i.e. an app for a conference, for a concert, a festival, an event, etc., using a cross-platform solution like Flutter or React Native is a good idea. In fact, you need to develop in a (usually) short time an app that will be used by the attendees that use different platforms for a limited amount of time. 

> When you need a short time to market and maintenance/longevity are not important, go cross-platform

Another example is when you have an idea and you want to validate it in the market (aka doing an MVP -  Minimum Viable Product). In this stage, velocity is the key: you need to prove as fast as you can that your idea fits in the market. So, going with a cross-platform solution is a good idea because you avoid wasting time and resources in developing for two different platforms. Of course, this is applicable if you want to cover all the platforms. If you have an idea iOS only, going cross-platform is no-sense.

> If you are developing an MVP, go cross-platform 

After a successful MVP stage, you found yourself with a proven idea and you need to build a product that can scale. So, you need a proper structure, scalable, testable, and easily maintainable. And inevitable at this point you will have some tech debt for the rush and quick decision taken during the MVP phase. Potentially you'll need to rewrite the two clients with a native solution, without "hacky" solutions because after proving that "it can work", you have to prove that "it can scale". (For a deeper analysis about tech choices in an early-stage startup, look [to the article written by my friend Gian.](https://giansegato.com/essays/a-technical-framework-for-early-stage-startups/))

> Switch to native if you have issues on scaling

In this situation, **Kotlin Multiplatform** can be really useful.
With two native applications, with platform-specific UI code, sharing the common business logic code is a good solution. In fact, you can write it one and test it once without any dependencies from the native platform.

## The perfect recipe?

Unfortunately, there isn't a perfect recipe. Every project has its peculiar characteristics and could be very hard to find the perfect solution. One project can work perfectly with a cross-platform solution while another can be a big big pain. 

> Choosing the right technology is part of the game. 

An important point to keep in mind is that if the experience with a particular choice is not successful as expected, you must have the consciousness to admit the defeat and try another solution (I know, it's not easy).

I hope that by sharing my experience, I will help you to make a great decision. If you want to share your considerations, feel free to reach me out on Twitter [@marcoGomier](https://twitter.com/marcoGomier).