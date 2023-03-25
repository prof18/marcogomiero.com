---
layout: post
title:  "How to create a parameterized base test class in Kotlin"
date:   2023-01-31
show_in_homepage: false
---

{{< rawhtml >}}

 <a href="https://androidweekly.net/issues/issue-556"><img style="margin: 0px;" src="https://androidweekly.net/issues/issue-556/badge" /></a>

<br>

{{< /rawhtml >}}

One exciting feature of JUnit 4 (and 5 as well, but this post will be focused on JUnit 4) is the possibility of running the same test with different input arguments.  

That is made possible by a [custom test runner](https://github.com/junit-team/junit4/wiki/parameterized-tests) called `Parameterized`, which will inject the provided arguments in the constructor of the test class. Instead, the different arguments must be defined in the companion object of the test class.

```kotlin
@RunWith(Parameterized::class)  
class KotlinVersionTest(val kotlinVersion: String) {  
  
    @Test  
    fun `Kotlin version is correct`() {  
        assertTrue(kotlinVersion.contains("1.7"))  
    }  
  
    companion object {  
        @JvmStatic  
        @Parameterized.Parameters(name = "with kotlinVersion {0}")  
        fun data() = listOf(  
            "1.7.0",  
            "1.7.10",  
            "1.7.20",  
            "1.7.21",  
        )  
    }  
}
```

However, in some situations, having a base test class helps set up a shared test environment.

```kotlin
open class BaseTest {  
  
    lateinit var kotlinFeatures: KotlinFeatures  
  
    @Before  
    open fun setup() {  
        kotlinFeatures = KotlinFeatures(kotlinVersion = "1.7.0")  
    }  
  
    @After  
    fun cleanUp() {  
       // Cleaning up stuff  
    }   
}
```

```kotlin
class KotlinVersionParameterizedTest {  
  
    @Test  
    fun `When the Kotlin version is 1_7_0, getNewFeatures returns the correct data`() {  
        val kotlinFeatures = KotlinFeatures(kotlinVersion = "1.7.0")  
  
        assertNotNull(kotlinFeatures)  
    }  
}
```

But what if `KotlinFeatures` needs to be tested with multiple `kotlinVersion`?

The `BaseTest` can be modified with a constructor that accepts an argument and a companion object that contains all the arguments required for the test. 

```kotlin
open class BaseTest(  
    private val kotlinVersion: String,  
) {  
  
    lateinit var kotlinFeatures: KotlinFeatures  
  
    @Before  
    open fun setup() {  
        kotlinFeatures = KotlinFeatures(kotlinVersion = kotlinVersion)  
    }  
  
    @After  
    fun cleanUp() {  
       // Cleaning up stuff  
    }  
  
    companion object {  
        @JvmStatic  
        @Parameterized.Parameters(name = "with kotlinVersion {0}")  
        fun data() = listOf(  
            "1.7.0",  
            "1.7.10",  
        )  
    }  
}
```

The test classes can now implement the `BaseTest` and run with the `Parameterized` test runner. It is only necessary to pass the argument to the Base Class's constructor.

```kotlin
@RunWith(Parameterized::class)  
class KotlinVersionParameterizedBaseTest(kotlinVersion: String): BaseTest(kotlinVersion) {  
  
    @Test  
    fun `getNewFeatures returns some data`() {  
        val newFeatures = kotlinFeatures.getNewFeatures()  
        assertNotNull(newFeatures)  
    }  
}
```

And that’s all! This way, running the same tests with different arguments and a shared configuration will be possible.

{{< figure src="/img/parameterized-base-test-kotiln/parameterized-test-result.png"  link="/img/parameterized-base-test-kotiln/parameterized-test-result.png" >}}
