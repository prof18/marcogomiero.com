---
layout: post
title:  "Ktor setup with in memory database for testing"
date:   2021-03-09
show_in_homepage: true
draft: true
tags: [Ktor]
---

SERIES: Building a backend with Ktor

- Part 1: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/)
- Part 2: [How to persist Ktor logs](https://www.marcogomiero.com/posts/2021/ktor-logging-on-disk/)
- Part 3: database setup with in memory for testing
- Part 4: database migration with liquibase
- Part 5: setup documentation with swagger.
- Part 6: conclusion, perspective from mobile dev, etc.
___



## Conclusions

And that’s it for today. You can find the code mentioned in the article on [GitHub](https://github.com/prof18/ktor-chuck-norris-sample/tree/part3). 

In the next episodes, I’ll cover in-memory database and migrations. You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episode. 



——

https://github.com/brettwooldridge/HikariCP

https://www.h2database.com/html/main.html

https://github.com/JetBrains/Exposed

https://github.com/JetBrains/Exposed/wiki
https://github.com/JetBrains/Exposed/wiki/DSL
https://github.com/JetBrains/Exposed/wiki/DAO

build.gradle.kts

```kotlin
 // Database
    implementation("org.jetbrains.exposed:exposed-core:$exposed_version")
    implementation("org.jetbrains.exposed:exposed-dao:$exposed_version")
    implementation("org.jetbrains.exposed:exposed-jdbc:$exposed_version")
    implementation("org.jetbrains.exposed:exposed-java-time:$exposed_version")
    implementation("mysql:mysql-connector-java:$mysql_connector_version")
    implementation("com.zaxxer:HikariCP:$hikaricp_version")

   
    testImplementation("com.h2database:h2:$h2_version")

```


application.conf

```cocon
ktor {
  deployment {
    port = 8080
    port = ${?PORT}
  }
  application {
    modules = [com.prof18.ktor.chucknorris.sample.ApplicationKt.module]
  }

  server {
    isProd = false
  }

  database {
    driverClass = "com.mysql.cj.jdbc.Driver"
    url = "jdbc:mysql://localhost:3308/chucknorris?useUnicode=true&characterEncoding=UTF-8"
    user = "root"
    password = "password"
    maxPoolSize = 3
  }
}
```

AppConfig.kt

```kotlin
data class DatabaseConfig(
    val driverClass: String,
    val url: String,
    val user: String,
    val password: String,
    val maxPoolSize: Int
)

class AppConfig {
    lateinit var databaseConfig: DatabaseConfig
    lateinit var serverConfig: ServerConfig
    // Place here other configurations
}


// Database
    val databaseObject = environment.config.config("ktor.database")
    val driverClass = databaseObject.property("driverClass").getString()
    val url = databaseObject.property("url").getString()
    val user = databaseObject.property("user").getString()
    val password = databaseObject.property("password").getString()
    val maxPoolSize = databaseObject.property("maxPoolSize").getString().toInt()
    appConfig.databaseConfig = DatabaseConfig(driverClass, url, user, password, maxPoolSize)
}

```


DatabaseFactory.kt

```kotlin
interface DatabaseFactory {
    fun connect()
    fun close()
}
```

DatabaseFactoryImpl.kt

```
class DatabaseFactoryImpl(appConfig: AppConfig) : DatabaseFactory {

    private val dbConfig = appConfig.databaseConfig

    override fun close() {
        // not necessary
    }

    override fun connect() {
        Database.connect(hikari())
    }

    private fun hikari(): HikariDataSource {
        val config = HikariConfig()
        config.driverClassName = dbConfig.driverClass
        config.jdbcUrl = dbConfig.url
        config.username = dbConfig.user
        config.password = dbConfig.password
        config.maximumPoolSize = dbConfig.maxPoolSize
        config.isAutoCommit = false
        config.transactionIsolation = "TRANSACTION_REPEATABLE_READ"

        // Suggestions from https://github.com/brettwooldridge/HikariCP/wiki/MySQL-Configuration
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        config.addDataSourceProperty("useServerPrepStmts", "true");
        config.addDataSourceProperty("useLocalSessionState", "true");
        config.addDataSourceProperty("rewriteBatchedStatements", "true");
        config.addDataSourceProperty("cacheResultSetMetadata", "true");
        config.addDataSourceProperty("cacheServerConfiguration", "true");
        config.addDataSourceProperty("elideSetAutoCommits", "true");
        config.addDataSourceProperty("maintainTimeStats", "false");

        config.validate()
        return HikariDataSource(config)
    }
}

```


AppModule.kt

```kotlin
val appModule = module {
    // Backend Config
    single<AppConfig>()
    singleBy<DatabaseFactory, DatabaseFactoryImpl>()
    singleBy<JokeLocalDataSource, JokeLocalDataSourceImpl>()
    singleBy<JokeRepository, JokeRepositoryImpl>()

}
```

Application.kt

```kotlin

fun Application.module(testing: Boolean = false, koinModules: List<Module> = listOf(appModule)) {
	...
	val databaseFactory by inject<DatabaseFactory>() databaseFactory.connect()
	...
}	
```


JokeDAO, maybe skip this

```kotlin
bject JokeTable: IdTable<String>(name = "joke") {
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

JokeLocalDataSource

```kotlin
interface JokeLocalDataSource {
    fun getAllJokes(): List<Joke>
}

class JokeLocalDataSourceImpl : JokeLocalDataSource {

    override fun getAllJokes(): List<Joke> {
        val query = JokeTable.selectAll()
        return Joke.wrapRows(query).toList()
    }
}
```

TESTING

DatabaseFactoryForServerTest

```kotlin
class DatabaseFactoryForServerTest(appConfig: AppConfig): DatabaseFactory {

    private val dbConfig = appConfig.databaseConfig

    override fun connect() {
        Database.connect(hikari())
        SchemaDefinition.createSchema()
    }

    override fun close() {
        // not needed
    }

    private fun hikari(): HikariDataSource {
        val config = HikariConfig()
        config.driverClassName = dbConfig.driverClass
        config.jdbcUrl = dbConfig.url
        config.maximumPoolSize = dbConfig.maxPoolSize
        config.isAutoCommit = true
        config.validate()
        return HikariDataSource(config)
    }
}
```


DatabaseFactoryForUnitTest

```kotlin
class DatabaseFactoryForUnitTest: DatabaseFactory {

    lateinit var source: HikariDataSource

    override fun close() {
        source.close()
    }

    override fun connect() {
        Database.connect(hikari())
        SchemaDefinition.createSchema()
    }

    private fun hikari(): HikariDataSource {
        val config = HikariConfig()
        config.driverClassName = "org.h2.Driver"
        config.jdbcUrl = "jdbc:h2:mem:;DATABASE_TO_UPPER=false;MODE=MYSQL"
        config.maximumPoolSize = 2
        config.isAutoCommit = true
        config.validate()
        source = HikariDataSource(config)
        return source
    }
}
```

SchemaDefinition

```kotlin
object SchemaDefinition {

    fun createSchema() {
        transaction {
            SchemaUtils.create(JokeTable)
        }
    }
}
```

AppTestModule

```kotlin
val appTestModule = module {
    single<AppConfig>()
    singleBy<DatabaseFactory, DatabaseFactoryForServerTest>()
    singleBy<JokeLocalDataSource, JokeLocalDataSourceImpl>()
}
```

What JokeRepository does, just to give context

```kotlin
    override suspend fun getRandomJoke(): JokeDTO {
        val jokeDTO = newSuspendedTransaction {
            val allJokes = jokeLocalDataSource.getAllJokes()
            val randomJoke = allJokes.random()
            return@newSuspendedTransaction randomJoke.toDTO()
        }
        return jokeDTO
    }
}
```


JokeRepositoryTest

```kotlin
class JokeRepositoryImplTest : KoinTest {

    private lateinit var databaseFactory: DatabaseFactoryForUnitTest

    @get:Rule
    val koinTestRule = KoinTestRule.create {
        // Your KoinApplication instance here
        modules(module {
            singleBy<JokeLocalDataSource, JokeLocalDataSourceImpl>()
            singleBy<JokeRepository, JokeRepositoryImpl>()
        })
    }

    private val jokeRepository: JokeRepository by inject()

    @Before
    fun setup() {
        databaseFactory = DatabaseFactoryForUnitTest()
        databaseFactory.connect()
    }

    @After
    fun tearDown() {
        databaseFactory.close()
    }

    @Test
    fun `getRandomJoke returns data correctly`() = runBlocking {
        // Setup
        val joke = transaction {
            Joke.new("joke_1") {
                this.value = "Chuck Norris tests are always green"
                this.createdAt = LocalDateTime.now()
                this.updatedAt = LocalDateTime.now()
            }
        }

        // Act
        val randomJoke = jokeRepository.getRandomJoke()

        // Assert
        assertEquals(transaction { joke.id.value }, randomJoke.jokeId)
        assertEquals(transaction { joke.value }, randomJoke.jokeContent)
    }
}
```

JokeResourceTest

```kotlin
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