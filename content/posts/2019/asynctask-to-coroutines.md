---
layout: post
title:  "A journey from Async Task to Kotlin Coroutines"
images:
  - https://miro.medium.com/max/1400/0*BnjRJYi8CNeaKOq1
date:   2019-01-14
show_in_homepage: true
tags: [Android]
---

{{< figure src="/img/path.jpeg" alt="image" caption="*Photo by [felipe lopez](https://unsplash.com/@flopez_nice) on [Unsplash](https://unsplash.com)*" >}}

Some weeks ago I released a new version of the RSS Parser Library and I talked about the update in a blog post.

> [RSS Parser 2.0: bye bye Async Task, welcome Coroutines](https://marco.gomiero.com/posts/bye-async-task)
This update brought a huge change in the infrastructure of the library. SPOILER: Kotlin and coroutines. Today, in this post I want to talk about the transition process and all the decisions that I have made to develop this new version. In this way, I hope to inspire you to leave the Async Task and get into the coroutines world.

But, before starting with the technical details, I want to share you some resources to get into the coroutine world. If you already know the coroutines you can skip to the second part of the article.

## Get into the coroutine world, it’s funny. I promise:

The first thing that you can do to get into the coroutine world is doing the codelab provided by Google.

> [Using Kotlin Coroutines in your Android App](https://codelabs.developers.google.com/codelabs/kotlin-coroutines/)

Don’t worry if you don’t understand all the concepts, the codelab is useful to make the first exploration and to receive the inputs and the tools to study a particular argument.

After the codelab, I suggest you give a look to the official documentation that is well written and full of examples.

> [Kotlin/kotlinx.coroutines](https://github.com/Kotlin/kotlinx.coroutines)

Then you could read some articles Android specific and not. Here are some articles that I’ve read:

> [An introduction to Kotlin Coroutines*](https://antonis.me/2018/12/12/an-introduction-to-kotlin-coroutines/)

> [How to make sense of Kotlin coroutines](https://proandroiddev.com/how-to-make-sense-of-kotlin-coroutines-b666c7151b93)

> [Kotlin Coroutines patterns & anti-patterns](https://proandroiddev.com/kotlin-coroutines-patterns-anti-patterns-f9d12984c68e)

> [Playing with Kotlin in Android: coroutines and how to get rid of the callback hell](https://medium.com/@andrea.bresolin/playing-with-kotlin-in-android-coroutines-and-how-to-get-rid-of-the-callback-hell-a96e817c108b)

> [Android Networking with Coroutines and Retrofit](https://medium.com/exploring-android/android-networking-with-coroutines-and-retrofit-a2f20dd40a83)

> [Handle Complex Network Call with Kotlin Coroutine + Retrofit 2](https://blog.oozou.com/handle-complex-network-call-with-kotlin-coroutine-retrofit-2-30a6cd1e0189)

> [Async code using Kotlin Coroutines](https://proandroiddev.com/async-code-using-kotlin-coroutines-233d201099ff)

I suggest also the talks of Chris Banes and Christina Lee:

> [So you’ve read the Coroutines guide and you’re ready to start using them in your Android app to coroutines? Great!](https://chris.banes.me/talks/2018/android-suspenders/)

> [Coroutines By Example](https://skillsmatter.com/skillscasts/12727-coroutines-by-example)

Of course, there are lots of resources available and lots of ways to learn the coroutines. These are some advice based on my experience and learning path.

## The Path From Async Task to Coroutines

The first release of the library is dated 18 June 2016, a period when there wasn’t all the beautiful stuff that there is today (for instance, Kotlin) and moreover I did not know all the stuff that I know today. The code was so simple (and now I can also say that was ugly) but it was working.

### Old School Java Code

I used an Async Task to handle the network request; the result of the request is sent to an XML Parser that notifies its result when the parsing was done. Here’s the code of the Parser:

```java
public class Parser extends AsyncTask<String, Void, String> implements Observer {

    private XMLParser xmlParser;
    private static ArrayList<Article> articles = new ArrayList<>();
    private OnTaskCompleted onComplete;

    public Parser() {
        xmlParser = new XMLParser();
        xmlParser.addObserver(this);
    }

    public interface OnTaskCompleted {
        void onTaskCompleted(ArrayList<Article> list);
        void onError();
    }

    public void onFinish(OnTaskCompleted onComplete) {
        this.onComplete = onComplete;
    }

    @Override
    protected String doInBackground(String... ulr) {

        Response response = null;
        OkHttpClient client = new OkHttpClient();
        Request request = new Request.Builder()
                .url(ulr[0])
                .build();

        try {
            response = client.newCall(request).execute();
            if (response.isSuccessful())
                return response.body().string();
        } catch (IOException e) {
            e.printStackTrace();
            onComplete.onError();
        }
        return null;
    }

    @Override
    protected void onPostExecute(String result) {
        if (result != null) {
            try {
                xmlParser.parseXML(result);
                Log.i("RSS Parser ", "RSS parsed correctly!");
            } catch (Exception e) {
                e.printStackTrace();
                onComplete.onError();
            }
        } else
            onComplete.onError();
    }

    @Override
    @SuppressWarnings("unchecked")
    public void update(Observable observable, Object data) {
        articles = (ArrayList<Article>) data;
        onComplete.onTaskCompleted(articles);
    }
}
```

Then, the result of the parsing (or an error of parsing) is notified to the “main executor” (the application that uses the library) with two simple callbacks.

```java
Parser parser = new Parser();
parser.execute(urlString);
parser.onFinish(new Parser.OnTaskCompleted() {
    //what to do when the parsing is done
    @Override
    public void onTaskCompleted(ArrayList<Article> list) {
        //list is an Array List with all article's information
        //set the adapter to recycler view
        mAdapter = new ArticleAdapter(list, R.layout.row, MainActivity.this);
        mRecyclerView.setAdapter(mAdapter);
        progressBar.setVisibility(View.GONE);
        mSwipeRefreshLayout.setRefreshing(false);
    }

    //what to do in case of error
    @Override
    public void onError() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                progressBar.setVisibility(View.GONE);
                mSwipeRefreshLayout.setRefreshing(false);
                Toast.makeText(MainActivity.this, "Unable to load data.",
                        Toast.LENGTH_LONG).show();
                Log.i("Unable to load ", "articles");
            }
        });
    }
});
```

### Kotlin and Coroutines, a love story

After 2 years, I wanted to get rid of Async Task, Java and all the ugly stuff. The perfect candidates for taking the place are Kotlin and the coroutines. However, my biggest concern was maintaining the compatibility with all the devs that still use Java (seriously guys? Love yourself, move to Kotlin). In fact, the Kotlin coroutines cannot be invoked from Java code.

At first, I tried to figure out if there was a method to call the coroutines from Java but finally I came up with a brilliant idea: provide the support for both the ways.

For the Java support, I decided to use [Future](https://docs.oracle.com/javase/7/docs/api/java/util/concurrent/Future.html) and [Callable](https://docs.oracle.com/javase/7/docs/api/java/util/concurrent/Callable.html) to handle the asynchronous operations. In particular, I implemented two classes that perform respectively the fetching and the parsing task.

```kotlin
class XMLFetcher(private val url: String) : Callable<String> {
  @Throws(Exception::class)
  override fun call(): String {
      return CoreXMLFetcher.fetchXML(url)
  }
}
```
```kotlin
class XMLParser(var xml: String) : Callable<MutableList<Article>> {
  @Throws(Exception::class)
  override fun call(): MutableList<Article> {
      return CoreXMLParser.parseXML(xml)
  }
}
```

The result of the parsing is then notified to the “main executor” using the same callbacks reported above.

```kotlin
fun execute(url: String) {
  Executors.newSingleThreadExecutor().submit{
      val service = Executors.newFixedThreadPool(2)
      val f1 = service.submit<String>(XMLFetcher(url))
      try {
          val rssFeed = f1.get()
          val f2 = service.submit(XMLParser(rssFeed))
          onComplete.onTaskCompleted(f2.get())
      } catch (e: Exception) {
          onComplete.onError(e)
      } finally {
          service.shutdown()
      }
  }
}
```

In this way, the old users of the library can still call the same code without noticing any kind of difference but the new ones (and of course also the old) can learn and use the new way.

As you can image, the new part is written using the Kotlin coroutines. As above, I separated the fetching and the parsing task. The fetching task is performed by the *fetchXML* suspending function, that takes the URL of the RSS feed as input and returns a [Deferred](https://kotlin.github.io/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-deferred/) object that will be the input of the *parseXML* suspend function. This function will then parse the RSS Feed and returns a list of parsed data.

```kotlin
object CoroutineEngine {
  @Throws(Exception::class)
  suspend fun fetchXML(url: String) =
          withContext(Dispatchers.IO) {
              return@withContext CoreXMLFetcher.fetchXML(url)
          }

  @Throws(Exception::class)
  suspend fun parseXML(xml: Deferred<String>) =
          withContext(Dispatchers.IO) {
              return@withContext CoreXMLParser.parseXML(xml.await())
          }
}
```

These functions are exposed to the “main executor” by using another suspend function, that it will get and parse asynchronously the RSS feed.

```kotlin
@Throws(Exception::class)
suspend fun getArticles(url: String) =
      withContext(Dispatchers.IO) {
          val xml = async { CoroutineEngine.fetchXML(url) }
          return@withContext CoroutineEngine.parseXML(xml)
      }
```

All the suspend functions reported above are called with the IO Dispatcher that uses a shared pool of on-demand created threads. There are also other dispatchers, give a look to the [documentation](https://kotlin.github.io/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-coroutine-dispatcher/) to find the one that better suits your needs.

And finally, from the ViewModel (or in whatever place depending on the architecture of your app) you can launch the coroutine with a [Scope](https://kotlin.github.io/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-coroutine-scope/), so, for example, you can stop it if the activity is destroyed, and then “transform” an URL to a List of Articles.

```kotlin
coroutineScope.launch(Dispatchers.Main) {
  try {
      val parser = Parser()
      val articleList = parser.getArticles(url)
      setArticleList(articleList)
  } catch (e: Exception) {
      e.printStackTrace()
      _snackbar.value = "An error has occurred. Please retry"
      setArticleList(mutableListOf())
  }
}
```

And finally, we have reached the end of my journey from Async Task to Coroutines. Of course, you can use this example as an idea to leave forever the (ugly) Async Tasks.

If you want to contribute to the development of the library or simply report a bug, visit the repo on Github: [https://github.com/prof18/RSS-Parser](https://github.com/prof18/RSS-Parser)

A special thanks to the (awesome) devs of the Android Developers Italia Community that gave to me some advice. If you are Italian, join us on [Slack](https://androiddevs.it/)!
