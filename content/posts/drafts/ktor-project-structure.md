---
layout: post
title:  "CHANGE ME? - Structuring a Ktor project"
date:   2021-03-09
show_in_homepage: true
draft: true
tags: [Ktor]
---

SERIES: Building a backend with Ktor

Part 1: project structure
Part 2: logging on disk
Part 3: database setup with in memory for testing
Part 4: database migration with liquibase
Part 5: setup documentation with swagger.
Part 6: conclusion, perspective from mobile dev, etc.

___

It’s been a few months since I’ve started working with [Ktor](https://ktor.io/) to build the backend of [Revelop](https://revelop.app/)

Today I want to start a series of articles dedicated to Ktor. With these articles I want to cover all the topics that made me struggle during the development and that was not easy to achieve out of box. For example, using a in-memory database for testing, handling database migration, setting up logging on disk, using dependency injection, etc. 

In this article I will show how I’ve structured the Ktor project I work in. I’ll cover dependency injection, configurations and testing.

But before moving on, a quick introduction about Ktor is mandatory.

> Ktor is an asynchronous framework for creating microservices, web applications, and more. It’s fun, free, and open source.
> From [ktor.io](https://ktor.io/)

Ktor is a lightweight framework that let easily build backends, web applications, mobile and browser applications. It can be used to create both server and client side applications (it is compatible with Kotlin Mutliplatform as well). Ktor is highly configurable with extensions and it is possible to configure a custom pipeline through a Kotlin DSL. And finally, Ktor is truly asynchronous and uses Kotlin Coroutines to make the development easier without the callback hell.

This is “an elevator pitch” of Ktor, to know all the details I’ll suggest to give a look [to the documentation](https://ktor.io/docs/welcome.html).

## Create a new Ktor Project

The starting point for a Ktor project is defenetly the wizard included in IntelliJ. The wizard let you choose between all the different features that Ktor provides and it will generate a bare-bone project ready to be used.

{{< figure src="/img/ktor-series/ktor-wizard-Intellij .png"  link="/img/ktor-series/ktor-wizard-Intellij .png" >}}

And if you don’t like IntelliJ the wizard is also available on [start.ktor.io](https://start.ktor.io/).

{{< figure src="/img/ktor-series/ktor-web-wizard.png"  link="/img/ktor-series/ktor-web-wizard.png" >}}

The project that I built as references for this series contains a few set of features:

- Call Logging
- Content Negotiation
- kotlinx.serialization
- Locations
- Routing

The project is a simple backend that returns random Chuck Norris jokes. The jokes are saved in a database and they came from the [Chuck Norris IO project](https://github.com/chucknorris-io/chuck-db). 

## Project Structure 

The wizard creates a default `Application.kt` file that contains the `[module](https://ktor.io/docs/modules.html)` function that initialize the server pipeline, install the selected features, register the routes, etc. In this function, all the configurations and the classes needed to run the server must be provided or initialized. 

### Dependency Injection with Koin

Before moving on, it is a good idea to setup dependency injection. I’ll use [**Koin**](https://insert-koin.io) that has a build-in support for Ktor.

```kotlin
// Koin for Ktor 
implementation "io.insert-koin:koin-ktor:$koin_version"
// SLF4J Logger
implementation "io.insert-koin:koin-logger-slf4j:$koin_version"
```

To use Koin, it is necessary to install the appropriate feature inside the `module` function. I recommended to do it as first thing in the setup pipeline.

```kotlin
install(Koin) {
    slf4jLogger()
    modules(appModule)
}
```

The Koin module is defined in a separate file, just to keep the `Application` class and the `module` function as clean as possible.

```kotlin
val appModule = module {
    single<MyClass>()
    singleBy<MyInterface, MyInterfaceImpl>()
}
```

After that, the dependency graph is built and inside the `Application`, `Routing` and `Route` scope, it is possibile to retrive the dependencies like in a `KoinComponent`

```kotlin
val myClass by inject<MyClass>()
```

For more information about Koin on Ktor, refer to the [documentation](https://insert-koin.io/docs/reference/koin-ktor/ktor/)

### Configuration

On Ktor it is possible to [set some configurations](https://ktor.io/docs/configurations.html), like host address and port, in code (if using the [`embeddedServer`](https://ktor.io/docs/create-server.html#embedded-server)) or in an external file with the HOCON format (if using the [`EngineMain`](https://ktor.io/docs/create-server.html#engine-main)). 

The wizard automatically creates an `application.conf` file in the application `resources` directory.


```bash
.
└── src
    ├── main
    │   ├── kotlin
    │   │   └── com
    │   │       └── ...
    │   └── resources
    │       ├── application.conf
    └── test
        ├── kotlin
        │   └── com
        │       └── ...
        └── resources
            ├──  ...
    
```

```hocon
ktor {
  deployment {
    port = 8080
    port = ${?PORT}
  }
  application {
    modules = [com.prof18.ktor.chucknorris.sample.ApplicationKt.module]
  }
}
```

This configuration file will be automatically loaded and parsed by Ktor when the server is started. It is possible to provide a custom configuration file instead of the one from resources with a command line argument:

```
java -jar ktor-backend.jar -config=/config-folder/application.conf
```

This is helpful for example to provide different configurations for database or for external service (on part 3 I’ll show an use case of this feature). 

But, beside the [default value provided by the framework](https://ktor.io/docs/configurations.html#hocon-file), it is possible to create custom configurations to use later in the code. 
For example, I’ve created a new section with a Boolean field that will indicate if the instance is run on staging or production server.

```hocon
...
server {
    isProd = false
}
```

Every section will be mapped in the code with a `data class`.

```kotlin
data class ServerConfig(
    val isProd: Boolean
)
```


```kotlin

class AppConfig {
    lateinit var serverConfig: ServerConfig
    // Place here other configurations
}

fun Application.setupConfig() {
    val appConfig by inject<AppConfig>()

    // Server
    val serverObject = environment.config.config("ktor.server")
    val isProd = serverObject.property("isProd").getString().toBoolean()
    appConfig.serverConfig = ServerConfig(isProd)

```


## Testing 

To allow better injection of *fakes* during testing, I’ve modified the `module` function to accept a list of Koin modules:

```kotlin
fun Application.module(testing: Boolean = false, koinModules: List<Module> = listOf(appModule)) {

    install(Koin) {
        slf4jLogger()
        modules(koinModules)
    }
}
```

The default value of that list is a list that contains...

// TODO 







Scaletta:

- Start with the first article. This article is about presentation and how I’ve structured the project. It is an opinioned project structure, there are of course many ways to do it. 
- Dependency injection with koin
- Start with app config 
- Database -> Not, it will be one of the next article topic
- the different api features. Clean architecture alike with data, domain, etc
- Testing setup without mentioning the database.
- The final idea is to have a template to use for ktor project

——

https://insert-koin.io/docs/reference/koin-ktor/ktor/

https://ktor.io/

koin

```cmd
.
├── Application.kt
├── config
│   └── AppConfig.kt
├── database
│   ├── DatabaseFactory.kt
│   └── DatabaseFactoryImpl.kt
├── di
│   └── AppModule.kt
└── features
    └── jokes
        ├── data
        │   ├── JokeLocalDataSource.kt
        │   ├── JokeLocalDataSourceImpl.kt
        │   └── dao
        │       └── Joke.kt
        ├── domain
        │   ├── JokeRepository.kt
        │   ├── JokeRepositoryImpl.kt
        │   ├── mapper
        │   │   └── DTOMapper.kt
        │   └── model
        │       └── JokeDTO.kt
        └── resource
            └── JokeResource.kt
```

```cmd
-config=/config-folder/application.conf
```

```kotlin
interface DatabaseFactory {
    fun connect()
    fun close()
}
```

```kotlin
val appModule = module {
    // Backend Config
    single<AppConfig>()
    singleBy<DatabaseFactory, DatabaseFactoryImpl>()
    singleBy<JokeLocalDataSource, JokeLocalDataSourceImpl>()
    singleBy<JokeRepository, JokeRepositoryImpl>()

}
```

```kotlin
object JokeTable: IdTable<String>(name = "joke") {
    val createdAt = datetime("created_at")
    val updatedAt = datetime("updated_at")
    val value = text("value")

    override val id: Column<EntityID<String>> = varchar("joke_id", 255).entityId()
    override val primaryKey: PrimaryKey = PrimaryKey(id)

}

class Joke(id: EntityID<String>): Entity<String>(id) {
    companion object: EntityClass<String, Joke>(JokeTable)

    var createdAt by JokeTable.createdAt
    var updatedAt by JokeTable.updatedAt
    var value by JokeTable.value
}
```

```kotlin
interface JokeLocalDataSource {
    fun getAllJokes(): List<Joke>
}
```

```kotlin
interface JokeRepository {
    suspend fun getRandomJoke(): JokeDTO
}
```

```kotlin
@Serializable
data class JokeDTO(
    val jokeId: String,
    val jokeContent: String
)
```

```kotlin
fun Joke.toDTO(): JokeDTO {
    return JokeDTO(
        jokeId = this.id.value,
        jokeContent = this.value
    )
}
```

```kotlin

@KtorExperimentalLocationsAPI
@Location("joke")
class JokeEndpoint {

    @Location("/random")
    class Random(val parent: JokeEndpoint)
}
```

```kotlin
@KtorExperimentalLocationsAPI
fun Route.jokeEndpoint() {

    val jokeRepository by inject<JokeRepository>()

    get<JokeEndpoint.Random> {
        call.respond(jokeRepository.getRandomJoke())
    }
}

```

```kotlin 

fun Application.module(testing: Boolean = false, koinModules: List<Module> = listOf(appModule)) {

    install(Koin) {
        slf4jLogger()
        modules(koinModules)
    }

    setupConfig()

    val appConfig by inject<AppConfig>()

    if (!appConfig.serverConfig.isProd) {
        val root = LoggerFactory.getLogger(org.slf4j.Logger.ROOT_LOGGER_NAME) as Logger
        root.level = ch.qos.logback.classic.Level.TRACE
    }

    val databaseFactory by inject<DatabaseFactory>()
    databaseFactory.connect()

    install(ContentNegotiation) {
        json()
    }

    install(CallLogging) {
        level = Level.INFO
    }

    install(Locations)

    routing {
        jokeEndpoint()
        get("/") {
            call.respondText("This is a sample Ktor backend to get Chuck Norris jokes")
        }
    }

    routing {
        // Static feature. Try to access `/static/ktor_logo.svg`
        static("/static") {
            resources("static")
        }

        static {
            resource("doc/swagger.yml", "doc/swagger.yml")
            resource("doc", "doc/index.html")
        }
    }
}
```

Testing:

```kotlin

@KtorExperimentalAPI
fun MapApplicationConfig.createConfigForTesting() {
    // Server config
    put("ktor.server.isProd", "false")
}


@KtorExperimentalLocationsAPI
@KtorExperimentalAPI
fun withTestServer(koinModules: List<Module> = listOf(appTestModule), block: TestApplicationEngine.() -> Unit) {
    withTestApplication(
        {
            (environment.config as MapApplicationConfig).apply {
                createConfigForTesting()
            }
            module(testing = true, koinModules = koinModules)
        }, block
    )
}

val appTestModule = module {
    single<AppConfig>()
    singleBy<DatabaseFactory, DatabaseFactoryForServerTest>()
    singleBy<JokeLocalDataSource, JokeLocalDataSourceImpl>()
}
```

```kotlin

@KtorExperimentalAPI
@KtorExperimentalLocationsAPI
class JokeResourceTest : AutoCloseKoinTest() {

    @Test
    fun `random joke api works correctly`() = withTestServer(
        koinModules = appTestModule.plus(
            module {
                // Just to showcase the possibility, in this case this dependency can be put in the base test module
                singleBy<JokeRepository, JokeRepositoryImpl>()
            }
        )
    ) {

        // Setup
        val joke = transaction {
            Joke.new("joke_1") {
                this.value = "Chuck Norris tests are always green"
                this.createdAt = LocalDateTime.now()
                this.updatedAt = LocalDateTime.now()
            }
        }

        val href = application.locations.href(
            JokeEndpoint.Random(
                parent = JokeEndpoint()
            )
        )

        handleRequest(HttpMethod.Get, href).apply {
            assertEquals(HttpStatusCode.OK, response.status())

            val response = Json.decodeFromString<JokeDTO>(response.content!!)

            assertEquals(transaction { joke.id.value }, response.jokeId)
            assertEquals(transaction { joke.value }, response.jokeContent)
        }
    }
}

```

```bash

.
├── logs
│   ├── ktor-chuck-norris-sample.2021-03-09.log
│   └── ktor-chuck-norris-sample.log
└── src
    ├── main
    │   ├── kotlin
    │   │   └── com
    │   │       └── prof18
    │   │           └── ktor
    │   │               └── chucknorris
    │   │                   └── sample
    │   │                       ├── Application.kt
    │   │                       ├── config
    │   │                       │   └── AppConfig.kt
    │   │                       ├── database
    │   │                       │   ├── DatabaseFactory.kt
    │   │                       │   └── DatabaseFactoryImpl.kt
    │   │                       ├── di
    │   │                       │   └── AppModule.kt
    │   │                       └── features
    │   │                           └── jokes
    │   │                               ├── data
    │   │                               │   ├── JokeLocalDataSource.kt
    │   │                               │   ├── JokeLocalDataSourceImpl.kt
    │   │                               │   └── dao
    │   │                               │       └── Joke.kt
    │   │                               ├── domain
    │   │                               │   ├── JokeRepository.kt
    │   │                               │   ├── JokeRepositoryImpl.kt
    │   │                               │   ├── mapper
    │   │                               │   │   └── DTOMapper.kt
    │   │                               │   └── model
    │   │                               │       └── JokeDTO.kt
    │   │                               └── resource
    │   │                                   └── JokeResource.kt
    │   └── resources
    │       ├── application.conf
    │       ├── db
    │       │   └── migration
    │       │       ├── changesets
    │       │       │   ├── changeset-202102281045.sql
    │       │       │   └── changeset-202102281050.sql
    │       │       └── migrations.xml
    │       ├── doc
    │       │   ├── index.html
    │       │   └── swagger.yml
    │       ├── logback.xml
    │       ├── static
    │       │   └── index.html
    │       └── swagger
    │           └── swagger.yml
    └── test
        ├── kotlin
        │   └── com
        │       └── prof18
        │           └── ktor
        │               └── chucknorris
        │                   └── sample
        │                       ├── features
        │                       │   └── jokes
        │                       │       ├── domain
        │                       │       │   └── JokeRepositoryImplTest.kt
        │                       │       └── resource
        │                       │           └── JokeResourceTest.kt
        │                       └── testutils
        │                           ├── TestServer.kt
        │                           └── database
        │                               ├── DatabaseFactoryForServerTest.kt
        │                               ├── DatabaseFactoryForUnitTest.kt
        │                               └── SchemaDefinition.kt
        └── resources
            └── logback-test.xml

104 directories, 325 files

```

The sample project is available [on GitHub](https://github.com/prof18/ktor-chuck-norris-sample). 

// TODO: place the code for this article in a specific branch? Create a branch for every article?