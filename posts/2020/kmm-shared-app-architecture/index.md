# Choosing the right architecture for a [new] Kotlin Multiplatform, Jetpack Compose and SwiftUI app


{{< rawhtml >}}

  <div id="banner" style="overflow: hidden;justify-content:space-around;">

    <div style="display: inline-block;">
        <a href="https://androidweekly.net/issues/issue-437"><img style="margin: 0px;" src="https://androidweekly.net/issues/issue-437/badge" /></a>
    </div>

    <div style="display: inline-block;">
        <img style="margin: 0px;" src="https://img.shields.io/badge/Featured%20in%20kotlinweekly.net-Issue%20%23221-%237874b4"/>
    </div>
</div>

{{< /rawhtml >}}

Recently, I've started to work on (yet another) side project: Money Flow. As the name suggests, this is an application to help me track all the expenses and incomes. I've thought and designed it almost a year ago but only now I've found the time to start writing actual code. 

{{< figure src="/img/kmm-app-arch/app-design.png" link="/img/kmm-app-arch/app-design.png" caption="A first design iteration, that will change a bit" >}}

I’ve decided to make this project a personal playground for a Kotlin Multiplatform mobile app. Money Flow will be an Android, iOS and MacOS application with a common business logic written in Kotlin. I’ve decided to use the new declarative way to handle UI: Jetpack Compose for Android (still in alpha at the time I’m writing this article) and SwiftUI for iOS/MacOS (that is officially stable, but still causes some headaches in big projects — I’ll probably write about my experience soon).

So, after setting up the project, I started thinking about the architecture of the Home Screen. 

> This article will be a sort of journal that describes all the decisions and the thoughts that I’ve made to come up with a solution that satisfies me. In this way, I want to be helpful to all the people that are in this decision process. 

In the first place, I’ve thought to go with an MVVM approach, with a platform-specific ViewModel defined in the native part. But I wanted to share as much code as possible so I’ve decided to switch to an MVP architecture with Model, (abstract) View and Presenter all defined in the common code. 

The Model is a sealed class that contains the different states: a loading state, an error state and a “success state” with all the info needed to render the HomeScreen.

```kotlin
sealed class HomeModel {
    object Loading: HomeModel()
    data class Error(val message: String): HomeModel()
    data class HomeState(val balanceRecap: BalanceRecap, val latestTransactions: List<Transaction>): HomeModel()
}

data class BalanceRecap(
    val totalBalance: Int,
    val monthlyIncome: Int,
    val monthlyExpenses: Int
)

data class Transaction(
    val id: String,
    val title: String,
    val amount: Int,
    val type: TransactionType,
    val formattedDate: String
)

enum class TransactionType {
    INCOME,
    EXPENSE
}
```

The View is pretty basic, with just a method that receives the data and renders it:

```kotlin
interface HomeView {
    fun presentData(homeModel: HomeModel)
}
```

And finally, the Presenter that instead is a little bit more complicated:

```kotlin
class HomePresenter(
    private val moneyRepository: MoneyRepository,
    // A default state only for iOS
    private val coroutineScope: CoroutineScope = MainScope() 
) : BasePresenter<HomeView>() {

    override fun onViewAttached(view: HomeView) {
        super.onViewAttached(view)
        computeHomeData()
    }

    internal fun computeHomeData(view: HomeView) {
        val latestTransactionFlow = moneyRepository.getLatestTransactions()
        val balanceRecapFlow = moneyRepository.getBalanceRecap()
        coroutineScope.launch {
            latestTransactionFlow.combine(balanceRecapFlow) { transactions: List<Transaction>, balanceRecap: BalanceRecap ->
                HomeModel.HomeState(
                    balanceRecap = balanceRecap,
                    latestTransactions = transactions
                )
            }.collect { homeModel ->
                view.presentData(it)
            }
        }
    }

    override fun onViewDetached() {
        super.onViewDetached()
        coroutineScope.cancel()
    }
}

```

