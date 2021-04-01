---
layout: post
title:  "Flutter or React Native, a cross-platform dilemma - How to chose + Bonus - (Part 4)"
date:   2020-03-23
show_in_homepage: false
---

Welcome to the fourth and last part of this article series about React Native and Flutter. 

[In the first episode](http://marcogomiero.com/posts/2019/rn-flutter-dilemma-1-intro/), we have introduced the two frameworks with some history and with a comparison between the languages that they use.

[In the second episode](http://marcogomiero.com/posts/2019/rn-flutter-dilemma-2-ui/), we have talked about User Interfaces and how to build them. 

[In the third episode](http://marcogomiero.com/posts/2019/rn-flutter-dilemma-3-under-hood/), we went deeper under the hood to understand how things work.

And now it's time to wrap things up by trying to understand how to choose the right framework for you.

But before moving on, a quick consideration about cross-platform is necessary. Cross-platform in general is not bad, but it is not absolutely better than native development. Going cross-platform it's a choice with compromises based on specific situations. For example, you are a web-first company that wants to provide a mobile app or you have constraints in your team or you want to try a new feature that you are not sure if it is going to be successful. 
Cross-platform can be really useful for example for the event's/conference's applications, i.e. for applications that have a short life span.  
And finally, another useful situation for using cross-platform is when you have to validate a new idea, where time to market is everything and you should not spend lots of time for covering all the platforms. If you are interested in some tips on how to choose the best stack for an MVP, give a look [to this article of my friend Gian Segato](https://giansegato.com/essays/a-technical-framework-for-early-stage-startups/).

The most important thing to keep in mind is that if the troubles of using a cross-platform solution became higher than benefits, you should take a step back, [like Airbnb did some time ago](https://medium.com/airbnb-engineering/sunsetting-react-native-1868ba28e30a). I know, it will not be an easy step but if things are not working as expected it could be the only viable solution.

But should I choose Flutter or React Native? Well, there isn't a correct answer valid for everyone.

I think that if your application will have complex and very custom layouts, long lists with complex layouts you should go with Flutter because it is more performant than React Native. Instead, if you want to incorporate a cross-platform feature inside an existent native application (the Frankenstein feature that we have discussed in the third episode of the series) you should choose React Native because it is more stable (Note: I compared this feature in the application of the company where I work during summer 2019 - things may be changed). Furthermore, I think that another reason to choose Flutter is that Dart is a language thought and developed also for mobile while Javascript is not. But of course, this is a personal thought, if you are more familiar with Javascript, go with it!

And that's all for this comparison between Flutter and React Native. I hope that these articles will be helpful to make the right decision. If you want to share your consideration and what led you to choose between the two frameworks, feel free to reach me out on Twitter [@marcoGomier](https://twitter.com/marcoGomier).

## BONUS

Yes, there is a bonus for you. This series of articles have been extrapolated from a talk that I give out during 2019 to both local meetups and international conferences (for more info about my talks, visit [the talks section of the website](https://www.marcogomiero.com/talks/)).
Here's the video and the slides of the talk:

### Slide:
[Flutter or React Native, a cross-platform dilemma | DevFest Veneto 19](https://speakerdeck.com/prof18/flutter-or-react-native-a-cross-platform-dilemma-devfest-veneto-19)

<script async class="speakerdeck-embed" data-id="02923dd271234bfe93db88058e894bab" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

### Video: 
{{< youtube NqQY4K2hjXo >}}
