# How to handle database migrations with Liquibase on Ktor



{{< rawhtml >}}

<a href="https://us12.campaign-archive.com/?u=f39692e245b94f7fb693b6d82&id=f4f6d67da0"><img style="margin: 0px;" src="https://img.shields.io/badge/Featured%20in%20kotlinweekly.net-Issue%20%23289-%237874b4"/></a>


{{< /rawhtml >}}

{{< admonition abstract "SERIES: Building a backend with Ktor" true >}}

- Part 1: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/)
- Part 2: [How to persist Ktor logs](https://www.marcogomiero.com/posts/2021/ktor-logging-on-disk/)
- Part 3: [How to use an in-memory database for testing on Ktor](https://www.marcogomiero.com/posts/2021/ktor-in-memory-db-testing/)
- Part 4: How to handle database migrations with Liquibase on Ktor
- Part 5 [Generate API documentation from Swagger on Ktor](https://www.marcogomiero.com/posts/2022/ktor-setup-documentation/)
{{< /admonition >}}

Databases are an important and critical part of backend infrastructures. They are the place where all the information is stored and that data cannot be compromised or lost. That’s why it is important to have proper management of the evolution of the database: it is necessary to be able to modify the schema, migrate the data, or roll back to a previous schema version if something unexpected happened.

There are many different products or tools to manage a database schema, for example [Flyway](https://github.com/flyway/flyway) or [Liquibase](https://github.com/liquibase/liquibase).

In this article, I will cover how to set up Liquibase in a Ktor project and how to create two Gradle tasks responsible to migrate a test and a production MySQL database. There is also a [pro version](https://www.liquibase.com/products) of Liquibase, but the free community version was enough for me.

This post is part of a series of posts dedicated to Ktor where I cover all the topics that made me struggle during development and that was not easy to achieve out of the box. You can check out the other instances of the series in the index above or [follow me on Twitter](https://twitter.com/marcoGomier) to keep up to date.

## Setup

The first thing to do is to add all the required dependencies. The starting point is the [Gradle plugin](https://github.com/liquibase/liquibase-gradle-plugin) in the `build.gradle.kts` file:

```kotlin
plugins {
    id("org.liquibase.gradle") version "<version-number>"
}
```

After syncing the project, it is possible to add now the required dependencies for the Liquibase runtime:

```kotlin
liquibaseRuntime("org.liquibase:liquibase-core:$liquibase_core")
liquibaseRuntime("mysql:mysql-connector-java:$mysql_connector_version")
liquibaseRuntime("ch.qos.logback:logback-core:1.2.3")
liquibaseRuntime("ch.qos.logback:logback-classic:1.2.3")
liquibaseRuntime("javax.xml.bind:jaxb-api:2.2.4")
```

*Note that here `liquibaseRuntime` is used instead of the usual `implementation`*

Besides the core functionality, the other dependencies are necessary for the database connection, for logging, and for parsing XML, since all the data about the migrations will be saved in an XML file (as shown later on).

## Configuring the migration task

To perform the database migrations, it is necessary to connect to the database, and to do so, some access information, like the database URL, the user, and the password, need to be stored somewhere and retrieved.

The access information can be saved, for example, on `local.properties` or in the environment variables:

```properties
liquibase.dev.url=jdbc:mysql://localhost:3308/chucknorris
liquibase.dev.pwd=password
liquibase.dev.user=root

liquibase.prod.url=jdbc\:mysql\://your-url.com
liquibase.prod.pwd=password
liquibase.prod.user=user
```

and can be retrieved in the `build.gradle.kts` file:

```kotlin
val propertiesFile = file("local.properties")
val properties = Properties()
if (propertiesFile.exists()) {
    properties.load(propertiesFile.inputStream())
}

val urlDev = properties.getProperty("liquibase.dev.url") ?: System.getenv("LIQUIBASE_DEV_URL")
val userDev = properties.getProperty("liquibase.dev.user") ?: System.getenv("LIQUIBASE_DEV_USER")
val pwdDev = properties.getProperty("liquibase.dev.pwd") ?: System.getenv("LIQUIBASE_DEV_PWD")

val urlProd = properties.getProperty("liquibase.prod.url") ?: System.getenv("LIQUIBASE_PROD_URL")
val userProd = properties.getProperty("liquibase.prod.user") ?: System.getenv("LIQUIBASE_PROD_USER")
val pwdProd = properties.getProperty("liquibase.prod.pwd") ?: System.getenv("LIQUIBASE_PROD_PWD")
```

The migration task can be configured and customized by providing some parameters in the `activities.register` block, inside the `liquibase` block.

```kotlin
liquibase {
    activities.register {
        this.arguments = mapOf(
            "logLevel" to "info",
            "changeLogFile" to "<file-path>",
            "url" to urlProd,
            "username" to userProd,
            "password" to pwdProd,
        )
    }
}
```

The ones that I’ve provided are the following, but you can find more parameters in the [Liquibase documentation](https://docs.liquibase.com/commands/home.html):

- `logInfo` -> execution log level (`debug`, `info`, `warning`, `severe`, `off`).
- `changeLogFile` -> the path of the changelog XML file to use;
- `url` -> database JDBC URL;
- `username` -> database username;
- `password` -> database password;

The location where the changelog `XML` file and the `SQL` files can be freely chosen depending on the project. I’ve decided to put them in the `resources` folder of the project, with the following structure:

```
.
└── src
    ├── main
        ├── kotlin
        └── resources
            ├── db
                └── migration
                    ├── changesets
                    │   ├── changeset-202102281045.sql
                    │   └── changeset-202102281050.sql
                    └── migrations.xml
```

The SQL files are contained in the `changesets` subfolder and are named with the following pattern to make the file unique: `changeset-YearMonthDayHourMinute.sql`

The `migrations.xml` file contains the definitions of every migration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
        xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.1.xsd">

    <changeSet id="202102281045" author="Marco">
        <comment>Jokes Table</comment>
        <sqlFile path="src/main/resources/db/migration/changesets/changeset-202102281045.sql"/>
    </changeSet>

    <changeSet id="202102281050" author="Marco">
        <comment>Jokes Data</comment>
        <sqlFile path="src/main/resources/db/migration/changesets/changeset-202102281050.sql"/>
    </changeSet>

</databaseChangeLog>
```

Every migration is represented by a `changeSet`, that has a unique ID. An ID could be, for example, the *YearMonthDayHourMinute* used for the file name.
In the changeSet object, it is necessary to provide the path of the SQL file for the migration, and also a comment can be added.

```xml
<changeSet id="202102281050" author="Marco">
    <comment>Jokes Data</comment>
    <sqlFile path="src/main/resources/db/migration/changesets/changeset-202102281050.sql"/>
</changeSet>
```

Finally, at this point, it is possible to run the Gradle task that will perform the database migration.

```bash
./gradlew update
```

## Migrating multiple databases

As shown above, every `activity` registered in the `liquibase` block corresponds to a different database instance to connect to. However, to connect and migrate different databases instances, it is necessary to register different `activity` with different names.

```kotlin
liquibase {
    activities.register("dev") {
        this.arguments = mapOf(
            "logLevel" to "info",
            "changeLogFile" to "<file-path>",
            "url" to urlDev,
            "username" to userDev,
            "password" to pwdDev,
        )
    }

    activities.register("prod") {
        this.arguments = mapOf(
            "logLevel" to "info",
            "changeLogFile" to "<file-path>",
            "url" to urlProd,
            "username" to userProd,
            "password" to pwdProd,
        )
    }
}
```

By default, the Liquibase plugin will run every activity. However, it is possible to set the `runList` parameter with the name of the activities to run:

```kotlin
liquibase {
    ...
    runList = “dev,prod”
}
```

The value of the parameter can also be provided from the command line when running the Gradle task. To do that, it is necessary to first define an empty variable in the `gradle.properties` file:

```properties
dbEnv=
```

Then the variable will be retrieved in the `build.gradle.kts` file and assigned to the `runList` parameter:

```kotlin
val dbEnv: String by project.ext

liquibase {
    ...
    runList = dbEnv
}
```

The value of the variable can then be injected from the command line with the following argument:

```bash
./gradlew update -PdbEnv=dev
```

## Conclusions

And that’s it for today. You can find the code mentioned in the article on [GitHub](https://github.com/prof18/ktor-chuck-norris-sample/tree/part4).

In the next episode, I’ll cover how to show the API documentation from a Swagger specification. You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episodes.

