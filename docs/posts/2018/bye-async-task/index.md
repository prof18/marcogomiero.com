# RSS Parser 2.0: bye bye Async Task, welcome Coroutines


Finally, I found some time to sit down and work on my library RSS Parser. Before starting to describe all the cool stuff that I’ve introduced with this update, I want to thank you all for the support. In fact this year, the library exceeded 100 stars on Github, that seems a little goal but it means a lot to me.

I wrote this library back in 2016 and now in 2018, the code was “ugly” compared to all the coolest stuff provided by Kotlin.

![](https://cdn-images-1.medium.com/max/2000/1*T__9s7dfREGnF13oRlBhDg.jpeg)

So I decided to rewrite the library using **Kotlin** and **Coroutines**, so I can (finally) get rid of **Async Task**.

![](https://cdn-images-1.medium.com/max/2000/1*87C2QK8usMRMZ-hpdrqKKA.jpeg)

Of course, I maintained the compatibility of the library for the projects that still use Java.

Shortly, the library allows to parse an RSS feed and retrieve some information like title, content, author, etc. You can found more information about the features of the library in the [blog post](http://www.marcogomiero.com/posts/rss-parser-library/) that I’ve published some time ago or in the [README](https://github.com/prof18/RSS-Parser) available on Github.

But now let’s see some code. In this article, I’ll show only how to use the library because I’m planning to publish another blog post with all the technical details and decisions that I have made during the development of this new version.
 
The usage is very simple both if you are using Java or Kotlin. 
If you are using **Kotlin**, you need to create a *Parser* object and then call the suspend method *getArticles* passing the *URL* of the RSS feed as parameter. Since this is a *suspend* function, you need to “[*launch*](https://kotlin.github.io/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/launch.html)” the coroutine. Of course, you need also to handle the error case.

Here is an example:

```java
import com.prof.rssparser.Article
import com.prof.rssparser.Parser

//url of RSS feed
private val url = "[https://www.androidauthority.com/feed](https://www.androidauthority.com/feed)"

coroutineScope.launch(Dispatchers.Main) {
    try {
        val parser = Parser()
        val articleList = parser.getArticles(url)
        // The list contains all article's data. For example you can use it for your adapter.
    } catch (e: Exception) {
        // Handle the exception
    }
}
```

A complete example with Kotlin is available on [Github](https://github.com/prof18/RSS-Parser/tree/master/samplekotlin).

If you don’t know anything about the coroutines, I suggest you give a look to the [Codelab](https://codelabs.developers.google.com/codelabs/kotlin-coroutines/) provided by Google.

Instead, if you are still using **Java** in your Android project, the usage is pretty the same as the older version of the library. You need to create a *Parser* object, implements the callbacks that handle the result and the error and finally start the parsing by calling the *execute* method passing the *URL* as parameter.

Here is an example:

```java
import com.prof.rssparser.Article;
import com.prof.rssparser.OnTaskCompleted;
import com.prof.rssparser.Parser;

Parser parser = new Parser();
parser.onFinish(new OnTaskCompleted() {

    //what to do when the parsing is done
    @Override
    public void onTaskCompleted(List<Article> list) {
        // The list contains all article's data. For example you can use it for your adapter.
    }

    //what to do in case of error
    @Override
    public void onError(Exception e) {
        // Handle the exception
    }
});
parser.execute(urlString);
```

A complete example in Java is also available on [Github](https://github.com/prof18/RSS-Parser/tree/master/samplejava).

That’s all! For all the details or to report a bug, please visit the repo on [Github](https://github.com/prof18/RSS-Parser).

----

*Published also on [Medium](https://medium.com/@marcogomiero/rss-parser-2-0-bye-bye-async-task-welcome-coroutines-6002c9de5145)*
