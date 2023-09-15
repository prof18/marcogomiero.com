---
layout: post
title:  "Using annotations to improve iOS code on Kotlin Multiplatform"
date:   2023-06-01
show_in_homepage: false
draft: true
---

Intro about the addition of this things on Kotlin 1.8

https://kotlinlang.org/docs/whatsnew18.html#improved-objective-c-swift-interoperability

## Intro about the architecture of MoneyFlow

https://www.marcogomiero.com/posts/2022/improved-kmm-shared-app-arch/

In MoneyFlow I’ve decided to create two UseCase: one in the common code and one only specific to iOS. This class is placed in the `iOSMain` sourceSet. This class receives in the constructor a reference of the shared UseCase and re-exposes the methods to be able to transform a `Flow` and handle coroutine scoping.

Even though there is an amount of code duplication, I think that it’s a good compromise. Some duplication is necessary to bridge the gap between different platforms and with this solution, the majority of the business logic is shared and a “slim” ViewModel will be used to fulfill different needs of different platforms.

Another approach can be using [KMP-NativeCoroutines](https://github.com/rickclephas/KMP-NativeCoroutines), a library that will make it easier to use Kotlin Coroutines from Swift code in KMP apps. But for this project I started with this approach and I will keep that to experience the difference. 

## Using @ObjCName and @HiddenFromObjC to improve the consumption on iOS


the annotations @ObjCName and @HiddenFromObjC can be used to improve 


https://kotlinlang.org/docs/native-objc-interop.html



Hiding Kotlin Declarations from Objective-C with @HiddenFromObjC

The Potential of @ShouldRefineInSwift for Wrapping Kotlin Declarations in Swift

Explain why it was not used in this specific case, but mention its usefulness in other scenarios


To ensure a seamless experience when integrating Kotlin Multiplatform code with native iOS projects, we must pay close attention to the interoperability between Kotlin and Objective-C/Swift. Kotlin provides three annotations to help with this:
@ObjCName: Customizes the name of a Kotlin declaration for Swift or Objective-C
@HiddenFromObjC: Hides a Kotlin declaration from Objective-C (and Swift)
@ShouldRefineInSwift: Marks a Kotlin declaration as swift_private in Objective-C API, allowing for further customization in Swift


Our goal in MoneyFlow is to export only the necessary UseCases to iOS while maintaining a clean and idiomatic API. The inspiration for this approach came from a tweet discussing the idea of applying HiddenFromObjC to an entire class:

I started playing with the HiddenFromObjC and ObjCName annotations on MoneyFlow to export to iOS only the UseCase that will be used on iOS. 
It would be amazing tho, if HiddenFromObjC could be applied to an entire class 🤔
To get started, we opted into the experimental features in the build.gradle.kts file:


The @HiddenFromObjC annotation allows us to prevent certain Kotlin declarations from being exported to Objective-C and Swift. This helps us create a cleaner API and expose only the necessary components to iOS. We applied the @HiddenFromObjC annotation in the AddTransactionUseCase and AllTransactionsUseCase classes:

```kotlin
all {
    languageSettings.apply {
        optIn("kotlin.experimental.ExperimentalObjCRefinement")
        optIn("kotlin.experimental.ExperimentalObjCName")
    }
}
```

```kotlin
@ObjCName("_HomeUseCase")
class HomeUseCase(
    private val moneyRepository: MoneyRepository,
    private val settingsRepository: SettingsRepository,
    private val errorMapper: MoneyFlowErrorMapper,
) {

    @HiddenFromObjC
    val hideSensibleDataState: StateFlow<Boolean> = settingsRepository.hideSensibleDataState

    @HiddenFromObjC
    fun observeHomeModel(): Flow<HomeModel> =
        moneyRepository.getMoneySummary().map {
            HomeModel.HomeState(
                balanceRecap = it.balanceRecap,
                latestTransactions = it.latestTransactions,
            )
        }

    @HiddenFromObjC
    fun toggleHideSensitiveData(status: Boolean) {
        settingsRepository.setHideSensitiveData(status)
    }

    @HiddenFromObjC
    suspend fun deleteTransaction(transactionId: Long): MoneyFlowResult<Unit> {
        return try {
            moneyRepository.deleteTransaction(transactionId)
            MoneyFlowResult.Success(Unit)
        } catch (throwable: Throwable) {
            val error = MoneyFlowError.DeleteTransaction(throwable)
            throwable.logError(error)
            val errorMessage = errorMapper.getUIErrorMessage(error)
            MoneyFlowResult.Error(errorMessage)
        }
    }
}

```


```kotlin
class HomeUseCaseIos(
    private val homeUseCase: HomeUseCase,
) : BaseUseCaseIos() {

    val hideSensibleDataState: FlowWrapper<Boolean> =
        FlowWrapper(scope, homeUseCase.hideSensibleDataState)

    fun getMoneySummary(): FlowWrapper<HomeModel> =
        FlowWrapper(scope, homeUseCase.observeHomeModel())

    fun deleteTransaction(transactionId: Long, onError: (UIErrorMessage) -> Unit) {
        scope.launch {
            val result = homeUseCase.deleteTransaction(transactionId)
            result.doOnError { onError(it) }
        }
    }

    fun toggleHideSensitiveData(status: Boolean) {
        homeUseCase.toggleHideSensitiveData(status)
    }
}
```

```swift
class HomeViewModel: ObservableObject {    
    private func homeUseCase() -> HomeUseCaseIos {
        DI.getHomeUseCase()
    }

    func deleteTransaction(transactionId: Int64) {
        homeUseCase().deleteTransaction(
            transactionId: transactionId,
            onError: { error in
                self.snackbarData = error.toSnackbarData()
            }
        )
    }
}
```
