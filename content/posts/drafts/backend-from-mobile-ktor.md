---
layout: post
title:  "CHANGEME: Backend from mobile Ktor"
date:   2021-12-30
show_in_homepage: false
draft: true
---

Ktor is unopinionated like android. Whatever architecture. Whatever pattern. This enables knowledge transfer

Classic android app:
- application
- activity/fragment
- view model
- repository
- local/remote data source

Ktor:
- application
- resource*
- repository
- local/remote data source

In general:
- Application
- presentation
- domain
- data

Both has a place to setup stuff, like Android Application and the module class on Ktor.

In android we usually have an application class that we can implement. In the onCreate we setup different things like logging, analytics crash reporting, etc. Every library that we need in our application

On Ktor, there is an extension function not the Application class. This is like the onCreate and the function is the entry point for the backend. We can also have different module functions if we want to spin up different modules, but this is another topic.

Here we have setup everything like on android, so DI, logging, database connection etc.

In particular here we have to define and install the plugins that we want to use int the backend. And we install a plugin with the install function.

Add a specific feature. This setup enables a flexible and lightweight project. No plugin activated by default

On the presentation layer on android you expose views on activity or fragments, on ktor expose api.

```kotlin
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