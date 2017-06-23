---
layout: post
title:  "New big update for YoutubeParser: video stats and much more"
date:   2017-06-22
---
<p class="intro"><span class="dropcap" align="justify">F</span>inally I've released a new big update for YoutubeParser. For people who don't know what I'm talking about, don't worry now I'm going to explain all.

YoutubeParser is the first Android library that I ever wrote. With this library it is possible to get information of videos from Youtube channels. These information are:
* Title;
* Link;
* Thumbnail, with three different image size.

After a year I've released this new big update, named 2.0, that introduces a bunch of new things. First of all, now it is possible to load more than 50 videos from the same channel. 50 is the maximum number of videos that can be retrieved with a single request.

Furthermore you can get the statistics of a video:
* View;
* Like;
* Dislike;
* Favorite Count;
* Comment Count.

The source code of the library is on Github together with a sample application that shows what you can do with the library.
* [Click here to view the library on Github][github]
* [Click here to show the code of the sample app][app-code]
* [Click here to download the app.][app-download]

Of course the library is available also on jCenter so you can easily add the dependency on Gradle.

{% highlight ruby %}
dependencies {
  compile 'com.prof.youtubeparser:youtubeparser:2.0'
}
{% endhighlight %}

Now let's look how it works. First of all you need to create a new *Parser* Object and then you have to create the url to load the data by using the method *generateRequest*. This method takes as parameter four values:
* The Channel ID of a Youtube Channel. For example, for this link *youtube.com/channel/UCVHFbqXqoYvEWM1Ddxl0QDg*, the Channel ID is: *UCVHFbqXqoYvEWM1Ddxl0QDg*
* The maximum number of videos to show. This value can be maximum 50.
* The type of ordering of the videos. It is possible to choose between two different type of ordering: by date or by views. To select the chosen value you have to use the constants: *Parser.ORDER_DATE* and *Parser.ORDER_VIEW_COUNT*
* The API Key. The key is a *BROSWER API KEY* and to create it you can follow [this guide](https://support.google.com/cloud/answer/6158862?hl=en#creating-browser-api-keys)

```Java
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
To create a BROSWER API KEY you can follow
<a href="https://support.google.com/cloud/answer/6158862?hl=en#creating-browser-api-keys"> this guide.</a>

##### To load more videos from the same channel:    
```Java
String url = parser.generateMoreDataRequest(CHANNEL_ID, 20, Parser.ORDER_DATE, API_KEY, nextToken);
```
Remember that this request can be made only AFTER the a previous one, because you need the nextPageToken. Remember also that every request can get a maximum of 50 elements.

##### To get the statistics of a video:
```Java
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
## Sample app
I wrote a simple app that shows videos from Android Developer Youtube Channel.

<img src="https://raw.githubusercontent.com/prof18/YoutubeParser/master/Screen.png" width="30%" height="30%">



[github]: https://github.com/prof18/YoutubeParser
[app-download]: https://github.com/prof18/YoutubeParser/blob/master/YoutubeParser.apk
[app-code]: https://github.com/prof18/YoutubeParser/tree/master/app
