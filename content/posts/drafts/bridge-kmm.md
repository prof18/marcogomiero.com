---
layout: post
title:  "CHANGEME: bridge kmm"
date:   2021-12-30
show_in_homepage: false
draft: true
---

https://github.com/rickclephas/KMP-NativeCoroutines

HomeUseCasse
```kotlin
class HomeUseCase(
    private val moneyRepository: MoneyRepository,
    private val settingsRepository: SettingsRepository,
    private val errorMapper: MoneyFlowErrorMapper
) {

    val hideSensibleDataState: StateFlow<Boolean> = settingsRepository.hideSensibleDataState

    fun observeHomeModel(): Flow<HomeModel> =
        moneyRepository.getMoneySummary()
            .catch { throwable: Throwable ->
                val error = MoneyFlowError.GetMoneySummary(throwable)
                throwable.logError(error)
                val errorMessage = errorMapper.getUIErrorMessage(error)
                HomeModel.Error(errorMessage)
            }.map {
                HomeModel.HomeState(
                    balanceRecap = it.balanceRecap,
                    latestTransactions = it.latestTransactions
                )
            }

    fun toggleHideSensitiveData(status: Boolean) {
        settingsRepository.setHideSensitiveData(status)
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

HomeUseCaseIos
```kotlin
class HomeUseCaseIos(
    private val homeUseCase: HomeUseCase
) : BaseUseCaseIos() {

    val hideSensibleDataState: FlowWrapper<Boolean> =
        FlowWrapper(scope, homeUseCase.hideSensibleDataState)

    fun getMoneySummary(): FlowWrapper<HomeModel> =
        FlowWrapper(scope, homeUseCase.observeHomeModel().freeze())

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

BaseUseCaseIos
```kotlin
abstract class BaseUseCaseIos {

    private val dispatcher: CoroutineDispatcher = Dispatchers.Default
    internal val scope = CoroutineScope(SupervisorJob() + dispatcher)

    fun onDestroy() {
        scope.cancel()
    }
}
```

FlowWrapper
```kotlin
// From https://github.com/russhwolf/To-Do/blob/master/shared/src/iosMain/kotlin/com/russhwolf/todo/shared/CoroutineAdapters.kt
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