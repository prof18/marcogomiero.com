---
layout: post
title:  "How to save Ktor logs on disk"
date:   2021-03-08
show_in_homepage: false 
draft: true
tags: [Ktor]
---


// TODO: make another log to see multiple files

// TODO: add the getLogger method

// TODO: commit hconf file


```

{{< figure src="/img/ktor-log-disk/ktor-log-run-config.png"  link="/img/ktor-log-disk/ktor-log-run-config.png" >}}


// VM Options -DLOG_DEST=/Users/marco/Workspace/Examples/ktor-chuck-norris-sample/logs -DLOG_MAX_HISTORY=2
```

```kotlin
val appConfig by inject<AppConfig>()

    if (!appConfig.serverConfig.isProd) {
        val root = LoggerFactory.getLogger(org.slf4j.Logger.ROOT_LOGGER_NAME) as Logger
        root.level = ch.qos.logback.classic.Level.TRACE
    }

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

data class ServerConfig(
    val isProd: Boolean
)

```

logback.xml prod
```xml

<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{YYYY-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_DEST}/ktor-chuck-norris-sample.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!-- daily rollover -->
            <fileNamePattern>${LOG_DEST}/ktor-chuck-norris-sample.%d{yyyy-MM-dd}.log</fileNamePattern>

            <!-- keep 90 days' worth of history capped at 3GB total size -->
            <maxHistory>${LOG_MAX_HISTORY}</maxHistory>
            <totalSizeCap>3GB</totalSizeCap>

        </rollingPolicy>

        <encoder>
            <pattern>%d{YYYY-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>


    <root level="info">
        <appender-ref ref="STDOUT"/>
        <appender-ref ref="FILE"/>
    </root>
    <logger name="org.eclipse.jetty" level="INFO"/>
    <logger name="io.netty" level="INFO"/>
</configuration>
```

logback.xml text

```xml
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{YYYY-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <root level="info">
        <appender-ref ref="STDOUT"/>
    </root>
    <logger name="org.eclipse.jetty" level="INFO"/>
    <logger name="io.netty" level="INFO"/>
    <logger name="Exposed" level="INFO"/>
    <logger name="ktor.test" level="INFO"/>
</configuration>
```


TestServer.kt on testing

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
}
```


