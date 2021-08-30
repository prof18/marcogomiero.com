---
layout: post
title:  "Ktor Cron"
date:   2021-08-09
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

https://github.com/quartz-scheduler/quartz

https://github.com/quartz-scheduler/quartz/blob/master/docs/index.adoc

```kotlin
// Quartz, for CRON
implementation("org.quartz-scheduler:quartz:2.3.2")
```

/Users/marco/Downloads/quartz-2.3.0-SNAPSHOT/src/org/quartz/impl/jdbcjobstore

```bash
.
├── jdbcjobstore
│   ├── AttributeRestoringConnectionInvocationHandler.java

    ...

    ├── tables_cloudscape.sql

    ...

    ├── tables_mysql.sql
    ├── tables_mysql_innodb.sql
    ├── tables_oracle.sql

    ...

```

```xml
<configuration>
    ...
    <logger name="org.quartz" level="INFO"/>
</configuration>

```


```kotlin
fun Application.module(testing: Boolean = false, koinModules: List<Module> = listOf(appModule)) {
      if (!testing) {
        val jobSchedulerManager by inject<JobSchedulerManager>()
        val jobFactory by inject<JobFactory>()
        jobSchedulerManager.startScheduler()
        jobSchedulerManager.scheduler.setJobFactory(jobFactory)
    }
}
```

```kotlin
val appModule = module {
    // Backend Config
    single<AppConfig>()
    singleBy<DatabaseFactory, DatabaseFactoryImpl>()
    singleBy<JokeLocalDataSource, JokeLocalDataSourceImpl>()
    singleBy<JokeRepository, JokeRepositoryImpl>()
    single<JobSchedulerManager>()
    single<JobFactory>()
}
```

```kotlin
class JobFactory(
    private val jokeRepository: JokeRepository
): JobFactory {

    override fun newJob(bundle: TriggerFiredBundle?, scheduler: Scheduler?): Job {
        if (bundle != null) {
            val jobClass = bundle.jobDetail.jobClass
            if (jobClass.name == RandomJokeJob::class.jvmName) {
                return RandomJokeJob(jokeRepository)
            }
        }
        throw NotImplementedError("Job Factory error")
    }
}
```

```kotlin
class JobSchedulerManager(appConfig: AppConfig) {

    var scheduler: Scheduler

    init {
        val databaseConfig = appConfig.databaseConfig

        val props = Properties()
        props["org.quartz.scheduler.instanceName"] = "ChuckNorrisScheduler"
        props["org.quartz.threadPool.threadCount"] = "3"

        props["org.quartz.jobStore.dataSource"] = "mySql"
        props["org.quartz.dataSource.mySql.driver"] = databaseConfig.driverClass
        props["org.quartz.dataSource.mySql.URL"] = databaseConfig.url
        props["org.quartz.dataSource.mySql.user"] = databaseConfig.user
        props["org.quartz.dataSource.mySql.password"] = databaseConfig.password
        props["org.quartz.dataSource.mySql.maxConnections"] = "10"
        props["org.quartz.dataSource.mySql.idleConnectionValidationSeconds"] = "50"
        props["org.quartz.dataSource.mySql.maxIdleTime"] = "60"

        props["org.quartz.jobStore.class"] = "org.quartz.impl.jdbcjobstore.JobStoreTX"
        props["org.quartz.jobStore.driverDelegateClass"] = "org.quartz.impl.jdbcjobstore.StdJDBCDelegate"
        props["org.quartz.jobStore.tablePrefix"] = "QRTZ_"


        props["org.quartz.plugin.triggHistory.class"] = "org.quartz.plugins.history.LoggingTriggerHistoryPlugin"
        props["org.quartz.plugin.triggHistory.triggerFiredMessage"] = """Trigger {1}.{0} fired job {6}.{5} at: {4, date, HH:mm:ss MM/dd/yyyy}"""
        props["org.quartz.plugin.triggHistory.triggerCompleteMessage"] = """Trigger {1}.{0} completed firing job {6}.{5} at {4, date, HH:mm:ss MM/dd/yyyy}"""

        val schedulerFactory: SchedulerFactory = StdSchedulerFactory(props)
        scheduler = schedulerFactory.scheduler
    }

    fun startScheduler() {
        scheduler.start()
    }
}
```

```kotlin
class RandomJokeJob(
    private val jokeRepository: JokeRepository
) : Job {

    override fun execute(context: JobExecutionContext?) {
        if (context == null) {
            return
        }

        val dataMap = context.jobDetail.jobDataMap

        val name: String? = try {
            dataMap.getString(JOB_MAP_NAME_ID_KEY)
        } catch (e: ClassCastException) {
            null
        }

        if (name != null) {
            val greetingMessage = jokeRepository.getChuckGreeting(name)

            println(greetingMessage)
        }
    }

    companion object {
        const val JOB_MAP_NAME_ID_KEY = "name"
        const val WATCH_JOB_GROUP = "WatchJob"

    }
}
```

```kotlin
override suspend fun watch(name: String) {
  // Schedule a cron every two days to renew the subscription
  val jobId = "chuck-watch-job-for-name-$name"
  val triggerId = "chuck-watch-trigger-for-name-$name"
  
  // If a job exists, delete it!
  val jobScheduler = jobSchedulerManager.scheduler
  val jobKey = JobKey.jobKey(jobId, RandomJokeJob.WATCH_JOB_GROUP)
  jobScheduler.deleteJob(jobKey)
  
  val job: JobDetail = JobBuilder.newJob(RandomJokeJob::class.java)
      .withIdentity(jobId, RandomJokeJob.WATCH_JOB_GROUP)
      .usingJobData(RandomJokeJob.JOB_MAP_NAME_ID_KEY, name)
      .build()
  
  val trigger: Trigger = TriggerBuilder.newTrigger()
      .withIdentity(triggerId, RandomJokeJob.WATCH_JOB_GROUP)
      .withSchedule(
          SimpleScheduleBuilder.simpleSchedule()
              // every minute
              .withIntervalInMinutes(1)
              .repeatForever()
      )
      .build()
  
  // Tell quartz to schedule the job using our trigger
  jobSchedulerManager.scheduler.scheduleJob(job, trigger)
}
```