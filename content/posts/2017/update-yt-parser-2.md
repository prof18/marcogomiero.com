---
layout: post
title:  "New big update for Youtube Parser: video stats and much more"
description: "Youtube Parser is an Android Library that helps you to handle Youtube videos from a specific channel. Let's see how it works!"
images: 
  - https://miro.medium.com/max/1400/1*rNC9B9nCUquBYtkfVv2aWQ.jpeg
date:   2017-06-23
show_in_homepage: false
tags: [Android]
---
Finally I've released a new big update for YoutubeParser. For people who don't know what I'm talking about, don't worry now I'm going to explain all.

**YoutubeParser** is the first **Android library** that I ever wrote. With this library it is possible to get information of videos from Youtube channels. These information are:

* Title 
* Link  
* Thumbnail, with three different image size. 


After a year I've released this new big update, named 2.0, that introduces a bunch of new things. First of all, now it is possible to load more than 50 videos from the same channel. 50 is the maximum number of videos that can be retrieved with a single request.

Furthermore you can also get the statistics of a video:

* View
* Like 
* Dislike 
* Favorite Count
* Comment Count 

The source code of the library is on Github together with a sample application that shows what you can do with the library.

* [Click here to view the library on Github](https://github.com/prof18/YoutubeParser) 
* [Click here to show the code of the sample app](https://github.com/prof18/YoutubeParser/tree/master/app") 
* [Click here to download the app](https://github.com/prof18/YoutubeParser/blob/master/YoutubeParser.apk) 

<img src="https://raw.githubusercontent.com/prof18/YoutubeParser/master/Screen.png" width="50%" height="50%" align="center">

Of course the library is available also on jCenter so you can easily add the dependency on Gradle.

```gradle
dependencies {
  compile 'com.prof.youtubeparser:youtubeparser:2.0'
}
```

Now let's look how it works. First of all you need to create a new *Parser* Object and then you have to create the url to load the data by using the method *generateRequest*. This method takes as parameter four values:

* The Channel ID of a Youtube Channel. For example, for this link *youtube.com/channel/UCVHFbqXqoYvEWM1Ddxl0QDg*, the Channel ID is: *UCVHFbqXqoYvEWM1Ddxl0QDg*
* The maximum number of videos to show. This value can be maximum 50.
* The type of ordering of the videos. It is possible to choose between two different type of ordering: by date or by views. To select the chosen value you have to use the constants: *Parser.ORDER_DATE* and *Parser.ORDER_VIEW_COUNT*
* The API Key. The key is a *BROSWER API KEY* and to create it you can follow [this guide](https://support.google.com/cloud/answer/6158862?hl=en#creating-browser-api-keys)

If the data are correctly retrieved, you can do your stuff inside the *onTaskCompleted*. Here you have two variable: an *ArrayList* of *Video* items that you can use to populate your view for instance and a *token* that is necessary to load more data (see below for more details).

If there are some error on the process, you can handle the situation in the *onError()* method.

```java
import com.prof.youtubeparser.Parser;
import com.prof.youtubeparser.models.videos.Video;

Parser parser = new Parser();

//(CHANNEL_ID, NUMBER_OF_RESULT_TO_SHOW, ORDER_TYPE ,BROSWER_API_KEY)
//https://www.youtube.com/channel/UCVHFbqXqoYvEWM1Ddxl0QDg --> channel id = UCVHFbqXqoYvEWM1Ddxl0QDg
//The maximum number of result to show is 50
//ORDER_TYPE --> by date: "Parser.ORDER_DATE" or by number of views: "ORDER_VIEW_COUNT"  
String url = parser.generateRequest(CHANNEL_ID, 20, Parser.ORDER_DATE, API_KEY);
parser.execute(url);
parser.onFinish(new Parser.OnTaskCompleted() {

    @Override
    public void onTaskCompleted(ArrayList<Video> list, String nextPageToken) {
      //what to do when the parsing is done
      //the ArrayList contains all video data. For example you can use it for your adapter
    }

    @Override
    public void onError() {
        //what to do in case of error
    }
});
```

If you want to retrieved **more videos from the same channel**, the procedure is the same of the above case. The only difference is the method that generate the url; here you have to add the token retrieved from the above procedure.

```java
String url = parser.generateMoreDataRequest(CHANNEL_ID, 20, Parser.ORDER_DATE, API_KEY, nextToken);
```

To get **the statistics of a single video**, the procedure is equivalent of the previous. As you can guess, the first thing to do is to generate the url with the *generateStatsRequest* method. The parameter of this method are:

* The ID of a Youtube Video
* The API Key 

Also here you can handle the result in the *onTaskCompleted* method and any error in the *onError()* method.

```java
import com.prof.youtubeparser.VideoStats;
import com.prof.youtubeparser.models.stats.Statistics;

VideoStats videoStats = new VideoStats();
String url = videoStats.generateStatsRequest(videoId, API_KEY);
videoStats.execute(url);
videoStats.onFinish(new VideoStats.OnTaskCompleted() {
  @Override
  public void onTaskCompleted(Statistics stats) {
      //Here you can set the statistic to a Text View for instance

      //for example:
      String body = "Views: " + stats.getViewCount() + "\n" +
                    "Like: " + stats.getLikeCount() + "\n" +
                    "Dislike: " + stats.getDislikeCount() + "\n" +
                    "Number of comment: " + stats.getCommentCount() + "\n" +
                    "Number of favourite: " + stats.getFavoriteCount();
  }
  @Override
  public void onError() {
      //what to do in case of error
  }
});
```

That's all! Please let me know if you notice any bug or if you have any advice that can improve this library.

