---
layout: post
title:  "Using Retrofit and Alamofire with Kotlin Serialization"
date:   2020-11-29
show_in_homepage: true
draft: true
tags: [Kotlin Multiplatform]
---

If you are starting a project with Kotlin Multiplatform and you want to share the network layer, the best way to go is definitely with [Ktor](https://kotlinlang.org/docs/mobile/use-ktor-for-networking.html). But if you don’t want to share the entire network layer but maybe only the DTOs? 
There could be many reasons for wanting this. Maybe you are starting to integrate Kotlin Multiplatform (I’ll call it KMP in the rest of the article) into an existing project and the work for sharing the entire network layer is simply too much. 

And this was the case for the project that I’m working on. We decided to start integrating KMP and we thought that the perfect target to start with is the DTOs. Because in this way we can define a single source of truth and share it on the backend and the mobile clients. But how to start using KMP in an existing project, is a topic for another article, so stay tuned!

In this article, I will show you how to implement a Kotlin Multiplatform Mobile application that performs a network call on the native side with Retrofit (on Android) and Alamofire (on iOs) but the DTOs are defined on KMP side as well as the information about deserialization. And for the deserialization, I will use (of course) the [Kotlin Serialization library](https://github.com/Kotlin/kotlinx.serialization). 

## API 

For this example I will use the [Bored Api](https://www.boredapi.com/) that returns this kind of response:

```json
{
  "activity": "Learn the NATO phonetic alphabet",
  "type": "education",
  "participants": 1,
  "price": 0,
  "link": "https://en.wikipedia.org/wiki/NATO_phonetic_alphabet",
  "key": "6706598",
  "accessibility": 0
}
```

And this response can be mapped to a simple data class:

```kotlin
@Serializable
data class Activity(
    val activity: String,
    val type: String,
    val participants: Int,
    val price: Double,
    val link: String,
    val key: String,
    val accessibility: Double
)
```

And this data class is placed inside the shared KMP module. 

## Android

Now, let’s move to the Android side and I start with Android because things are simpler. In fact, you can use [Retrofit](https://github.com/square/retrofit) and the [Kotlin Serialization Converter](https://github.com/JakeWharton/retrofit2-kotlinx-serialization-converter). All you need to do is add the `Converter Factory` for the Kotlin Serialization.


```kotlin
Retrofit.Builder()
    .baseUrl("https://www.boredapi.com/api/")
    .addConverterFactory(Json.asConverterFactory(MediaType.get("application/json")))
    .build()
    .create(ActivityApiService::class.java)
```

## iOs 

On iOs the equivalent to Retrofit is [Alamofire](https://github.com/Alamofire/Alamofire). Alamofire let you easily handle the deserialization of the responses (and of course also the serialization of the requests) with the `Decodable` protocol (and `Encodable` - or `Codable` to support both `Encodable` and `Decodable` at the same time). For more information about `Codable`, I suggest you to look at the [official documentation](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types). 
But unfortunately there is [no Codable support on Kotlin/Native](https://github.com/JetBrains/kotlin-native/issues/2978) (maybe it will come with direct interoperability with Swift - [Kotlin Roadmap](https://kotlinlang.org/roadmap.html)).

### Custom Response Deserialization with Alamofire

Fortunately, Alamofire gives the possibility to write [a custom response serializer](https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md#creating-a-custom-response-serializer). The starting point is a `struct` that extends `ResponseSerializer`; this `struct` overrides the `serialize` method, which “does some magics” and returns the desired deserialized object, represented by the generic `T`.

```swift
struct CustomSerializer<T>: ResponseSerializer {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        // TODO
    }
}
```

Before performing the object deserialization, a string representation of the response must be computed. To do that, I will use the `StringResponseSerializer` provided by Alamofire.

```swift
let jsonString = try StringResponseSerializer().serialize(request: request, response: response, data: data, error: error)
```

And then, this string will be sent to a Kotlin helper function that performs the actual deserialization. 

```kotlin
val deserializedObject = JsonDecoder().decodeFromString(jsonString: “{}”)
```

And at the end, the custom Alamofire deserializer will look something like this (with also a bit of error handling):


```swift
import Alamofire
import shared

struct CustomSerializer<T>: ResponseSerializer {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        
        guard error == nil else { throw error! }
        
        guard let data = data, !data.isEmpty else {
            guard emptyResponseAllowed(forRequest: request, response: response) else {
                throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            
            guard let emptyResponseType = T.self as? EmptyResponse.Type, let emptyValue = emptyResponseType.emptyValue() as? T else {
                throw AFError.responseSerializationFailed(reason: .invalidEmptyResponse(type: "\(T.self)"))
            }
            return emptyValue
        }
        
        do {
            let jsonString = try StringResponseSerializer().serialize(request: request, response: response, data: data, error: error)
            val deserializedObject = JsonDecoder().decodeFromString(jsonString: “{}”)
            return deserializedObject
            
        } catch {
            throw AFError.responseSerializationFailed(reason: .decodingFailed(error: error))
        }
    }
}
```

And then, the ViewModel can make the network request using the custom serializer.


```swift
AF.request("https://www.boredapi.com/api/activity")
    .response(responseSerializer: CustomSerializer<Activity>()) { response in
    if let activity = response.value {
        DispatchQueue.main.async {
            self.showLoading = false
            self.activityName = activity.activity
        }
    }
}
```


### Deserialization on Kotlin/Native

Now let’s move back to KMP, and let’s implement the `decodeFromString` function mentioned above.

The first thing that popped into my mind is to use an `inline reified` function that works with generics (for more info about inline functions and reified parameters, give a look to the [Kotlin documentation](https://kotlinlang.org/docs/reference/inline-functions.html)).

```kotlin
object JsonDecoder {
    @Throws(Exception::class)
    inline fun <reified T> decodeFromString(jsonString: String): T {
        return Json.decodeFromString(jsonString)
    }
}
```

But unfortunately, this approach does not work because Swift doesn’t have `inline` functions support.

```
{
    KotlinException = "kotlin.IllegalStateException: unsupported call of reified inlined function `com.prof18.sharedserialization.shared.JsonDecoder.decodeFromString`";
    KotlinExceptionOrigin = "";
    NSLocalizedDescription = "unsupported call of reified inlined function  com.prof18.sharedserialization.shared.JsonDecoder.decodeFromString`";
}
```

So, after a bit of exploring of the Kotlin Serialization documentation and sources, I’ve discovered that there is the possibility to get the serializer of a `KClass` (`KClass<T>.serializer()`) and then pass it to the `decodeFromString` function.

```kotlin
object JsonDecoder {
    @InternalSerializationApi
    fun decodeFromString(jsonString: String, objCClass: ObjCClass): Any {
        val kClazz = getOriginalKotlinClass(objCClass)!!
        val serializer = kClazz.serializer()
        return Json.decodeFromString(serializer, jsonString)
    }
}
```

This approach works! But unfortunately, the `KClass<T>.serializer()` is an internal API. And (as stated [in the documentation](https://github.com/Kotlin/kotlinx.serialization/blob/d24399eb388b0f45b7d55902d4563ded404dcf83/core/commonMain/src/kotlinx/serialization/Serializers.kt#L130)) it doesn't work with generic classes, lists, custom serializers, etc (I’ve opened an [issue on GitHub](https://github.com/Kotlin/kotlinx.serialization/issues/1210) just to be sure).

So, given the limitations of using an internal API, I’ve decided to change (again!) approach. Since it is hard to create generic deserialization, it is better to specify the deserialization information for every DTO. To do that, I have defined an abstract class with an abstract deserialize method that every DTOs has to implement.

```kotlin
abstract class BaseResponseDTO {
    @Throws(Exception::class)
    abstract fun deserialize(jsonString: String): BaseResponseDTO   
}
```

So, the `Activity` class defined above need to override the `deserialize` method. 


```kotlin
@Serializable
data class Activity(
  ...
) : BaseResponseDTO() {

    override fun deserialize(jsonString: String): Activity {
        val activity: Activity = Json.decodeFromString(jsonString)
        activity.freeze()        
        return activity
    }
}
```

Now, some modifications must be made to the custom Alamofire deserializer. First of all, the accepted generic type is not `T` only, but `T` that inherits from `BaseResponseDTO`

```swift
struct CustomSerializer<T: BaseResponseDTO>: ResponseSerializer {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        ...    
    }
}
```

In this way, we can retrieve the serializer from the abstract class, deserialize the object and return it.

```swift
let deserializedObject = try T().deserialize(jsonString: jsonString) as! T
```

And finally, this works! 

Here’s the full code of the updated serializer. 

```swift
import Alamofire
import shared

struct CustomSerializer<T: BaseResponseDTO>: ResponseSerializer {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        
        guard error == nil else { throw error! }
        
        guard let data = data, !data.isEmpty else {
            guard emptyResponseAllowed(forRequest: request, response: response) else {
                throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            
            guard let emptyResponseType = T.self as? EmptyResponse.Type, let emptyValue = emptyResponseType.emptyValue() as? T else {
                throw AFError.responseSerializationFailed(reason: .invalidEmptyResponse(type: "\(T.self)"))
            }
            return emptyValue
        }
        
        do {
            let jsonString = try StringResponseSerializer().serialize(request: request, response: response, data: data, error: error)
            let deserializedObject = try T().deserialize(jsonString: jsonString) as! T
            deserializedObject.makeFrozen()
            return deserializedObject
        } catch {
            throw AFError.responseSerializationFailed(reason: .decodingFailed(error: error))
        }
    }
}
```

If you want to see all in action, I’ve published a little sample [on my GitHub](https://github.com/prof18/shared-deserialization). 


In the end, the result is a bit more boilerplate than what I’ve expected but not so much. I think that the benefits of having the DTOs defined in one place for both the clients and the backend are way higher than the “burden” of writing a bunch of lines of code for every DTOs. 

If you have any suggestion to improve that solution or you have any kind of doubt, feel free to drop a comment below or tweet me [@marcoGomier](https://twitter.com/marcoGomier)






