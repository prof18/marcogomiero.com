---
layout: post
title:  "Ktor Project Structure"
date:   2021-03-09
show_in_homepage: true
draft: true
tags: [Ktor]
---

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