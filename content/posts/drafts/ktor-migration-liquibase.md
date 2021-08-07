---
layout: post
title:  "Ktor database migration Liquibase"
date:   2021-08-07
show_in_homepage: false
draft: true
---

{{< admonition abstract "SERIES: Building a backend with Ktor" true >}}

- Part 1: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/)
- Part 2: [How to persist Ktor logs](https://www.marcogomiero.com/posts/2021/ktor-logging-on-disk/)
- Part 3: [How to use an in-memory database for testing on Ktor](https://www.marcogomiero.com/posts/2021/ktor-in-memory-db-testing/)
- Part 4: TODO "Ktor database migration Liquibase"
{{< /admonition >}}


---



In this article, I will cover how to setup an in-memory database with [H2](https://www.h2database.com/html/main.html) for testing on a Ktor project that uses a MySQL database in production.

This post is part of a series of posts dedicated to Ktor where I cover all the topics that made me struggle during development and that was not easy to achieve out of the box. You can check out the other instances of the series in the index above or [follow me on Twitter](https://twitter.com/marcoGomier) to keep up to date.


build.gradle.kts

```kotlin
plugins {
    application
    kotlin("jvm") version "1.4.30"
    id("org.jetbrains.kotlin.plugin.serialization") version "1.4.30"
    id("org.liquibase.gradle") version "2.0.4"
}
```

```kotlin
liquibaseRuntime("org.liquibase:liquibase-core:$liquibase_core")
liquibaseRuntime("mysql:mysql-connector-java:$mysql_connector_version")
liquibaseRuntime("ch.qos.logback:logback-core:1.2.3")
liquibaseRuntime("ch.qos.logback:logback-classic:1.2.3")
liquibaseRuntime("javax.xml.bind:jaxb-api:2.2.4")
```

```kotlin
// Database migrations
val dbEnv: String by project.ext

val propertiesFile = file("local.properties")
val properties = Properties()
if (propertiesFile.exists()) {
    properties.load(propertiesFile.inputStream())
}

// gw update -PdbEnv=dev
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

gradle.properties
```properties
dbEnv=
```

local.properties
```properties
liquibase.url=jdbc\:mysql\://your-url.com
liquibase.pwd=password
liquibase.user=user
```

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

## Conclusions

And that’s it for today. You can find the code mentioned in the article on [GitHub](https://github.com/prof18/ktor-chuck-norris-sample/tree/part3). 

In the next episode, I’ll cover database migrations. You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episodes.