---
layout: post
title:  "Ktor setup for documentation"
date:   2021-08-08
show_in_homepage: true
draft: true
---

This is a text


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