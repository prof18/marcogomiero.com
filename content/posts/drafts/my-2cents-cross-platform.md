---
layout: post
title:  "My 2 Cents about cross-platform"
date:   2020-05-09
show_in_homepage: true
tags: [Cross Platform]
---

In this article I want to share my experience with cross-platform solutions and what I think about choosing them for your product. 

Disclaimer: my opinion can be different than yours  

Intro about me, why i am speaking about that.

What I've tried so far:

- React Native -> used in production, not for me i don't like javascript. Some issue with browfield app. Some performance issue in some circumpstances. Link the article i made

- Flutter -> useed for pet projects not yet on big production apps. Dart is better than javascript, but not perfect (semicolons). Better performance that RN, material design highly integrated, very fast to learn and start. I learnt faster dart and flutter rather than RN and javascript. 

- Kotlin Multiplatform -> used for pet project and started integrating in production projects. Not yet stable but this is the future for me. Why? -> next paragraph


Issue with cross-platform solution:

the fact that they want to rewrite the UI. Sharing business logic will resolve the problems. Thats why kotlin multiplatofrm is the solution

But what to use now:

Starting from scratch with an mvp of a new idea -> go with flutter, but sooner or later your find yourself to rewrite things natively (depends on the situation but necessary to have modularization, testing, good scalable actitechure, etc). Or with RN. With flutter is you have graphical and custom artifacts, drawing, anim, etc. 

Short time span app (conference, event, etc) -> go with flutter or R/N

More scalable and structored project (not mvp or projects i'm not sure they works) or to relief burdain of current project -> KMP even if is not yet stable.

For an early startup. Start with flutter and the migrate to kmp when things starts to work.









