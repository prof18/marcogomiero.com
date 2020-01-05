---
layout: post
title:  "Flutter or React Native, a cross-platfrom dilemma - How they work - (Part 3)"
date:   2019-09-09
draft: true
---

Welcome to the third part of this article series about React Native and Flutter. In the latest episode we have talked about User Interfaces and how to build it in the two frameworks. In this article we'll go deeper under the hoods to understand how things works. But I will not going deeper with lot's of details and implementation things, because I want to make you understand how thing works at an high level. 

But, before moving on, I suggest you to read the previous articles of the series if you have lost them.

> [Flutter or React Native, a cross-platform dilemma - Introduction - (Part 1)](http://marcogomiero.com/posts/2019/rn-flutter-dilemma-1-intro/)

<br>

> [Flutter or React Native, a cross-platform dilemma - How to build User Interfaces - (Part 2)](http://marcogomiero.com/posts/2019/rn-flutter-dilemma-2-ui/)

## React Native

Let's start by analyzing the internals of Rect Native. React Native has an internal infrastructure that is called "the **Bridge**" and that is built at runtime. The main purpose of the bridge is to create a connection between the native part of the application and the Javascript one, so it can be possible to call native code from the javascript part of the application. The communication between the two different parts is managed it's event driven and in the following gif you can see an example of that kind of communication.

{{< figure src="/img/flutter-rn/js-bridge.gif" alt="image" caption="An example of communication between Native and Javascript" >}}

Let's analyze what happens here. Let's suppose that we have opened our application. Then, the native code notifies to the bridge that the app has been opened and so the bridge generates a serialized payload that contains that information. This payload is sent to the javascript code that decides what to do; for example it decide to render the simple "Hello World" App that we showed in the latest episode. So again, the information is sent back to the bridge that serializes that information and it send it back to the native code. At this time, the native code has received all the information that it needs to render the view of the application. 






<!-- What happens under the hood, difference between bridge and flutter engine. Make a word about new RN architecture. Maybe talk about the internal UI representation?  -->