The presenter receives in the constructor the dependencies that it needs plus a *CoroutineScope* that for Android is provided by the native side. On iOS, instead, the scope is initialized by default (because we can’t define a scope from Swift code). 
A CoroutineScope is necessary because the data come from the repository as `Flow` ([here](https://kotlinlang.org/docs/reference/coroutines/flow.html) for more info about Kotlin Flow) and any ongoing operation has to be canceled when the view is destroyed.

Then, I moved to the Android side to develop the HomeScreen:

```kotlin
class MainActivity : AppCompatActivity(), HomeView {

    private val presenter by scoped { HomePresenter(MoneyRepositoryFake()) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        presenter.attachView(this)

        setContent {
            MoneyFlowTheme {
                HomeScreen()
            }
        }
    }

    override fun onDestroy() {
        presenter.detachView()
        super.onDestroy()
    }

    override fun presentData(homeModel: HomeModel) {
        Timber.d(homeModel)
        TODO("Not yet implemented")
        // Send data to the HomeScreen. Maybe with a flow? Live data?
    }
}
```
I’m sure that right now you are wondering what `by scoped` is. Well, this is a solution suggested by [Ryan Harter](https://ryanharter.com/blog/2020/03/easy-android-scopes/) to treat a Presenter like an [Android] ViewModel and make it survive to configuration changes.

And now it’s time for ~~iOS~~ problems. In fact, with SwiftUI the UI is defined with `struct`... 

```swift
import SwiftUI
import shared

struct HomeScreen: View, HomeView {
    
    var body: some View {
        ...
    }
}
```

...and a non-class type (like a struct, `HomeScreen` in this case) cannot conform to protocols (read interface if you come from a JVM world), in this case `HomeView`.

{{< figure src="/img/kmm-app-arch/xcode-error-view.png" >}}


So going with MVP was a failure (with this approach — If you have found other ways, I’ll be more than glad to hear them). That’s why I’ve decided to switch back to an MVVM architecture. But, as I said before, my goal is to share as much code as possible, so I don’t want to create two different platform-specific ViewModels that access directly the `MoneyRepository` to make the exact same transformations. Plus, I need to be able to use a CoroutineScope to cancel any ongoing processing when the view is destroyed, and if I access directly the `MoneyRepository` from an iOS ViewModel I won’t be able to do that. 

Given that circumstances, I’ve decided to use a sort of “shared middleware actor” that prepares and serves the data for the UI. And that actor, that I will call `UseCase`, will be used by the native ViewModels. Of course, this is not a new thing, I’ve borrowed the concept from [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html). In this way, the only task that the ViewModel has to do is to serve to the UI the data that come from the UseCase. And by using such architecture, the ViewModel can use platform-specific code to better handle and respect the lifecycles of the target platform. 

So I wrote a UseCase, that looks like that:

```kotlin
interface HomeUseCase {
    fun observeHomeModel(): StateFlow<HomeModel>
    fun computeData()
    suspend fun computeHomeDataSuspendable()
}

class HomeUseCaseImpl(
    private val moneyRepository: MoneyRepository,
    // That's only for iOs
    private val viewUpdate: ((HomeModel) -> Unit)? = null,
): HomeUseCase {

    // Used only on iOs
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

    // iOs only
    fun onDestroy() {
        coroutineScope.cancel()
    }
}
```

As you may have already noticed, there is some “duplicated” stuff in the class. And that’s because some different behavior between Android and iOS must be covered. 
On **Android**, I use a suspendable function and a `Flow` to process the data and observe the changes. The native part (i.e., the Android ViewModel) can call the `computeHomeDataSuspendable` function in a specific CoroutineScope (that ideally will be the `viewModelScope`) and observe the changes with the `homeModel` flow. 
On **iOS** instead, a Flow cannot be directly observed and plus, the cancellation of the data observed from the `MoneyRepository` must be handled manually. For the former problem, a simple callback can be used. This callback is provided in the constructor (that by default is null and it will be defined only on iOs) and will be called (only if it is not null, of course!) when collecting the data from the two flows. The latter problem instead, can be solved (similarly to what I’ve done before in the Presenter) by using a default CoroutineScope and two methods: one to start to get the data and one to cancel the entire process. The `computeData` method will call the `computeHomeDataSuspendable` method on a specific CoroutineScope that can be canceled with the `onDestroy` method.

And that’s it for the shared code. Now the dots can be connected in the native part. 
For Android, I’ve used a simple Android ViewModel that starts observing the data when initialized, collect the flow and update a LiveData.


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

Then in the UI, I can observe the LiveData and update the UI accordingly.

```kotlin

@Composable
fun HomeScreen() {

    val viewModel: HomeViewModel = viewModel()

    val homeModel by viewModel.homeLiveData.observeAsState()

    Scaffold(
        ...
    )
}
```

On iOS instead, the ViewModel is an `ObservableObject` that exposes the HomeModel as a `Published` object (an equivalent to the LiveData). 


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

In this case, the observation of the data is not started automatically, but there are two methods, one to start observing and one to cancel the observation. 

The iOS screen will look like that:


```swift
import SwiftUI
import shared

struct HomeScreen: View {
    
    @ObservedObject var viewModel: HomeViewModel = HomeViewModel()
    
    var body: some View {
        
        NavigationView {
            ...
        }
        .onAppear {
            self.viewModel.startObserving()
        }.onDisappear {
            self.viewModel.stopObserving()
        }
    }
}
``` 

And that’s it!

{{< figure src="/img/kmm-app-arch/what-to-do.gif" >}}

If you want to give a look at the entire code mentioned in this article, you can give a look to 
[Github](https://github.com/prof18/MoneyFlow/tree/4b628cce71ad145c464b2d3d4100c131cd37fbdc) (Be aware that the project is still in its early stages of development, so things can be "ugly" and can heavily change). 

In this way, I have the majority of the business logic shared, with a “slim” ViewModel that is necessary to respect the different needs of the different platforms.

{{< smalltext >}} // Thanks to <a href="https://giansegato.com/">Gian</a> for helping me review the post {{< /smalltext >}}