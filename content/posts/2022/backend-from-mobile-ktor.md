---
layout: post
title:  "Moving from mobile to backend development with Ktor"
date:   2022-06-06
show_in_homepage: false
image: "/img/ktor-series/commons-layers.png"
---

> **SERIES: Building a backend with Ktor**
>
> - Part 1: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/)
> - Part 2: [How to persist Ktor logs](https://www.marcogomiero.com/posts/2021/ktor-logging-on-disk/)
> - Part 3: [How to use an in-memory database for testing on Ktor](https://www.marcogomiero.com/posts/2021/ktor-in-memory-db-testing/)
> - Part 4: [How to handle database migrations with Liquibase on Ktor](https://www.marcogomiero.com/posts/2022/ktor-migration-liquibase/)
> - Part 5: [Generate API documentation from Swagger on Ktor](https://www.marcogomiero.com/posts/2022/ktor-setup-documentation/)
> - Part 6: [How to schedule jobs with Quartz on Ktor](https://www.marcogomiero.com/posts/2022/ktor-jobs-quartz/)
> - Part 7: Moving from mobile to backend development with Ktor

This article is the final instance of the series of posts dedicated to Ktor where I cover all the topics that made me struggle during development and that were not easy to achieve out of the box. In this article, I will cover why I ended up using Ktor and how was my journey from the mobile to the backend world.

After some experience maintaining an existing backend project developed with [Dropwizard](https://www.dropwizard.io/en/latest/), I had to start a new project from scratch. After some research, I chose to go with Ktor, for many reasons.

First of all, Ktor is built with Kotlin and coroutines, two things that I like.

Secondly, Ktor is lightweight and flexible, because you don’t have to import every feature, but only the things that you need. This is made possible with [plugins](https://ktor.io/docs/plugins.html#install), i.e. a specific feature (for example Compression, CORS, Cookies, etc) that you decide to install, only if you need it.

And last but not least, Ktor is unopinionated. This allows not to stick to a specific pattern or architecture but to choose the one that better suits the project. And it also allows knowledge transfer, because it will be possible to reuse the existing knowledge acquired in another domain, mobile in my case.

For these reasons, I found Ktor easy to use, with a gentle learning curve, even for a mobile developer.

## Knowledge Transfer

The main topics that I needed to adapt are 3: architecture, dependency injection and testing.

### Architecture

An Android application is usually divided into 4 different layers:

- Application
- Presentation
- Domain
- Data

The **application layer** is responsible for starting the application, together with all the different libraries and functionalities that are needed. For example dependency injection, logging, analytics, etc.

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

The **presentation** layer is responsible for showing data to the user and interacting with it. In this layer, there are activities/fragments and ViewModels (or the equivalent in other patterns).

The **domain** layer takes care of the specific domain of the application. It is usually composed of *UseCases* and *Repositories* where the data are manipulated and prepared before being passed to the presentation layer.
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

And finally, the **data** layer, which is the interface to the external world. This layer contains all the code required to retrieve data from the network or a database, for example by using Retrofit or Room.

On Ktor the layers are similar.

The **application layer** is responsible for starting the server, together with all the different libraries and functionalities that are needed. Here it is possible to choose [Ktor’s plugins](https://ktor.io/docs/plugins.html) that are required in the server.

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

Since a server doesn’t have any UI, the presentation layer is a bit different than in a mobile application. In this case, it is necessary to expose API endpoints to the outside world and not show buttons, checkboxes, etc. I’ve called this layer **Resource**, but is a completely personal choice (another possible name could be **Controller**) since Ktor is unopinionated.

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

The **domain** layer will look the same as on Android. Here, there will be *UseCases* and *Repositories* where the data are manipulated and prepared before being passed to the presentation layer.

And finally, the concept of **data** layer will be the same. The only thing that will change is the libraries required to interact with the database or the network. To interact with the database, I chosed [Exposed](https://github.com/JetBrains/Exposed), an ORM developed by Jetbrains.

With all the required platform adaptations, the architecture layers are very similar in both the worlds.

{{< figure src="/img/ktor-series/commons-layers.png"  link="/img/ktor-series/commons-layers.png" >}}

For this reasons, all the patterns and knowledge used to architect an Android application can be easily adapted and reused to build a backend.

### Dependency Injection

A topic that doesn’t require any additional knowledge is dependency injection.

On Ktor, [Koin](https://insert-koin.io/docs/quickstart/ktor) can be used. And it behaves exactly like on Android: it is necessary to create a module, initialize Koin and then it will possible to retrieve the dependency.

**Android**:

```kotlin
val appModule = module {
   single<HelloRepository> { HelloRepositoryImpl() }
   factory { MySimplePresenter(get()) }
}
```

```kotlin
class MyApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        startKoin {
            androidLogger()
            androidContext(this@MyApplication)
            modules(appModule)
        }
    }
}
```

```kotlin
class MainActivity : AppCompatActivity() {

   val firstPresenter: MySimplePresenter by inject()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        ...
    }
}
```

**Ktor**:

```kotlin
val appModule = module {
    single<JokeLocalDataSource> { JokeLocalDataSourceImpl() }
    single<JokeRepository> { JokeRepositoryImpl(get()) }
}
```

```kotlin
fun Application.module() {

    install(Koin) {
        slf4jLogger()
        modules(koinModules)
    }
    ...
}
```

```kotlin
fun Route.jokeEndpoint() {

    val jokeRepository by inject<JokeRepository>()

    get<JokeEndpoint.Random> {
        call.respond(jokeRepository.getRandomJoke())
    }

    ...
}
```

For more details about DI setup, you can look at the first instance of the series - [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/).

### Testing

Also, testing doesn’t require a completely new set of knowledge. Unit testing will be exactly the same as on Android because it’s platform agnostic.

Integration testing instead will be friendlier and easier because no emulator is required.
In particular, Ktor does not create a web server but it hooks directly into the internal mechanism with a TestEngine. In this way, the execution of tests will be quicker rather than spinning up a complete web server for testing.

```kotlin
@Test
fun testRequests() = withTestApplication(module(testing = true)) {
    with(handleRequest(HttpMethod.Get, "/")) {
        assertEquals(HttpStatusCode.OK, response.status())
        assertEquals("Hello from Ktor Testable sample application", response.content)
    }
}
```

For more details about testing on Ktor, you can look at the first instance of the series - [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/).

## Conclusions

Being unopinionated is the key to knowledge transfer. For this reason, mobile knowledge can be adapted and changed to be ready to develop backend applications with Ktor. However, there will be still some areas that requires more attention and a more deep dive, like scaling and deploying. That was one of the areas where I was lacking knowledge and where I asked for help.
But even without the full and complete knowledge, going to the ”other side” and trying new things was really a nice experience that can enrich your vision.

And that’s it for this series. You can check out the other instances of the series in the index above or [follow me on Twitter](https://twitter.com/marcoGomier) for new content.

## Bonus:

I’ve spoke about this topic in a talk [in the Kotlin Dev Room at Fosdem 2022](https://www.marcogomiero.com/talks/2022/from-mobile-to-backend-ktor-fosdem/).

Here’s the recording of the session:

{{< rawhtml >}}
<br>
<video controls width="100%">
	<source src="https://ftp.fau.de/fosdem/2022/D.kotlin/from_mobile_to_backend.webm" type="video/webm">
</video>
{{< /rawhtml >}}


