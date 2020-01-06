---
layout: post
title:  "Flutter or React Native, a cross-platfrom dilemma - How they work - (Part 3)"
date:   2019-09-09
draft: true
---

Welcome to the third part of this article series about React Native and Flutter. In the latest episode, we have talked about User Interfaces and how to build them in the two frameworks. In this article, we'll go deeper under the hoods to understand how things work. But I will not go deeper with lot's of details and implementation things, because I want to make you understand how the thing works at a high level. 

But, before moving on, I suggest you read the previous articles of the series if you have lost them.

> [Flutter or React Native, a cross-platform dilemma - Introduction - (Part 1)](http://marcogomiero.com/posts/2019/rn-flutter-dilemma-1-intro/)

<br>

> [Flutter or React Native, a cross-platform dilemma - How to build User Interfaces - (Part 2)](http://marcogomiero.com/posts/2019/rn-flutter-dilemma-2-ui/)

## React Native

Let's start by analyzing the internals of Rect Native. React Native has an internal infrastructure that is called "the **Bridge**" and that is built at runtime. The main purpose of the bridge is to create a connection between the native part of the application and the Javascript one, so it can be possible to call native code from the javascript part of the application and vice-versa. The communication between the two different parts is managed it's event-driven and in the following gif, you can see an example of that kind of communication.

{{< figure src="/img/flutter-rn/js-bridge.gif" alt="image" caption="An example of communication between Native and Javascript" >}}

Let's analyze what happens here. Let's suppose that we have opened our application. Then, the native code notifies to the bridge that the app has been opened and so the bridge generates a serialized payload that contains that information. This payload is sent to the javascript code that decides what to do; for example, it decides to render the simple "Hello World" App that we showed in the latest episode. So again, the information is sent back to the bridge that serializes that information and it sends it back to the native code. At this time, the native code has received all the information that it needs to render the view of the application. 
These exchanges of information are performed in an asynchronous way: the messages are collected in a queue that is flushed every 5 ms by default to avoid too much message sending in a short period of time. Nevertheless, this message passing causes some delays especially with a complex layout or long list with complex items. 
In fact, the Facebook team is working on a new architecture (codename Fabric) to address this issue and let the UI update synchronously. In just two words, they will get rid of the bridge and the serialization and there will be a JavaScript Interface to allow the communication between the Javascript part and the native one. For more information about Fabric I suggest you look to this talk: [_React Native's New Architecture - Parashuram N - React Conf 2018_](https://www.youtube.com/watch?v=UcqRXTriUVI)

## Flutter

Flutter instead works in a completely different way. In fact, all the widgets are managed and rendered using an engine. In particular, the widgets are rendered in a canvas using Skia, a 2-d graphics library. 

{{< figure src="/img/flutter-rn/engine.png" alt="image" caption="Flutter Engine" >}}

In this way, there isn't a continuous communication between the "cross-platform technology" and the native part and everything is faster. Moreover, all the Dart code is compiled to native code to speed things up ( be aware that the compilation to native code is performed only for production build and for this reason debug builds can be slower ). 

## Comparison

So, in React Native there is a correspondence between the components and the native widgets while Flutter includes its own widgets. This choice has pro and cons. Imagine that Apple and Google update the TextView with some flowers on the shape: an app developed with React Native will ( or better should ) show the flowers without any intervention while an app developed with Flutter won't show it until the Flutter team will add it on their custom TextView. This is a con, because we need to wait another update if there are new things available on the native UI. The pro instead is that there isn't any delay due to the bridge initialisation and the runtime translation needed to enable the communication between the javascript part and the native one. 







<!-- What happens under the hood, difference between bridge and flutter engine. Make a word about new RN architecture. Maybe talk about the internal UI representation?  -->
