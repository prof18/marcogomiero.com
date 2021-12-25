---
layout: post
title:  "Generate API documentation from Swagger on Ktor"
date:   2021-08-08
show_in_homepage: true
draft: true
---

{{< admonition abstract "SERIES: Building a backend with Ktor" true >}}

- Part 1: [Structuring a Ktor project](https://www.marcogomiero.com/posts/2021/ktor-project-structure/)
- Part 2: [How to persist Ktor logs](https://www.marcogomiero.com/posts/2021/ktor-logging-on-disk/)
- Part 3: [How to use an in-memory database for testing on Ktor](https://www.marcogomiero.com/posts/2021/ktor-in-memory-db-testing/)
- Part 4: [How to handle database migrations with Liquibase on Ktor](https://www.marcogomiero.com/posts/2021/ktor-migration-liquibase/)
- Part 5: Generate API documentation from Swagger on Ktor
{{< /admonition >}}




--- 

In this article I will … 

This post is part of a series of posts dedicated to Ktor where I cover all the topics that made me struggle during development and that was not easy to achieve out of the box. You can check out the other instances of the series in the index above or [follow me on Twitter](https://twitter.com/marcoGomier) to keep up to date.

## Setup

Gradle plugin https://github.com/int128/gradle-swagger-generator-plugin

Generate ReDoc with an OpenAPI YAML.

https://int128.github.io/gradle-swagger-generator-plugin/examples/redoc/#

Redoc is an open-source tool for generating documentation from OpenAPI (fka Swagger) definitions.

https://github.com/Redocly/redoc


```bash
.
└── src
    ├── main
        └── resources
            ├── doc
            │   ├── index.html
            │   └── swagger.yml
            └── swagger
                └── swagger.yml
  
```

build.gradle.kts
```kotlin
plugins {
    application
    kotlin("jvm") version "1.4.30"
    id("org.jetbrains.kotlin.plugin.serialization") version "1.4.30"
    id("org.liquibase.gradle") version "2.0.4"
    id("org.hidetake.swagger.generator") version "2.18.2"
}
```

```kotlin
// Task for documentation
// ./gradlew generateReDoc
tasks.generateReDoc.configure {
    inputFile = file("$rootDir/src/main/resources/swagger/swagger.yml")
    outputDir = file("$rootDir/src/main/resources/doc")
    title = "Api Doc"
    options = mapOf(
        "spec-url" to "doc/swagger.yml"
    )
}

tasks.build {
    doLast {
        tasks.generateReDoc.get().exec()
    }
}
```

```kotlin
fun Application.module(testing: Boolean = false, koinModules: List<Module> = listOf(appModule)) {
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


```yaml
swagger: "2.0"
info:
  title: Ktor Chuck Norris Sample
  description: A ktor sample project that returns Random Chuck Norris jokes
  version: 0.0.1
tags:
  - name: Jokes
    description: Jokes Apis

paths:
  /joke/random:
    get:
      summary: Get a random Chuck Norris Joke
      responses:
        "200":
          description: "JokeDTO"
          schema:
            $ref: "#/definitions/JokeDTO"

definitions:
  JokeDTO:
    type: object
    properties:
      jokeId:
        type: string
      jokeContent:
        type: string
    required:
      - jokeId
      - jokeContent
```

{{< figure src="/img/ktor-series/api-doc.png"  link="/img/ktor-series/api-doc.png" >}}

## Conclusions

And that’s it for today. You can find the code mentioned in the article on [GitHub](https://github.com/prof18/ktor-chuck-norris-sample/tree/part5). 

In the next episode, I’ll cover how to show the API documentation from a Swagger specification. You can follow me on [Twitter](https://twitter.com/marcoGomier) to know when I’ll publish the next episodes.