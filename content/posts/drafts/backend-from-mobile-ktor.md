---
layout: post
title:  "Moving from mobile to backend development with Ktor"
date:   2021-12-30
show_in_homepage: false
draft: true
---

{{< admonition abstract "SERIES: Building a backend with Ktor" true >}}

- Part 1: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/)
- Part 2: [How to persist Ktor logs](https://www.marcogomiero.com/posts/2021/ktor-logging-on-disk/)
- Part 3: [How to use an in-memory database for testing on Ktor](https://www.marcogomiero.com/posts/2021/ktor-in-memory-db-testing/)
- Part 4: [How to handle database migrations with Liquibase on Ktor](https://www.marcogomiero.com/posts/2022/ktor-migration-liquibase/)
- Part 5: [Generate API documentation from Swagger on Ktor](https://www.marcogomiero.com/posts/2022/ktor-setup-documentation/)
- Part 6: [How to schedule jobs with Quartz on Ktor](https://www.marcogomiero.com/posts/2022/ktor-jobs-quartz/)
- Part 7: Moving from mobile to backend development with Ktor
{{< /admonition >}}

This article is the final instance of the series of posts dedicated to Ktor where I cover all the topics that made me struggle during development and that was not easy to achieve out of the box. In this article, I will cover why I ended up using Ktor and how was my journey from the mobile to the backend world. 

After some experience of maintaining an existing backend project developed with [Dropwizard](https://www.dropwizard.io/en/latest/), I had to start a new project from scratch. After some research I chose to go with Ktor, for many reasons. 

First of all, Ktor is build with Kotlin and coroutines, two things that I really like. 

Secondly, Ktor is lightweight and flexible, because you don’t have to import every feature, but only the things that you need. This is made possible with [plugins](https://ktor.io/docs/plugins.html#install), i.e. a specify feature (for example Compression, CORS, Cookies, etc) that you decide to install, only if you need it.  

And last but not least, Ktor is unopinionated. This allows to not stick to a specific pattern or architecture but to choose the one that better suits the project. And it also allows knowledge transfer, because it will be possible the reuse the existing knowledge acquired in another domain, mobile in my case.

For these reasons I found Ktor easy to use, with a gentle learning curve, even for a mobile developer. 

## Knowledge Transfer

As mentioned above, I didn’t find impossibile to adapted my mobile knowledge. 
An Android application is usually divided into 4 different layers: 

- Application 
- Presentation 
- Domain
- Data 

The **application layer** is responsible of starting the application, together with all the different libraries and functionalities that are needed. For example dependency injection, logging, analytics, etc. 

```kotlin
class MyApp : Application() {

    override fun onCreate() {
        super.onCreate()

        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        }
        initAnalytics()
        initCrashReporting()
        initRandomLib()
    }
}
```

The **presentation** layer is responsible of showing data to the user and interacting with it. In this layer, there are activities/fragments and ViewModels (or the equivalent in other pattern). 

The **domain** layer takes care of the specific domain of the application. It is usually composed of UseCases and Repositories where the data are manipulated and prepared before being passed to the presentation layer. 
This layer usually doesn’t contain any reference to the Android world.

```kotlin
class JokeRepositoryImpl( 
    private val jokeLocalDataSource: JokeLocalDataSource
) : JokeRepository {

    override suspend fun getRandomJoke(): JokeModel {
        // ...
    }
}
```

And finally, the **data** layer, that is the interface to the external world. This layer contains all the code required to retrieve data from the network or from a database, for example by using Retrofit or Room.

{{< figure src="/img/ktor-series/android-layers.png"  link="/img/ktor-series/android-layers.png" >}}

On Ktor the layers are really similar. 

The **application layer** is responsible of starting the server, together with all the different libraries and functionalities that are needed. Here it is possible to choose the [Ktor’s plugins](https://ktor.io/docs/plugins.html) that are required in the server. 

```kotlin
fun Application.module(testing: Boolean = false) {

    install(Koin) {
        slf4jLogger()
        modules(koinModules)
    }
		
    install(ContentNegotiation) {
        json()
    }

    install(CallLogging) {
        level = Level.INFO
    }

    install(Locations)

    routing {
      ...
    }
}
```

Since a server doesn’t have any UI, the presentation layer is a bit different than in mobile application. In this case, it is necessary to expose API endpoints to the outside world and not show buttons, checkboxes, etc. I’ve called this layer **Resource**, but is a complete personal choice (another possible name could be **Controller**) since Ktor is unopinionated.

```kotlin
// JokeResource.kt
fun Route.jokeEndpoint() {

    val jokeRepository by inject<JokeRepository>()

    get<JokeEndpoint.Random> {
        call.respond(jokeRepository.getRandomJoke())
    }

    post<JokeEndpoint.Watch> {  apiCallParams ->
        val name = apiCallParams.name
        jokeRepository.watch(name)
        call.respond("Ok")
    }
}
```


The **domain** layer will look the same like on Android. In here, there will be UseCases and Repositories where the data are manipulated and prepared before being passed to the resource layer. 

And finally, the concept of the **data** layer will be the same. The only thing that will change are the libraries required to interact with the database or the network. To interact with the database, I choose [Exposed](https://github.com/JetBrains/Exposed), an ORM developed by Jetbrains.








{{< figure src="/img/ktor-series/ktor-layers.png"  link="/img/ktor-series/ktor-layers.png" >}}


{{< figure src="/img/ktor-series/commons-layers.png"  link="/img/ktor-series/commons-layers.png" >}}
---

Maybe here we could have a use case layer, but let’s keep it simple for this example. 

- repository -> here we manage data. Same stuff in both the situation 
- local/remote data source -> source of the data, could be from a database or from the network. We use Room, sqldelight or retrofit, depending on what we want to do.

Ktor:
- application -> still have an application but it is not a class, it is a function. A place where you can instantiate stuff. The module function called when the backend is started. Here the plugin are initialized. Only the plugin that we want. Link to the the plugin on the doc.
- resource* -> not activity, we are not showing UI. We are sexposing endpoint. We have a point where we expose endpoint. THis place has not a name because there is not an opzionino about that but we cal call it reosource or controller. 

Again there could be 

- repository -> repository where we manipulate the data in our domain
- local/remote data source -> data source


In general we can have this kind of structure, that is pretty similar. 

- Application -> where we initialize stuff
- presentation -> where you expose what we need to expsose
- domain -> manipulate the data of the business
- data -> where the data are retrieved. We can retrieve data from the database for example with Exposed. It is an ORM developed by Jetbrains. It is a type-safe SQL wrapper. A dsl take we can use to call SQL.

DI injection, use Koin. The concept are the same: declare module, start it in the application and retrieve the dependency with the delegate. 

 

Both has a place to setup stuff, like Android Application and the module class on Ktor.

In android we usually have an application class that we can implement. In the onCreate we setup different things like logging, analytics crash reporting, etc. Every library that we need in our application

On Ktor, there is an extension function not the Application class. This is like the onCreate and the function is the entry point for the backend. We can also have different module functions if we want to spin up different modules, but this is another topic.

Here we have setup everything like on android, so DI, logging, database connection etc.

In particular here we have to define and install the plugins that we want to use int the backend. And we install a plugin with the install function.

Add a specific feature. This setup enables a flexible and lightweight project. No plugin activated by default

On the presentation layer on android you expose views on activity or fragments, on ktor expose api.

```kotlin
@Location("joke")
class JokeEndpoint {

    @Location("/random")
    class Random(val parent: JokeEndpoint)

    @Location("/watch/{name}")
    class Watch(val name: String, val parent: JokeEndpoint)
}
```

The domain layer is basically the same in every platform. You get data from the database and or from the network using coroutines

Again the data layer is very similar. You get the some data from the database or the network. In that case what changes is the ORM

Room or SQLDelight on Android, Exposed can be a choice on Ktor. Exposed, an ORM framework for Kotlin. Exposed offers two levels of database access: typesafe SQL wrapping DSL and lightweight data access objects.

Dependency injection is the same with Koin. https://insert-koin.io/docs/quickstart/ktor


testing

Unit Test    -> Just regular Kotlin Unit tests
androidTest  -> TestEngine

```
@Test
fun testRequests() = withTestApplication(module(testing = true)) {
    with(handleRequest(HttpMethod.Get, "/")) {
        assertEquals(HttpStatusCode.OK, response.status())
        assertEquals("Hello from Ktor Testable sample application", response.content)
    }
```

Ktor is flexible and unopinionated -> Knowledge Transfer
Mobile knowledge can be adapted
Effective scaling and deploying can be hard
“Going to the other side” enrich your dev vision

## Conclusions


https://www.marcogomiero.com/talks/2022/from-mobile-to-backend-ktor-fosdem/


And that’s it for today. 



Unopiniotated is the key for knowledge transferring. 
Mobile knowledge can be adapted, changed a bit and moved to the backend. OF course this is not enough to build a scalable add bullet proof backend. For example for me the part of effective scaling and deploying was hard and I had to ask for help, but beside that it was a really nice exp. 
Going to the other side on trying new things can enrich your dev vision.

You can find the code mentioned in the article on [GitHub](https://github.com/prof18/ktor-chuck-norris-sample/tree/part5).



You can check out the other instances of the series in the index above or [follow me on Twitter](https://twitter.com/marcoGomier) to keep up to date.



In the next episode, I’ll cover how to set up background jobs. You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episodes.