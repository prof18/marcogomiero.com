---
layout: post
title:  "My 2 Cents about cross-platform"
date:   2020-05-09
show_in_homepage: true
draft: true
tags: [Cross Platform]
---

During my journey as mobile developer, I had the chance to try and give a look to some cross platform solutions both for work and fun reasons. Today, I want to share my toughts and considerations about them and why/when you should use cross-platform. I hope that these toughts will be helpful to anyone that is in the process of choosing an right solution for their product.

> **Disclaimer**: in this article I will share some opinions based on my experience and they can be applicable to your situation or not.  If you want to share your considerations, feel free to drop a comment below or tweet me [@marcoGomier](https://twitter.com/marcoGomier)

## Possible solutions

Out in the wild there are plenty of differerent cross-platform solutions. However, in this post I will focus only on the most used (that are also the one that provide an experience as much close as the native one) and the most promising. 

TODO: redo the picture!! Just cordova is the city!!!!

{{< figure src="/img/2cents-cross/google-trend-cross.png" alt="image" caption="Google Trends for the past 12 months. *Last update May 2020*" >}}

First of all, I've excluded all the solutions that uses web technologies to render the app in a WebView (like [Cordova](https://cordova.apache.org/) or [Ionic](https://ionicframework.com/)) because they don't have adequate performances. 


## Issue with cross platform solutions

## What to use now? 

---

React Native, Flutter, Ionic, Xamarin.


In this article I want to share my experience with cross-platform solutions and what I think about choosing them for your product. 

Disclaimer: my opinion can be different than yours  

Intro about me, why i am speaking about that.

What I've tried so far:

- React Native -> used in production, not for me i don't like javascript. Some issue with browfield app. Some performance issue in some circumpstances. Link the article i made

- Flutter -> useed for pet projects not yet on big production apps. Dart is better than javascript, but not perfect (semicolons). Better performance that RN, material design highly integrated, very fast to learn and start. I learnt faster dart and flutter rather than RN and javascript. 

- Kotlin Multiplatform -> used for pet project and started integrating in production projects. Not yet stable but this is the future for me. Why? -> next paragraph


Issue with cross-platform solution:

the fact that they want to rewrite the UI. Sharing business logic will resolve the problems. Thats why kotlin multiplatofrm is the solution

Unify UI declaration across platforms  

React Native: call native widgets through a “bridge”
PRO: Use of native widgets
CONS: The bridge causes delays  

Flutter: uses its own widget

PRO: No delays, really fast
CONS: Use of custom widgets 

Different platforms have different pattern 

“Overall, multiplatform is not about compiling all code for all platforms”

Compiling code for all platforms has limitations:

Every platform has unique APIs
Impossible to cover all platforms API

Solution:

Share as much code as needed
Access platform APIs through the expected/actual mechanism

Share part of the code like business logic, connectivity..


But what to use now:

Starting from scratch with an mvp of a new idea -> go with flutter, but sooner or later your find yourself to rewrite things natively (depends on the situation but necessary to have modularization, testing, good scalable actitechure, etc). Or with RN. With flutter is you have graphical and custom artifacts, drawing, anim, etc. 

Short time span app (conference, event, etc) -> go with flutter or R/N

More scalable and structored project (not mvp or projects i'm not sure they works) or to relief burdain of current project -> KMP even if is not yet stable.

For an early startup. Start with flutter and the migrate to kmp when things starts to work.









