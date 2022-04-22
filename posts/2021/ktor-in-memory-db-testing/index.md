# How to use an in-memory database for testing on Ktor


{{< rawhtml >}}

<div id="banner" style="overflow: hidden;justify-content:space-around;">

    <div style="display: inline-block;margin-right: 10px;">
        <a href="https://androidweekly.net/issues/issue-487"><img style="margin: 0px;" src="https://androidweekly.net/issues/issue-487/badge" /></a>
    </div>

    <div style="display: inline-block;">
     <a href="https://us12.campaign-archive.com/?u=f39692e245b94f7fb693b6d82&id=2b57b99606"><img style="margin: 0px;" src="https://img.shields.io/badge/Featured%20in%20kotlinweekly.net-Issue%20%23271-%237874b4"/></a>

    </div>
</div>

{{< /rawhtml >}}

{{< admonition abstract "SERIES: Building a backend with Ktor" true >}}

- Part 1: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/)
- Part 2: [How to persist Ktor logs](https://www.marcogomiero.com/posts/2021/ktor-logging-on-disk/)
- Part 3: How to use an in-memory database for testing on Ktor
- Part 4: [How to handle database migrations with Liquibase on Ktor](https://www.marcogomiero.com/posts/2022/ktor-migration-liquibase/)
- Part 5 [Generate API documentation from Swagger on Ktor](https://www.marcogomiero.com/posts/2022/ktor-setup-documentation/)
- Part 6: [How to schedule jobs with Quartz on Ktor](https://www.marcogomiero.com/posts/2022/ktor-jobs-quartz/)
{{< /admonition >}}

Usually, in a backend project, there are different instances of the same database: one for production (or more than one, it depends on the architecture), one for staging, and a local one that runs in the development machine.

However, for automated testing, none of these databases will be suitable to use. Since the purpose of testing is checking that every part of the software is working as expected, it will be necessary to test also situations where there isn’t any data saved in the database. To achieve that, the database must be cleared after every test (or group of tests) or pre-populated before.

An approach to achieve that is using an in-memory database. As the name suggests, all the data will be saved in memory and not on disk, so they can be easily deleted when closing the database connection. Another approach could be using Docker to spin up every time a dedicated container for the database, to have a database that is like the one used in production. In my case, I preferred to use an in-memory solution but if you are interested in the topic, I suggest looking at this article by Philip Hauer: [Don't use In-Memory Databases (H2, Fongo) for Tests](https://phauer.com/2017/dont-use-in-memory-databases-tests-h2/)

In this article, I will cover how to setup an in-memory database with [H2](https://www.h2database.com/html/main.html) for testing on a Ktor project that uses a MySQL database in production.

This post is part of a series of posts dedicated to Ktor where I cover all the topics that made me struggle during development and that was not easy to achieve out of the box. You can check out the other instances of the series in the index above or [follow me on Twitter](https://twitter.com/marcoGomier) to keep up to date.

## Setup

The ORM that I’ve decided to use is [Exposed](https://github.com/JetBrains/Exposed) from Jetbrains. It is very nice to deal with and it offers the possibility to use a typesafe DSL that wraps SQL and a lightweight data access object.
Exposed supports different databases like MySQL, H2, PostgreSQL, SQLite. For a complete list, refer [to the documentation](https://github.com/JetBrains/Exposed#supported-databases).

Exposed comes with a [different set of artifacts](https://github.com/JetBrains/Exposed/wiki/Getting-Started) that you can decide to use. For this project I’ve added the following:

```kotlin
implementation("org.jetbrains.exposed:exposed-core:$exposed_version")
implementation("org.jetbrains.exposed:exposed-dao:$exposed_version")
implementation("org.jetbrains.exposed:exposed-jdbc:$exposed_version")
```

The connection to the MySQL database is performed with the JDBC driver and with a connection pool provided by [Hikari](https://github.com/brettwooldridge/HikariCP).

```kotlin
implementation("com.zaxxer:HikariCP:$hikaricp_version")
implementation("mysql:mysql-connector-java:$mysql_connector_version")
```

The last required dependency is [H2](https://github.com/h2database/h2database) that is needed only for tests.

```kotlin
testImplementation("com.h2database:h2:$h2_version")
```

## Database Connection:

The connection and the disposal of the database is performed through a method defined in the `DatabaseFactory` interface

```kotlin
interface DatabaseFactory {
	fun connect()
	fun close()
}
```

This interface will then have a different implementation, depending on if the server is running in production or for unit or integration testing.

The factory implementation used in production creates a private  *HikariDataSource* that will be used by the `connect` method

```kotlin
class DatabaseFactoryImpl(appConfig: AppConfig) : DatabaseFactory {

	private val dbConfig = appConfig.databaseConfig

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

        // More configuration suggestions from https://github.com/brettwooldridge/HikariCP/wiki/MySQL-Configuration

        config.validate()
        return HikariDataSource(config)
	}

	override fun close() {
        // used only on Unit tests
	}
}
```

The `connect` method will be called inside the Ktor module function during the initialization and the setup of the server.

```kotlin
fun Application.module(testing: Boolean = false, koinModules: List<Module> = listOf(appModule)) {
	...
	val databaseFactory by inject<DatabaseFactory>() databaseFactory.connect()
	...
}
```

As you may have noticed, the `DatabaseFactoryImpl` class uses some fields provided by `AppConfig`. These fields are the driver class used for the connection, the name, user, and password of the database, and other fields that are specific to the connection. These fields are placed inside the `application.conf` file to be able to change them on different instances of the server.

```hocon
ktor {

  ...

  database {
    driverClass = "com.mysql.cj.jdbc.Driver"
    url = "jdbc:mysql://localhost:3308/chucknorris?useUnicode=true&characterEncoding=UTF-8"
    user = "root"
    password = "password"
    maxPoolSize = 3
  }
}
```

After adding the `database` block, it is necessary to update accordingly the `AppConfig` class.

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

fun Application.setupConfig() {

	...

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

For more informations about the configuration process, you can give a look at the first episode of the series: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure#configuration)

## Testing

For testing, it is necessary to cover two different situations: unit tests and integration tests (in this case I refer to integration tests that involve the server).

### Setup

**Integration testing** that involves the server is performed with a `TestEngine` that does not create a web server but hooks directly into the internal mechanism. For more information about testing on Ktor, you can look at the first episode of the series: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure#testing). When this type of test is run, the same Ktor module function that initializes the server on production is called. In this way, the connection of the database is automatically performed.

When running **unit tests** instead, the server is not involved, so the connection to the database must be performed manually.

These two behaviors can be achieved with two implementations of the `DatabaseFactory`: `DatabaseFactoryForServerTest` and `DatabaseFactoryForUnitTest`.

The former receives the configuration data from the `AppConfig` class since the Ktor module function will be called.

```kotlin
class DatabaseFactoryForServerTest(appConfig: AppConfig): DatabaseFactory {

	...

	private fun hikari(): HikariDataSource {
        val config = HikariConfig()
        config.driverClassName = dbConfig.driverClass
        config.jdbcUrl = dbConfig.url
        config.maximumPoolSize = dbConfig.maxPoolSize
        config.isAutoCommit = true
        config.validate()
        return HikariDataSource(config)
	}

	...
}
```

The latter instead has the configuration data hardcoded since the connection to the database must be performed manually.

```kotlin
class DatabaseFactoryForUnitTest: DatabaseFactory {

	...

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

    ...
}
```

Since the database used is **H2**, the driver and the URL change a bit.
The driver class name is now: `org.h2.Driver` and the URL is: `jdbc:h2:mem:;DATABASE_TO_UPPER=false;MODE=MYSQL`. The URL specifies also some features:
- `mem` -> it tells to use the in-memory version of H2
- `:` -> it does not specify a name for the database
- `DATABASE_TO_UPPER=false` -> it disable the default feature of using uppercase for identifiers. For example, if it is not disabled, the table names are uppercase and queries will fail
- `MODE=MYSQL` -> it uses the MySQL compatibility mode in order to have the same features of MySQL.

To learn more about H2 database settings and features, I suggest you to look at the documentation for [settings](https://www.h2database.com/javadoc/org/h2/engine/DbSettings.html) and [features](http://www.h2database.com/html/features.html).

After the connection to the database, it is necessary to create its structure, since the database will be destroyed after each test (or after a set of tests).

To do that, it is possible to use the features of Exposed.
After defining a table with the Exposed DSL (for more info about it, give a look at the [Exposed documentation](https://github.com/JetBrains/Exposed/wiki/DSL)):

```kotlin
object JokeTable: IdTable<String>(name = "joke") {
	val createdAt = datetime("created_at")
	val updatedAt = datetime("updated_at")
	val value = text("value")

	override val id: Column<EntityID<String>> = varchar("joke_id", 255).entityId()
	override val primaryKey: PrimaryKey = PrimaryKey(id)
}
```

it is possible to create the table:

```kotlin
SchemaUtils.create(JokeTable)
```

Since this operation must be repeated for every table, it is better to create a function that can be called inside the DatabaseFactory.

```kotlin
object SchemaDefinition {
	fun createSchema() {
        transaction {
            SchemaUtils.create(JokeTable)
        }
	}
}
```

The `connect` function in both the database factories will look like that:

```kotlin
override fun connect() {
	Database.connect(hikari())
	SchemaDefinition.createSchema()
}
```

However, during unit tests, it is necessary to manually close the connection to the database, to be sure that all the data are cleared between each test run. To be able to do that, it is necessary to store in the Factory an instance of `HikariDataSource` that can be closed with the `close` method.

```kotlin
class DatabaseFactoryForUnitTest: DatabaseFactory {

	lateinit var source: HikariDataSource

	...

	private fun hikari(): HikariDataSource {
        val config = HikariConfig()
        ...
        source = HikariDataSource(config)
        return source
	}

	override fun close() {
        source.close()
	}
}
```

As reference, here are the entire `DatabaseFactoryForServerTest` and `DatabaseFactoryForUnitTest` class.

```kotlin
class DatabaseFactoryForServerTest(appConfig: AppConfig): DatabaseFactory {

	private val dbConfig = appConfig.databaseConfig

	override fun connect() {
		Database.connect(hikari())
		SchemaDefinition.createSchema()
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

	override fun close() {
        // used only for Unit tests
	}
}
```

```kotlin
class DatabaseFactoryForUnitTest: DatabaseFactory {

	lateinit var source: HikariDataSource

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

	override fun close() {
		source.close()
	}
}
```

### Execution

As mentioned early, during **integration tests** that involve the server, the database connection is performed automatically since the Ktor module function will be called. The only thing to do is to replace in the Koin test module the `DatabaseFactory` implementation from `DatabaseFactoryImpl`, which is used in production, to `DatabaseFactoryForServerTest`.

```kotlin
val appTestModule = module {
	...
	singleBy<DatabaseFactory, DatabaseFactoryForServerTest>()
	...
}
```

As you can see in the following example of test, it is not required any initialization or setup in the test class.

```kotlin
class JokeResourceTest : AutoCloseKoinTest() {

	@Test
	fun `random joke api works correctly`() = withTestServer() {

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

On **unit tests** instead, the connection and the disconnection from the database must be performed manually before and after the test, or whenever it is necessary.

```kotlin
class JokeRepositoryImplTest : KoinTest {

    private lateinit var databaseFactory: DatabaseFactoryForUnitTest

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
    fun `getRandomJoke returns data correctly`() = runBlockingTest {
        ...
    }
}
```


## Conclusions

And that’s it for today. You can find the code mentioned in the article on [GitHub](https://github.com/prof18/ktor-chuck-norris-sample/tree/part3).

In the next episode, I’ll cover database migrations. You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episodes.









