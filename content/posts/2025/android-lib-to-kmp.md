---
layout: post
title:  "From an Android to a Kotlin Multiplatform library"
date:   2025-03-16
show_in_homepage: true 
draft: false
---

As Kotlin Multiplatform (KMP) continues to gain traction, more Android libraries are transitioning to support multiple platforms. However, this transition doesn’t always come for free; depending on the project, there could be different challenges. 

Recently, I migrated an existing Android library ([RSS-Parser](https://github.com/prof18/RSS-Parser), a library to parse RSS feeds). In this article, I will share my experience, cover all the challenges I faced during this journey, and describe the solutions I implemented to overcome them, from preserving git history to handling platform-specific dependencies and testing across different platforms.

##  Source Sets and git history

The code structure is the first difference between an Android and a multiplatform project. KMP [uses different source sets](https://kotlinlang.org/docs/multiplatform-discover-project.html#source-sets) to separate platform-specific code from shared code.

In a typical KMP project, you'll find, for example:

- `commonMain`: Contains code shared across all platforms
- `androidMain`: Android-specific implementations
- `iosMain`: iOS-specific implementations
- `jvmMain`: JVM (desktop) specific implementations

And so on for [every supported platform](https://kotlinlang.org/docs/multiplatform-dsl-reference.html#targets). Each platform has its corresponding test source set (e.g., `commonTest`, `androidTest`, etc.).

This structure allows the core logic to be written once in the common source set while providing platform-specific implementations where needed.

An Android library, instead, has everything inside a single source set, usually called `main`.

The first challenge is migrating to the multiplatform source sets without losing the git history and library contributors’ work. Simply creating a new project would mean losing all this valuable information. To avoid this, I tried different approaches and found the following one to be successful (successful for my use case; there might be different ways that I completely ignored).

1. Create a new library project using the [KMP Web Wizard](https://terrakok.github.io/kmp-web-wizard/) (so I don’t have to create the source sets manually)
2. Move the new source sets inside the existing library project
3. Duplicate and keep the old source set in the repo for reference
4. Move the existing code to the `androidMain` source set
5. Make the Android part work as before without sharing the code yet

This approach allowed me to maintain the entire git history while transitioning to the new structure. The original Android code served as a reference point during the migration process, making it easier to ensure that functionality remained consistent without looking at the previous commits every time.

## Handling Platform-Specific APIs

The original Android library relied heavily on platform-specific APIs that aren't available across all platforms, like OkHttp for retrieving the RSS feed (with the `CoroutineEngine.fetchXML` method) and `XmlPullParser` for parsing the feed (with the `CoroutineEngine.parseXML` method).

```kotlin
class Parser(
    private var callFactory: Call.Factory,
    private val charset: Charset? = null,
) {
    suspend fun getChannel(url: String): Channel = withContext(coroutineContext) {
        val charsetString = charset.toString()
        val xml = CoroutineEngine.fetchXML(url, callFactory)
        return@withContext CoroutineEngine.parseXML(xml, charset)
    }
}
```

When dealing with platform-specific code, there are two primary approaches:

1. **Interfaces**: Define a common interface in shared code and implement it for each platform
2. **Expect/Actual**: Declare expected classes/functions in common code and provide actual implementations for each platform. ([Expect/Actual documentation](https://kotlinlang.org/docs/multiplatform-expect-actual.html))

### Interfaces vs Expect/Actual

While the Expect/Actual mechanism is powerful, using interfaces provides more flexibility. For example, with interfaces, it will be possible to provide a fake implementation, fully delegate the implementation to the platform code (for example, when using a Swift library) or having multiple implementations for a single platform. 

In the case of RSS-Parser, I’ve created interfaces for fetching and parsing a feed.

```kotlin
internal interface XmlFetcher {
    suspend fun fetchXml(url: String): ParserInput
}

internal interface XmlParser {
    suspend fun parseXML(input: ParserInput): RssChannel
}
```

And the interfaces are implemented for each platform:

```kotlin
// JVM implementation
internal class JvmXmlFetcher(
    private val callFactory: Call.Factory,
): XmlFetcher {
    override suspend fun fetchXml(url: String): ParserInput {
        // Use OkHttp for fetching
    }
}

// iOS implementation
internal class IosXmlFetcher(
    private val nsUrlSession: NSURLSession,
): XmlFetcher {
    override suspend fun fetchXml(url: String): ParserInput =
        suspendCancellableCoroutine { continuation ->
            // Use NSURLSession for fetching
        }
}
```

However, for abstracting platform-specific types, like `InputStream` and `NSData`, the expect/actual mechanism is the way to go:

```kotlin
internal expect class ParserInput

// JVM/Android implementation
internal actual data class ParserInput(
    val inputStream: InputStream
) 

// iOS implementation
internal actual data class ParserInput(
    val data: NSData
) 
```

## Creating Platform-Specific Constructors

I wanted to provide different types of constructors to make the library easy to use across platforms. In particular, the users of the library must be able to:

- Create an instance of the library by customizing the platform-specific dependencies (OkHttp, NSURLSession); 
- Create an instance with default values;
- Create an instance in a KMP, Android, or JVM project.

To achieve that, I’ve created a `Builder` (I know, it’s more of a `Factory` than a `Builder`, but I figured it out too late, and that would mean doing breaking changes) in the library's main class, which is located in the `common` source set.

```kotlin
class RssParser internal constructor(
    private val xmlFetcher: XmlFetcher,
    private val xmlParser: XmlParser,
) {
    internal interface Builder {
        fun build(): RssParser
    }
}
```

For each platform, I created a specific builder:

```kotlin
// Android builder
class RssParserBuilder(
    private val callFactory: Call.Factory = OkHttpClient(),
    private val charset: Charset? = null,
): RssParser.Builder {
    override fun build(): RssParser {
        return RssParser(
            xmlFetcher = JvmXmlFetcher(
                callFactory = callFactory,
            ),
            xmlParser = AndroidXmlParser(
                charset = charset,
                dispatcher = Dispatchers.IO,
            ),
        )
    }
}


// JVM builder
class RssParserBuilder(
    private val callFactory: Call.Factory = OkHttpClient(),
    private val charset: Charset? = null,
): RssParser.Builder {
    override fun build(): RssParser {
        return RssParser(
            xmlFetcher = JvmXmlFetcher(
                callFactory = callFactory,
            ),
            xmlParser = JvmXmlParser(
                charset = charset,
                dispatcher = Dispatchers.IO,
            ),
        )
    }
}

// iOS builder
class RssParserBuilder(
    private val nsUrlSession: NSURLSession = NSURLSession.sharedSession,
): RssParser.Builder {
    override fun build(): RssParser {
        return RssParser(
            xmlFetcher = IosXmlFetcher(
                nsUrlSession = nsUrlSession,
            ),
            xmlParser = IosXmlParser(
                dispatcher = Dispatchers.IO
            ),
        )
    }
}
```

To create instances with default values, the `expect/actual` mechanism can be leveraged by defining a function in the common source set:

```kotlin
expect fun RssParser(): RssParser
```

Then, for every platform, the actual implementation will just call the `Builder` with default values:

```kotlin
actual fun RssParser(): RssParser = RssParserBuilder().build()
```

Defining this function with a capital letter creates a syntax that feels like a constructor call to library users. This approach allows developers on each platform to use the library in an idiomatic way, with the option to customize platform-specific dependencies when needed.

{{< figure src="/img/android-lib-to-kmp/constructor.png"  link="/img/android-lib-to-kmp/constructor.png" >}}



## Testing on multiple platforms

While the library has different platform-specific implementations, my goal was to have a single set of tests that can be run on all the platforms that the library supports. 

However, this goal presents some challenges when it comes to creating platform-specific test instances and accessing test resources (e.g. different XML files that I want to test against my library)

### Platform-Specific Test Instances

The `expect/actual` mechanism comes to the rescue when creating platform-specific instances for testing. 

In the `commonTest` source set, an expect `Factory` can be defined

```kotlin
internal expect object XmlParserFactory {
    fun createXmlParser(): XmlParser
}
```

And it can be implemented in every platform testing source set:

```kotlin

// JVM implementation
internal actual object XmlParserFactory {
    actual fun createXmlParser(): XmlParser = JvmXmlParser(dispatcher = UnconfinedTestDispatcher())
}

// Android implementation 
internal actual object XmlParserFactory {
    actual fun createXmlParser(): XmlParser = AndroidXmlParser(dispatcher = UnconfinedTestDispatcher())
}

// iOS implementation
internal actual object XmlParserFactory {
    actual fun createXmlParser(): XmlParser = IosXmlParser(dispatcher = UnconfinedTestDispatcher())
}
```

This setup allows to write a single test that can be run on different platforms

```kotlin
class XmlParserTest {
    @Test
    fun channelTitle_isCorrect() = runTest {
        val parser = XmlParserFactory.createXmlParser()
        val input = readFileFromResources("test-feed.xml")
        val channel = parser.parseXML(input)
        assertEquals("channel-title", channel.title)
    }
}
```


{{< figure src="/img/android-lib-to-kmp/test.png"  link="/img/android-lib-to-kmp/test.png" >}}


### Accessing Test Resources

Accessing test resources across platforms is complicated because there is no `java.io.File` on Kotlin/Native and on iOS, the working directory is unrelated to the project directory. 

To solve this, environmental variables can be leveraged to get the path where the test resources are placed.

```kotlin
// In build.gradle.kts
val rootDir = "${rootProject.rootDir.path}/rssparser/src/commonTest/resources"

tasks.withType<Test>().configureEach {
    environment("TEST_RESOURCES_ROOT", rootDir)
}

tasks.withType<KotlinNativeTest>().configureEach {
    environment("TEST_RESOURCES_ROOT", rootDir)
    // This is necessary to have the variable propagated on iOS
    environment("SIMCTL_CHILD_TEST_RESOURCES_ROOT", rootDir)
}
```

Test resources can now be retrieved by creating a platform-specific helper

```kotlin
internal expect fun readFileFromResources(
    resourceName: String
): ParserInput

// JVM implementation
internal actual fun readFileFromResources(
    resourceName: String,
): ParserInput {
    val path = System.getenv("TEST_RESOURCES_ROOT")
    val file = File("$path/$resourceName")
    return ParserInput(
        inputStream = FileInputStream(file)
    )
}

// iOS implementation
internal actual fun readFileFromResources(
    resourceName: String
): ParserInput {
    val s = getenv("TEST_RESOURCES_ROOT")?.toKString()
    val path = "$s/${resourceName}"
    val data = NSData.dataWithContentsOfFile(path)
    return ParserInput(requireNotNull(data))
}
```

## Publishing the library

Publishing a Kotlin Multiplatform library on Maven is relatively straightforward (assuming you already have a Maven publication) using the [Gradle Maven Publish Plugin](https://github.com/vanniktech/gradle-maven-publish-plugin). The same setup for Android worked for the KMP library without any changes.

## Conclusions

Migrating an Android library to Kotlin Multiplatform is rewarding, but it comes with some challenges. Here’s the takeaways after migrating RSS-Parser to Kotlin Multiplatform.

**Adapting to different platforms requires time and thought**: each platform has its quirks and best practices, and understanding these differences leads to a better API design.

**Code organization can be challenging**: maintaining the git history while restructuring the codebase requires careful planning. 

**Prefer interfaces over expect/actual where possible**: while expect/actual is a powerful feature, interfaces often provide more flexibility and maintainability.

**Testing across platforms requires extra consideration**: ensuring tests run on all platforms involves handling platform-specific test dependencies and resource access. Environment variables and factory patterns can help address these challenges.

**Start small and expand gradually**: begin by supporting a limited set of platforms and then expand as you become more comfortable with the multiplatform approach.
