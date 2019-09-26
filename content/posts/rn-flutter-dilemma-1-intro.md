---
layout: post
title:  "Flutter or React Native, a cross platfrom dilemma - Introduction - (Part 1)"
date:   2019-09-09
draft: true
---

<!-- Contestualization: Why I am talking about React Native and Flutter. Brief Historty of the two frameworks, trends, etc. Maybe also the language used. -->

These days you have certainly heard about cross-platform mobile development, in particular about the "senior" React Native and the "freshman" Flutter. 

Today, I want to start a series of articles to clarify the two frameworks. In particular, I want to describe their differences, their weakness, their stretch... so, all you need to know to help your choice. 

<!-- TODO: Mention the argument of the serie -->

## History

Before starting with the comparison, I think that a little bit of history is mandatory. The first version of React Native has been developed during an internal Facebook hackathon in 2013 and a first version has been previewed two years later in January 2015. Finally, in May 2015, React Native has been officially launched and open-sourced. Flutter instead is younger and a first embryonal version has been revealed during the Dart Dev Summit of 2015. After two years, an alpha release has been released during the Google I/O 2017 and the final 1.0 release came out on December 2018.


Despite the youngness, Flutter is gaining lot's of attentions in the "cross-platform square".


<!-- 

React Native si e' imposto quasi come standard nel corso del tempo 

Some of the most famous companies which use RN in their products include Facebook (duh), Tesla, Airbnb, and Walmart. Some apps you might have heard which were built using the framework are Instagram, Pinterest, Discord and Salesforce. Clearly, React Native is suitable for anything from social networks to enterprise software. For more examples of great apps built with RN see this list.

Ma Flutter sta guadagnando parecchio terreno

Ci sono gia; alcune app che lo usano

Some notable projects made using Flutter include Google Ads, which is the engine behind all the ads you see in your search results and many other places; Alibaba’s mobile app called Xianyu, an e-commerce utility used by over 50 million people; and Abbey Road’s Topline, a creative/sharing app for musicians. We also have some experimental experience with Flutter behind our belt. We’re working on a concept app called Lunching, which will help companies simplify the process of ordering lunch to the office, and we’ve completed a Flutter-based notepad, a simple notes app. You can read about what we’ve learned in the process in this series: Part 1, Part 2, and Part 3.


 -->

<!-- TODO: insert image of google trends. With caption as legend -->

## Language 

The language used by React Native is Javascript, a language that you can love or you can hate, there isn't a half-measure. In general, people with an object-oriented background could encounter difficulties when they use Javascript for the first time. Some "weird" arguments can be the type conversion, the prototype-based inheritance, the fact that code can fail silently, etc. These are not random facts but happened to me to deal with them. In addition, there is a little bit of confusion around the javascript ecosystem: lot's of libraries, frameworks, multiple approaches to perform the same thing.

<!-- Inserire meme su javascript -->

Flutter instead uses Dart, an object oriented language developed by Google in 2011. Google wanted to create a language that improves some of the pitfall that Javascript has, for example the handling of the types. So Dart is a strongly typed language but the the type can be inferred. 

<!-- Scrivere che bisogna magari con Flutter bisogna imparare un altro linguagggio, ma e' semplice. Con React Native puo' essere che Javascript lo si conosca gia' -->

<!-- 
 Examplese from others blog post:

 When it comes to React Native, you will use JavaScript or TypeScript, so it should be pretty easy to get started if you have skills in web development. However, I made the experience that you sometimes need to (depending on the project) work with native code (Java/Kotlin and Objective C / Swift). The reason why could be the requirement to use a very specific feature that is not at all or only partly available as a React Native module

  Flutter requires you to use the Dart programming language which is developed by Google and Lars Bak, who was involved in the development of the V8 JavaScript engine. Dart has a C-style syntax (without pointers) and some similarities to JavaScript. Since Dart can transpile into JavaScript, you could run it in a browser.

  As already mentioned before, adding libraries / dependencies to a React Native project can be tricky. Sometimes the linking command react-native link module can lead to several problems (double linking or only partly). Note that this is not necessarily related to React Native, but rather your project configuration or the module you want to link. So you would need to open the Android and iOS projects to manually link the module. With Flutter, this process feels way simpler. Adding the dependency to your yaml file followed by a flutter get packages should be enough. This to be said, there is no node package server that you often have to restart our cache-clean, as in React Native




 -->


<!-- Dart is an open-source, scalable programming language, with robust libraries and runtimes, for building web, server, and mobile apps.
 -->

<!-- Aggiunge qualche link con qualche risorsa riguardo a Dart -->




