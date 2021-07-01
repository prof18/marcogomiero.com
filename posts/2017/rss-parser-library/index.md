# How to easily handle RSS Feeds on Android with RSS Parser


[Two month ago I have talked about YoutubeParser](http://www.marcogomiero.com/posts/update-yt-parser-2/), an Android Library that I developed. Today I want to talk about  **RSS-Parser**, another library that I wrote.


This library allows you to easily download an (or multiple) RSS Feed in order to display it in your application. For every article it is possible to download the following information:

* Title
* Author
* Description
* Content
* Main Image
* Link
* Publication Date

[Here](https://www.androidauthority.com/feed/) you can find an example of feed.

The source code of the library is on Github together with a sample application that shows what you can do with the library.

*  [Click here to view the library on Github](https://github.com/prof18/RSS-Parser) 
*  [Click here to show the code of the sample app](https://github.com/prof18/RSS-Parser/tree/master/app) 
*  [Click here to download the app](https://github.com/prof18/RSS-Parser/blob/master/RSS%20Parser.apk) 

<img src="https://raw.githubusercontent.com/prof18/RSS-Parser/master/Screen.png" width="50%" height="50%" align="center">

Of course the library is available also on jCenter so you can easily add the dependency on Gradle.

```gradle
dependencies {
  compile 'com.prof.rssparser:rssparser:1.1'
}
```

Now, let's give a look on how it works. First on all you need to create a new Parser object and next you can execute the Parser by calling the method *execute()*, that requires as parameter the URL of the RSS feed.


If the data are correctly retrieved you can handle them inside the *OnTaskCompleted* method. Here you have an *ArrayList* of *Article* and you can use it for example to populate a Recycler View. Instead if some bad things happened, you can take actions inside the *onError* method.


```java
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
```

That’s all! Please let me know if you notice any bug or if you have any advice that can improve this library.

