---
layout: post
title:  "Friends Tournament - Tournament creation and management made easy"
date:   2020-06-07
show_in_homepage: false
draft: true
tags: [Projects]
---

Today I want to share **Friends Tournament**, a side project that I have been working on for the past year during my spare time. 

{{< figure src="/img/friends-tournament/banner_generic.png" alt="image" >}}

Friends Tournament is a simple application that will help you to manage and organize tournaments with your friends. You can use it to generate videogames tournament, sports tournament, board games tournament, whatever type of tournament do you want. All you need to do is to provide the number of players, the number of matches and the numbers of player that can play at the same time. That's all! Friends Tournament will then generate the matches and the rounds for you. You can then keep the score of each player and a leaderboard will be generated automatically.

## Why

During last summer my friends and I organized a tournament of [Crash Team Racing](https://www.crashbandicoot.com/it/crashteamracing). So we started to set up the different matches and to organize the rounds by randomly extracting the name of the players. It was a boring job that ended with a big chart on paper:

{{< figure src="/img/friends-tournament/paper.jpg" alt="image" >}}

So, how I can speed things up?... Well, let's make an app! And that's why I decided to build Friends Tournament.

## Tech Stack

For this application, I decided to go with Flutter so I managed to test how things works with a complex project. And I can say that, as native mobile engineer, I'm satisfied with the result. Spoiler alert: I'll share my 2cents about cross-platform solutions in a future article, so make sure to follow me if you are interested!

For the business logic, I decided to go with the [Bloc pattern](https://medium.com/flutterpub/architecting-your-flutter-project-bd04e144a8f1) because I really like it! If you are interested about the structure of the project, you can give a look to the code because Friends Tournament is open source and its available on [GitHub](https://github.com/prof18/Friends-Tournament).

## Download

For the time being, Friends Tournament is only available for Android. Maybe in the future I'll release the iOs version too.

{{<rawhtml>}}

<div align="center"><a href=""><img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/images/generic/en_badge_web_generic.png" width="200px"/></a></div>

{{</rawhtml>}}

If you have any feedback, if you notice a bug or if you want to contribute for example with the translation, feel free to drop a comment below or tweet me [@marcoGomier](https://twitter.com/marcoGomier).



 
