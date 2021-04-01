---
layout: post
title:  "Flutter or React Native, a cross-platform dilemma - Introduction - (Part 1)"
date:   2019-12-12
images:
  - https://www.marcogomiero.com/img/flutter-rn/trends.jpeg
show_in_homepage: false
---

These days you have certainly heard about cross-platform mobile development, in particular about the "senior" [React Native](https://facebook.github.io/react-native/) and the "freshman" [Flutter](https://flutter.dev/). 

Today, I want to start a series of articles to understand the two frameworks. In particular, I want to describe their differences, their weaknesses, their strength... so, all you need to know to help your choice. 

In this article, I want to introduce the two frameworks with a historical overview and an analysis of the languages that they use. Next, in the following articles, I will move the focus on how to build User Interfaces with these two frameworks and how they work internally. 

## History

Before starting with the comparison, I think that a little bit of history is mandatory. The first version of React Native has been developed during an internal Facebook hackathon in 2013 and a first version has been previewed two years later in January 2015. Finally, in May 2015, React Native has been officially launched and open-sourced. Flutter instead is younger and a first embryonal version has been revealed during the Dart Dev Summit of 2015. After two years, an alpha release has been released during the Google I/O 2017 and the final 1.0 release came out in December 2018.

Today, React Native is the standard de facto for cross-platform development. In fact, during the years React Native has gained success because it can provide a "native feel" (in a following article I will explain how this is possible) and not a weird rendering with HTLM and CSS inside a WebView like for example [Cordova](https://cordova.apache.org/) or [PhoneGap](https://phonegap.com/). Lots of famous apps are using React Native, for example, Facebook, Instagram, Pinterest, Instagram, Discord and much more. 

Despite the youngness, Flutter is gaining lots of attention in the "cross-platform square". In fact, there are already some (complex) apps that use Flutter, for example, Google Ads, the Alibaba's app Xianyu. 

{{< figure src="/img/flutter-rn/trends.jpeg" alt="image" caption="Google Search Trends for \"React Native\" and \"Flutter\"." >}}

## Language

The language used by React Native is Javascript, a language that you can love or you can hate, there isn't a half-measure. In general, people with an object-oriented background could encounter difficulties when they use Javascript for the first time. Some "weird" arguments can be the type conversion, the prototype-based inheritance, the fact that code can fail silently, etc. These are not random facts but happened to me to deal with them. Also, there is a little bit of confusion around the Javascript ecosystem: lots of libraries, frameworks, multiple approaches to perform the same thing. If you want to (or you have to) use React Native, I suggest you go with [Typescript](http://www.typescriptlang.org/) especially if you come from an object-oriented background. 

Flutter instead uses [Dart](https://dart.dev/), an open-source, object-oriented language developed by Google in 2011. Google wanted to create a language that improves some of the pitfalls that Javascript has, for example, the handling of the types. So Dart is a strongly typed language but the type can be inferred. Dart is capable both to compile to native code (ARM & x64) for mobile, desktop and backend and to transpile to Javascript for the web. The syntax is very similar to object-oriented languages and the learning curve to learn the language is flat.

Going with React Native can be tempting if you already have skills in web development since you will be going to use Javascript or Typescript. With Flutter instead, you have to learn a new language, even if is very simple to learn. However, with React Native often happens that you have to deal with Native code, especially for linking new third party libraries. With Flutter instead is rare that you have to touch native code unless you want to develop a custom plugin that uses native APIs.

And for today is enough. After this brief introduction, in the next episode, we'll talk about how to build User Interfaces.
