---
layout: post
title:  "Using annotations to improve iOS APIs on Kotlin Multiplatform"
date:   2023-09-19
show_in_homepage: false
---

Kotlin 1.8 has introduced new annotations to improve the interoperability of Kotlin with Objective-C and Swift:

- `@ObjCName`: allows to customize the name that will be used in Swift or Objective-C
-  `@HiddenFromObjC`: allows hiding a Kotlin declaration from Objective-C (and Swift).
-  `@ShouldRefineInSwift`: it marks a Kotlin declaration as `swift_private` in the Objective-C API, allowing to replace it with a wrapper written in Swift.

You can see the [release announcement](https://kotlinlang.org/docs/whatsnew18.html#improved-objective-c-swift-interoperability) for more details about the interoperability improvements introduced with Kotlin 1.8.

In this article, I will cover how I used the `@HiddenFromObjC` and `@ObjCName` annotations to improve the architecture of [MoneyFlow](https://github.com/prof18/MoneyFlow), a pet project to manage personal finances that I started a couple of years ago and that became a personal playground for a Kotlin Multiplatform mobile app.

## MoneyFlow architecture

MoneyFlow uses an MVVM architecture with native ViewModels and a “shared middleware actor”, the UseCase, that prepares and serves the data for the UI. For every UseCase, there is an iOS-specific implementation placed in the `iOSMain` source set that receives in the constructor a reference of the shared UseCase and re-exposes the methods.

For example, the `HomeUseCase` will have an iOS-specific implementation called `HomeUseCaseIos`.

```kotlin
class HomeUseCase(
    private val moneyRepository: MoneyRepository,
    private val errorMapper: MoneyFlowErrorMapper,
) {
    fun observeHomeModel(): Flow<HomeModel> =
        moneyRepository.getMoneySummary().map {
            HomeModel.HomeState(
                balanceRecap = it.balanceRecap,
                latestTransactions = it.latestTransactions
            )
        }

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
    private val homeUseCase: HomeUseCase
) : BaseUseCaseIos() {

    fun getMoneySummary(): FlowWrapper<HomeModel> =
        FlowWrapper(scope, homeUseCase.observeHomeModel())

    fun deleteTransaction(transactionId: Long, onError: (UIErrorMessage) -> Unit) {
        scope.launch {
            val result = homeUseCase.deleteTransaction(transactionId)
            result.doOnError { onError(it) }
        }
    }
}
```

This approach introduces some code duplication, but I think that it’s a good compromise to bridge the gap between different platforms (to handle Flows and Coroutine cancellation). With this solution, the majority of the business logic is shared, and a “slim” ViewModel will be used to fulfill different needs of different platforms.

For more details about this architecture, you can look at the following articles that I wrote: 

> [Improving shared architecture for a Kotlin Multiplatform, Jetpack Compose and SwiftUI app](https://www.marcogomiero.com/posts/2022/improved-kmm-shared-app-arch/)


> [Choosing the right architecture for a [new] Kotlin Multiplatform, Jetpack Compose and SwiftUI app](https://www.marcogomiero.com/posts/2020/kmm-shared-app-architecture/)


An alternative approach would be using [KMP-NativeCoroutines](https://github.com/rickclephas/KMP-NativeCoroutines) or [SKIE](https://github.com/touchlab/SKIE), two libraries that improve Kotlin interoperability with iOS. But for this project, I started with this approach, and I will keep that to experience the difference. 

However, having two classes with very similar names (`HomeUseCase` and `HomeUseCaseIos`) can be misleading and will increase the binary size of the exported Objective-C framework.

## @HiddenFromObjC and @ObjCName usage

As mentioned above, the `HiddenFromObjC` annotation prevents certain Kotlin declarations from being exported to Objective-C and Swift. The `ObjCName` annotation instead can be used to change the name of the Kotlin declaration that will be exported to Objective-C and Swift.

Those two annotations can be combined to export to the iOS application only the iOS-specific implementation of the UseCase while keeping the same name.

```kotlin
@HiddenFromObjC
class HomeUseCase(
    private val moneyRepository: MoneyRepository,
    private val errorMapper: MoneyFlowErrorMapper,
) {
	...
}
```

```kotlin
@ObjCName("HomeUseCase")
class HomeUseCaseIos(
    private val homeUseCase: HomeUseCase,
) : BaseUseCaseIos() {
	...
}
```

This way, the iOS application will be completely transparent about the different implementations of the UseCase.

```swift
class HomeViewModel: ObservableObject {    
    private func homeUseCase() -> HomeUseCase {
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

And that’s all. The usage of those annotations is helping to create a cleaner API and export only the necessary components in the iOS framework, contributing to less complexity and reduced binary size.

You can find the code mentioned in the article on [GitHub](https://github.com/prof18/MoneyFlow).
