---
layout: post
title:  "Improving shared architecture for a Kotlin Multiplatform, Jetpack Compose and SwiftUI app"
date:   2022-06-26
show_in_homepage: true
image: "/img/impr-kmm-arch/money-flow-dark.png"
---

{{< rawhtml >}}

<div id="banner" style="overflow: hidden;justify-content:space-around;">

    <div style="display: inline-block;margin-right: 10px;">
        <a href="https://androidweekly.net/issues/issue-525"><img style="margin: 0px;" src="https://androidweekly.net/issues/issue-525/badge" /></a>
    </div>

    <div style="display: inline-block;">
        <a href="https://us12.campaign-archive.com/?u=f39692e245b94f7fb693b6d82&id=68710ad80a"><img style="margin: 0px;" src="https://img.shields.io/badge/Featured%20in%20kotlinweekly.net-Issue%20%23309-%237874b4"/></a>
    </div>

    <div style="display: inline-block;">
        <a href="https://jetc.dev/issues/123.html"><img style="margin: 0px;" src="https://img.shields.io/badge/Featured%20in%20jetc.dev-Issue%20%23123-343a40"/></a>
    </div>


    
</div>

{{< /rawhtml >}}

A couple of years ago I started working on a pet project to manage personal finances, named [MoneyFlow](https://github.com/prof18/MoneyFlow).

{{< figure src="/img/impr-kmm-arch/money-flow-dark.png"  link="/img/impr-kmm-arch/money-flow-dark.png" >}}

This project soon became a personal playground for a Kotlin Multiplatform mobile app and in a previous article, I journaled all the steps that lead me to a satisfying (at least for that time) shared app architecture.

> [Choosing the right architecture for a [new] Kotlin Multiplatform, Jetpack Compose and SwiftUI app](https://www.marcogomiero.com/posts/2020/kmm-shared-app-architecture/)

To know more about the complete journey, please refer to the article mentioned above, but the outcome was a **MVVM** architecture with native ViewModels and a “shared middleware actor”, the UseCase, that prepares and serves the data for the UI.

**Shared UseCase**:

```kotlin
class HomeUseCaseImpl(
    private val moneyRepository: MoneyRepository,
    // That's only for iOS
    private val viewUpdate: ((HomeModel) -> Unit)? = null,
): HomeUseCase {

    // Used only on iOS
    private val coroutineScope: CoroutineScope = MainScope()

    private val homeModel = MutableStateFlow<HomeModel>(HomeModel.Loading)

    override fun observeHomeModel(): StateFlow<HomeModel> = homeModel

    override fun computeData() {
        coroutineScope.launch {
            computeHomeDataSuspendable()
        }
    }

    override suspend fun computeHomeDataSuspendable() {
        val latestTransactionFlow = moneyRepository.getLatestTransactions()
        val balanceRecapFlow = moneyRepository.getBalanceRecap()

        latestTransactionFlow.combine(balanceRecapFlow) { transactions: List<Transaction>, balanceRecap: BalanceRecap ->
            HomeModel.HomeState(
                balanceRecap = balanceRecap,
                latestTransactions = transactions
            )
        }.catch { cause: Throwable ->
            val error = HomeModel.Error("Something wrong")
            homeModel.value = error
            viewUpdate?.invoke(error)
        }.collect {
            homeModel.value = it
            viewUpdate?.invoke(it)
        }
    }

    // iOS   only
    fun onDestroy() {
        coroutineScope.cancel()
    }
}
```

**Android ViewModel:**

```kotlin
class HomeViewModel(
   private val useCase: HomeUseCase
) : ViewModel() {

    private val _homeLiveData = MutableLiveData<HomeModel>()
    val homeLiveData: LiveData<HomeModel>
        get() = _homeLiveData

    init {
        observeHomeModel()
        viewModelScope.launch {
            useCase.computeHomeDataSuspendable()
        }
    }

    private fun observeHomeModel() {
        viewModelScope.launch {
            useCase.observeHomeModel().collect {
                _homeLiveData.postValue(it)
            }
        }
    }
}
```

**iOS ViewModel**:

```swift
import shared

class HomeViewModel: ObservableObject {
    
    @Published var homeModel: HomeModel = HomeModel.Loading()
    
    lazy var useCase = HomeUseCaseImpl(moneyRepository: MoneyRepositoryFake(), viewUpdate: { [weak self] model in
        self?.homeModel = model
    })
    
    func startObserving() {
        self.useCase.computeData()
    }
    
    func stopObserving() {
        self.useCase.onDestroy()
    }
}
```


I’m still convinced that this approach is a good compromise for sharing code as much as possible. In this way, all data handling and preparation will live in a shared UseCase. The ViewModels then can be native and use all the native tools provided by the platform, for example, the *Android Jetpack ViewModel* and *Combine/SwiftUI* utilities.

However, this solution can be improved. 
First, there are duplicated methods to provide a suspendable and a no-suspendable version of a function. The fact that there are duplicated versions of the same function in the same class is something that can lead to confusion on the consumer side. 

Secondly, the model returned by those functions is exposed in different ways: with a (State)Flow that will be used from Android and with a nullable callback injected in the constructor. This callback will be NOT *null* only on iOS and it will be invoked when the Flow coming from the repository is collected. Having a nullable field in the constructor based on the platform is another thing that I don’t like.

One of the reasons to have duplicated functions was the impossibility to use and collect a Flow on Swift. But with some glue code, this is not impossible. 

## Consuming Kotlin Flow on Swift

With some wrapping code, it is possible to consume Kotlin Flow on Swift. 

To consume Kotlin Flow on Swift, I took inspiration from [Russell Wolf](https://mobile.twitter.com/RussHWolf)‘s article: [Kotlin Coroutines and Swift, revisited](https://dev.to/touchlab/kotlin-coroutines-and-swift-revisited-j5h)

This strategy requires some Kotlin and Swift wrapping code. The Kotlin code will live in the `iOSMain` sourceSets and the Swift code will live in the iOS app. In the end, the Flow will be transformed into a [`Combine Publisher`](https://developer.apple.com/documentation/combine/publisher) that can be observed from iOS ViewModels.

**Kotlin Wrapper Code**:

```kotlin
class FlowWrapper<T : Any>(
    private val scope: CoroutineScope,
    private val flow: Flow<T>
) {

    fun subscribe(
        onEvent: (T) -> Unit,
        onError: (Throwable) -> Unit,
        onComplete: () -> Unit
    ): Job =
        flow
            .onEach { onEvent(it.freeze()) }
            .catch { onError(it.freeze()) }
            .onCompletion { onComplete() }
            .launchIn(scope)
}
```

**iOS Wrapper Code**:

```swift
import Combine
import shared

func createPublisher<T>(_ flowAdapter: FlowWrapper<T>) -> AnyPublisher<T, KotlinError> {
    let subject = PassthroughSubject<T, KotlinError>()
    let job = flowAdapter.subscribe { (item) in
        subject.send(item)
    } onError: { (error) in
       subject.send(completion: .failure(KotlinError(error)))
    } onComplete: {
        subject.send(completion: .finished)
    }
    return subject.handleEvents(receiveCancel: {
        job.cancel(cause: nil)
    }).eraseToAnyPublisher()
}

class PublishedFlow<T> : ObservableObject {
    @Published
    var output: T

    init<E>(_ publisher: AnyPublisher<T, E>, defaultValue: T) {
        output = defaultValue

        publisher
            .replaceError(with: defaultValue)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$output)
    }
}

class KotlinError: LocalizedError {
    let throwable: KotlinThrowable
    init(_ throwable: KotlinThrowable) {
        self.throwable = throwable
    }
    var errorDescription: String? {
        get { throwable.message }
    }
}
```

## Improved UseCase

The improved UseCase will have only a single method that returns a Flow. In the example below, I’ve also added a suspendable method, `deleteTransaction` to showcase how to handle methods that perform an action and return a result.

```kotlin
class HomeUseCase(
    private val moneyRepository: MoneyRepository,
    private val settingsRepository: SettingsRepository,
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

To transform a `Flow` and handle coroutine cancellation, I’ve decided to create another UseCase but only specific to iOS. This class is placed in the `iOSMain` sourceSet. This class receives in the constructor a reference of the shared UseCase and re-exposes the methods to be able to transform a `Flow` and handle coroutine scoping.

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

Coroutine scoping is handled in a `BaseUseCaseIos` class, that creates a scope and exposes a function to cancel the scope. 

```kotlin
abstract class BaseUseCaseIos {

    private val dispatcher: CoroutineDispatcher = Dispatchers.Default
    internal val scope = CoroutineScope(SupervisorJob() + dispatcher)

    fun onDestroy() {
        scope.cancel()
    }
}
```

The `Flow` can be “transformed” by creating a new `FlowWrapper` class with the `Flow` instance and the coroutine scope.

```kotlin
 fun getMoneySummary(): FlowWrapper<HomeModel> =
        FlowWrapper(scope, homeUseCase.observeHomeModel())
```

The “perform action and return a result” method instead, launches a coroutine in the scope and returns the result in a callback provided as a parameter.

```kotlin 
 fun deleteTransaction(transactionId: Long, onError: (UIErrorMessage) -> Unit) {
        scope.launch {
            val result = homeUseCase.deleteTransaction(transactionId)
            result.doOnError { onError(it) }
        }
    }
```

In this specific case, I’ve put only an `onError` callback because the UI will react only in case of an error.

## Android ViewModel

The Android ViewModel will regularly use the UseCase with the `viewModelScope` coroutine scope provided by the Jetpack ViewModel like in a regular Android project.

```kotlin
internal class HomeViewModel(
    private var useCase: HomeUseCase,
    private val errorMapper: MoneyFlowErrorMapper,
) : ViewModel() {

    var homeModel: HomeModel by mutableStateOf(HomeModel.Loading)
        private set

    init {
        observeHomeModel()
    }

    private fun observeHomeModel() {
        viewModelScope.launch {
            useCase.observeHomeModel()
                .catch { throwable: Throwable ->
                    val error = MoneyFlowError.GetCategories(throwable)
                    throwable.logError(error)
                    val errorMessage = errorMapper.getUIErrorMessage(error)
                    emit(HomeModel.Error(errorMessage))
                }
                .collect {
                    homeModel = it
                }
        }
    }
}
```

## iOS ViewModel

On iOS instead, the ViewModel is an [`ObservableObject`](https://developer.apple.com/documentation/combine/observableobject). 

```swift
class HomeViewModel: ObservableObject {
	...
}
```

To make SwiftUI react to state changes, it is necessary to create a [`@Published`](https://developer.apple.com/documentation/combine/published) variable that will receive the data from the `FlowWrapper` exposed from the UseCase.

```swift
class HomeViewModel: ObservableObject {

	@Published var homeModel: HomeModel = HomeModel.Loading()
   
}    
```

The `FlowWrapper` now, needs to be transformed to a [`Publisher`](https://developer.apple.com/documentation/combine/publisher), like explained [in the section above](#consuming-kotlin-flow-on-swift).

```swift
createPublisher(homeUseCase().getMoneySummary())
    .eraseToAnyPublisher()
    .receive(on: DispatchQueue.global(qos: .userInitiated))
```

When new data or an error is coming from the `Flow`, the  `@Published` variable will be updated with the new content. The `sink` operator is like `collect` on `Flow`.

```
.sink(
    receiveCompletion: { completion in
        if case let .failure(error) = completion {
            let moneyFlowError = MoneyFlowError.GetMoneySummary(throwable:  error.throwable)
            error.throwable.logError(
                moneyFlowError: moneyFlowError,
                message: "Got error while transforming Flow to Publisher"
            )
            let uiErrorMessage = DI.getErrorMapper().getUIErrorMessage(error: moneyFlowError)
            self.homeModel = HomeModel.Error(uiErrorMessage: uiErrorMessage)
        }
    },
    receiveValue: { genericResponse in
        onMainThread {
            self.homeModel = genericResponse
        }
    }
)
```

When the `ViewModel` will be destroyed, then the coroutine scope will be canceled. 

```swift
deinit {
    homeUseCase().onDestroy()
}
``` 

As a reference, here’s the entire `iOS ViewModel`:

```swift
class HomeViewModel: ObservableObject {

    @Published var homeModel: HomeModel = HomeModel.Loading()
    
    private var subscriptions = Set<AnyCancellable>()

    private func homeUseCase() -> HomeUseCaseIos {
        DI.getHomeUseCase()
    }

    func startObserving() {
        createPublisher(homeUseCase().getMoneySummary())
            .eraseToAnyPublisher()
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        let moneyFlowError = MoneyFlowError.GetMoneySummary(throwable:  error.throwable)
                        error.throwable.logError(
                            moneyFlowError: moneyFlowError,
                            message: "Got error while transforming Flow to Publisher"
                        )
                        let uiErrorMessage = DI.getErrorMapper().getUIErrorMessage(error: moneyFlowError)
                        self.homeModel = HomeModel.Error(uiErrorMessage: uiErrorMessage)
                    }
                },
                receiveValue: { genericResponse in
                    onMainThread {
                        self.homeModel = genericResponse
                    }
                }
            )
            .store(in: &self.subscriptions)
    }

    func deleteTransaction(transactionId: Int64) {
        homeUseCase().deleteTransaction(
            transactionId: transactionId,
            onError: { error in
                self.snackbarData = error.toSnackbarData()
            }
        )
    }

    deinit {
        homeUseCase().onDestroy()
    }
}
```

## Conclusions

With the improvements covered above, the UseCase became more flexible and readable than before. Even though there is an amount of code duplication, I think that it’s a good compromise.
Some duplication is necessary to bridge the gap between different platforms and with this solution, the majority of the business logic is shared and a “slim” ViewModel will be used to fulfill different needs of different platforms.

Another approach can be using [KMP-NativeCoroutines](https://github.com/rickclephas/KMP-NativeCoroutines), a library that will make it easier to use Kotlin Coroutines from Swift code in KMP apps. I will try it out in the future or in another project. 

You can find the code mentioned in the article on [GitHub](https://github.com/prof18/MoneyFlow).

