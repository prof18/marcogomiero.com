---
layout: post
title:  "How to handle database migrations with Liquibase on Ktor"
date:   2021-08-07
show_in_homepage: false
draft: true
---

{{< admonition abstract "SERIES: Building a backend with Ktor" true >}}

- Part 1: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/)
- Part 2: [How to persist Ktor logs](https://www.marcogomiero.com/posts/2021/ktor-logging-on-disk/)
- Part 3: [How to use an in-memory database for testing on Ktor](https://www.marcogomiero.com/posts/2021/ktor-in-memory-db-testing/)
- Part 4: How to handle database migrations with Liquibase on Ktor
{{< /admonition >}}

Databases are an important and critical part of a backend infrastructure. They are the place where all the informations are stored and that data cannot be compromised or lost. That’s why it is important to have a proper management of the evolution of the database: it is necessary to be able to modifying the schema, migrate the data or rollback to a previous schema version if something unexpected happened. 

There are many different products or tools to manage a database schema, for example [Flyway](https://github.com/flyway/flyway) or [Liquibase](https://github.com/liquibase/liquibase). 


 

---

In a backend you have a database but you need also to properly manage it. Migration, rollback etc. Have to do it without compromising the server.

Different solutions, for example Flyway

https://github.com/flyway/flyway

https://www.thebookofjoel.com/kotlin-ktor-exposed-postgres

I’ve tried it but didn’t like because you have to run the migration when the program is running with a method and I don’t like it, I prefer unbundled from the backend. Otherwise if something goes wrong I will have the backend down until I will fix the issue. 

So I’ve found out about Liquibase where I can run the migration with a gradle task. Liquibase has different feature a pro version, but the free community version was enough for me. 

https://www.liquibase.com/products

https://www.liquibase.org/

https://github.com/liquibase/liquibase

Liquibase helps millions of teams track, version, and deploy database schema changes. It will help you to:

Control database schema changes for specific versions
Eliminate errors and delays when releasing databases
Automatically order scripts for deployment
Easily rollback changes
Collaborate with tools you already use

rapidly manage database schema changes.

In this article, I will cover how to setup an in-memory database with [H2](https://www.h2database.com/html/main.html) for testing on a Ktor project that uses a MySQL database in production.

This post is part of a series of posts dedicated to Ktor where I cover all the topics that made me struggle during development and that was not easy to achieve out of the box. You can check out the other instances of the series in the index above or [follow me on Twitter](https://twitter.com/marcoGomier) to keep up to date.


## Setup 
 
 The first things to do is add the plugin on gradle 

build.gradle.kts

```kotlin
plugins {
    application
    kotlin("jvm") version "1.4.30"
    id("org.jetbrains.kotlin.plugin.serialization") version "1.4.30"
    id("org.liquibase.gradle") version "2.0.4"
}
```

After adding the plugin it is possibile to add the dependencies with liquibaseRuntime instead of implementation. The dependencies add the core functionalities, logging, jdbc connection and xml parsing api.

```kotlin
liquibaseRuntime("org.liquibase:liquibase-core:$liquibase_core")
liquibaseRuntime("mysql:mysql-connector-java:$mysql_connector_version")
liquibaseRuntime("ch.qos.logback:logback-core:1.2.3")
liquibaseRuntime("ch.qos.logback:logback-classic:1.2.3")
liquibaseRuntime("javax.xml.bind:jaxb-api:2.2.4")
```


Then it is necessary to create the tasks to perform the migration. Need to declare two different one, one for production database and one for local development. For local development, the data can be hardcoded while for remote one it is better to have them store in the local.properties file 

```kotlin
// Database migrations
val dbEnv: String by project.ext

val propertiesFile = file("local.properties")
val properties = Properties()
if (propertiesFile.exists()) {
    properties.load(propertiesFile.inputStream())
}

liquibase {
    activities.register("dev") {
        this.arguments = mapOf(
            "logLevel" to "info",
            "changeLogFile" to "src/main/resources/db/migration/migrations.xml",
            "url" to "jdbc:mysql://localhost:3308/chucknorris",
            "username" to "root",
            "password" to "password"
        )
    }

    activities.register("prod") {
        val url = properties.getProperty("liquibase.url") ?: System.getenv("LIQUIBASE_URL")
        val user = properties.getProperty("liquibase.user") ?: System.getenv("LIQUIBASE_USER")
        val pwd = properties.getProperty("liquibase.pwd") ?: System.getenv("LIQUIBASE_PWD")

        this.arguments = mapOf(
            "logLevel" to "info",
            "changeLogFile" to "/resources/db/migration/migrations.xml",
            "url" to url,
            "username" to user,
            "password" to pwd
        )
    }
    runList = dbEnv
}
```

local.properties
```properties
liquibase.url=jdbc\:mysql\://your-url.com
liquibase.pwd=password
liquibase.user=user
```

The gradle command to perform the migration is

```bash
./gradlew update

```

To decide which database to migration and which task to run, is decided by the `runList = dbEnv` variable.

The value of the variable can be injected from the command line with 

```bash
./gradlew update -PdbEnv=dev
```

The variable is defined in gradle.properties and then reassigned  with each run

```kotlin
val dbEnv: String by project.ext
```

gradle.properties
```properties
dbEnv=
```


## Execution

The database migration that will be performed must be saved inside the resource directory in an sql file

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

changeset-202102281045.sql
```sql
# From https://github.com/chucknorris-io/chuck-db

# Joke table
CREATE TABLE IF NOT EXISTS joke
(
    created_at TIMESTAMP NOT NULL ,
    joke_id    VARCHAR(255) PRIMARY KEY,
    updated_at TIMESTAMP NOT NULL ,
    value      TEXT NOT NULL
);
```

Then, the list of migrations are defined in the migrations.xml file. Remember to assaign an unique id to the entry in the xml and as file name. I usually use 202102281045 2021 02 28 10 45. YearMonthDayHourMinute. 

migrations.xml

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

## Conclusions

And that’s it for today. You can find the code mentioned in the article on [GitHub](https://github.com/prof18/ktor-chuck-norris-sample/tree/part3). 

In the next episode, I’ll cover database migrations. You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episodes.