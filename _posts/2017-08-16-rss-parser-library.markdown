---
layout: post
title:  "How to easily handle RSS Feeds on Android with RSS Parser"
description: "RSS Parser is an Android Library that helps you to handle RSS Feed in your application. Let's see how it works!"
date:   2017-08-16
---
<p class="intro"><span class="dropcap" align="justify">T</span></p><p align="justify">wo month ago <a href="http://www.marcogomiero.com/blog/update-yt-parser-2/">I have talked about YoutubeParser</a>, an Android Library that I developed. Today I want to talk about  <b>RSS-Parser</b>, another library that I wrote.</p>


<p align="justify">This library allows you to easily download an (or multiple) RSS Feed in order to display it in your application. For every article it is possible to download the following information:
<ul>
<li>Title</li>
<li>Author</li>
<li>Description</li>
<li>Content</li>
<li>Main Image</li>
<li>Link</li>
<li>Publication Date</li>
</ul>
</p>
<p align="justify"><a href="https://www.androidauthority.com/feed/">Here</a> you can find an example of feed.
</p>

<p align="justify">The source code of the library is on Github together with a sample application that shows what you can do with the library.

<ul>
<li> <a href = "https://github.com/prof18/RSS-Parser">Click here to view the library on Github</a> </li>
<li> <a href = "https://github.com/prof18/RSS-Parser/tree/master/app">Click here to show the code of the sample app</a> </li>
<li> <a href = "https://github.com/prof18/RSS-Parser/blob/master/RSS%20Parser.apk">Click here to download the app.</a> </li>
</ul>
</p>


<img src="https://raw.githubusercontent.com/prof18/RSS-Parser/master/Screen.png" width="50%" height="50%" align="center">


<p align="justify">Of course the library is available also on jCenter so you can easily add the dependency on Gradle.</p>

{% highlight gradle %}
dependencies {
  compile 'com.prof.rssparser:rssparser:1.1'
}
{% endhighlight %}

<p align="justify">Now, let's give a look on how it works. First on all you need to create a new Parser object and next you can execute the Parser by calling the method <i>execute()</i>, that requires as parameter the URL of the RSS feed.</p>


<p align="justify">If the data are correctly retrieved you can handle them inside the <i>OnTaskCompleted</i> method. Here you have an <i>ArrayList</i> of <i>Article</i> and you can use it for example to populate a Recycler View. Instead if some bad things happened, you can take actions inside the <i>onError</i> method.</p>


{% highlight java %}

import com.prof.rssparser.Article;
import com.prof.rssparser.Parser;

//url of RSS feed
String urlString = "http://www.androidcentral.com/feed";
Parser parser = new Parser();
parser.execute(urlString);
parser.onFinish(new Parser.OnTaskCompleted() {

    @Override
    public void onTaskCompleted(ArrayList<Article> list) {
      //what to do when the parsing is done
      //the Array List contains all article's data.
    }

    @Override
    public void onError() {
      //what to do in case of error
    }
});

{% endhighlight %}

<p align="justify">That’s all! Please let me know if you notice any bug or if you have any advice that can improve this library.</p>
