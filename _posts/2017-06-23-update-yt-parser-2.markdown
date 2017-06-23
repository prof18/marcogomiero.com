---
layout: post
title:  "New big update for YoutubeParser: video stats and much more"
date:   2017-06-23
---
<p class="intro"><span class="dropcap" align="justify">F</span></p>inally I've released a new big update for YoutubeParser. For people who don't know what I'm talking about, don't worry now I'm going to explain all.</p>

<b>YoutubeParser</b> is the first <b>Android library</b> that I ever wrote. With this library it is possible to get information of videos from Youtube channels. These information are:
<ul>
<li> Title; </li>
<li> Link;  </li>
<li> Thumbnail, with three different image size. </li>
</ul>

After a year I've released this new big update, named 2.0, that introduces a bunch of new things. First of all, now it is possible to load more than 50 videos from the same channel. 50 is the maximum number of videos that can be retrieved with a single request.

Furthermore you can also get the statistics of a video:
<ul>
<li> View; </li>
<li> Like; </li>
<li> Dislike; </li>
<li> Favorite Count; </li>
<li> Comment Count. </li>
</ul>

The source code of the library is on Github together with a sample application that shows what you can do with the library.
<ul>
<li> <a href = "https://github.com/prof18/YoutubeParser">Click here to view the library on Github</a> </li>
<li> <a href = "https://github.com/prof18/YoutubeParser/tree/master/app">Click here to show the code of the sample app</a> </li>
<li> <a href = "https://github.com/prof18/YoutubeParser/blob/master/YoutubeParser.apk">Click here to download the app.</a> </li>
</ul>

<img src="https://raw.githubusercontent.com/prof18/YoutubeParser/master/Screen.png" width="50%" height="50%" align="middle">

Of course the library is available also on jCenter so you can easily add the dependency on Gradle.

{% highlight ruby %}
dependencies {
  compile 'com.prof.youtubeparser:youtubeparser:2.0'
}
{% endhighlight %}

Now let's look how it works. First of all you need to create a new <i>Parser</i> Object and then you have to create the url to load the data by using the method <i>generateRequest</i>. This method takes as parameter four values:
<ul>
<li>The Channel ID of a Youtube Channel. For example, for this link <i>youtube.com/channel/UCVHFbqXqoYvEWM1Ddxl0QDg</i>, the Channel ID is: <i>UCVHFbqXqoYvEWM1Ddxl0QDg</i></li>
<li>The maximum number of videos to show. This value can be maximum 50.</li>
<li>The type of ordering of the videos. It is possible to choose between two different type of ordering: by date or by views. To select the chosen value you have to use the constants: <i>Parser.ORDER_DATE</i> and <i>Parser.ORDER_VIEW_COUNT</i></li>
<li>The API Key. The key is a <i>BROSWER API KEY</i> and to create it you can follow <a href="https://support.google.com/cloud/answer/6158862?hl=en#creating-browser-api-keys">this guide</a></li>
</ul>

If the data are correctly retrieved, you can do your stuff inside the <i>onTaskCompleted</i>. Here you have two variable: an <i>ArrayList</i> of <i>Video</i> items that you can use to populate your view for instance and a <i>token</i> that is necessary to load more data (see below for more details).

If there are some error on the process, you can handle the situation in the <i>onError()</i> method.

{% highlight java %}
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
{% endhighlight %}

If you want to retrieved <b>more videos from the same channel</b>, the procedure is the same of the above case. The only difference is the method that generate the url; here you have to add the token retrieved from the above procedure.

{% highlight java %}
String url = parser.generateMoreDataRequest(CHANNEL_ID, 20, Parser.ORDER_DATE, API_KEY, nextToken);
{% endhighlight %}

To get <b>the statistics of a single video</b>, the procedure is equivalent of the previous. As you can guess, the first thing to do is to generate the url with the <i>generateStatsRequest</i> method. The parameter of this method are:
<ul>
<li> The ID of a Youtube Video; </li>
<li> The API Key. </li>
</ul>

Also here you can handle the result in the <i>onTaskCompleted</i> method and any error in the <i>onError()</i> method.

{% highlight java %}
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
{% endhighlight %}

That's all! Please let me know if you notice any bug or if you have any advice that can improve this library.
