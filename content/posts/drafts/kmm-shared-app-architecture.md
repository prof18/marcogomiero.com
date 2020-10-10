---
layout: post
title:  "CHANGEME - Exploring Kotlin Multiplatform app architecture with Jetpack Compose and SwiftUI"
date:   2020-09-06
show_in_homepage: true
draft: true
tags: [Kotlin Multiplatform]
---

Recently, I've started to work on (yet another) side project: Money Flow. As the name suggests, this is an application to help me tracking all the expenses and the incomes. I've thought and designed it almost a year ago and only now I've found the time to start writing code. 

{{< figure src="/img/kmm-app-arch/app-design.png" caption=“First design iteration, it will change a bit”>}}

And I’ve decided to make this project a personal playground for a Kotlin Multiplatform mobile app. Money Flow will be an Android, iOS and MacOS application with a common business logic written in Kotlin. And I’ve decided to use the new declarative way to do UI: Jetpack Compose for Android (still in alpha when I’m writing this article) and SwiftUI for iOs/MacOS (that is officially stable, but still causes some headache in big projects - I’ll probably write about my experience soon - ).

So, after setting up the project, I started to think about the architecture of the Home Screen. 

> This article will be a sort of journal that describes all the decisions and the thoughts that I’ve made to come up with a solution that really satisfies me. In this way I want to be helpful to all the people that are in this decision process. 

I the first place, I’ve thought to go with a MVVM approach, with a platform specific ViewModel defined in the native part. But I wanted to share more code as possible so I’ve decided to switch to an MVP architecture with Model, (abstract) View and Presenter defined in the common code. 

The Model is a sealed class that contains the different states: a loading state, an error state and a “success state” that contains all the info needed to render the HomeScreen.

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

And finally we have the Presenter that instead is a little bit more complicated:

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

The presenter receives in the constructor the dependencies that it needs and plus a *CoroutineScope* that for Android will be the provided by the native part, instead for iOS the scope will be initialized by default (because we can’t define a scope from the Swift code). 
We need a CoroutineScope, because the data come from the repository as `Flows` ([here](https://kotlinlang.org/docs/reference/coroutines/flow.html) for more info about Kotlin Flows) and we need to cancel any ongoing operation if the view is destroyed. 

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
        // Send data to the HomeScreen. Maybe with a flow? A live data?
    }
}
```
I’m sure that right know you are wondering what `by scoped` is. Well, this is a solution suggested by [Ryan Harter](https://ryanharter.com/blog/2020/03/easy-android-scopes/) to treat a Presenter like and [Android] ViewModel and make it survive to configuration changes.

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

...and a non-class type (like a struct, `HomeScreen` in our case) cannot conform to protocols (read interface if you come from a JVM world), in our case `HomeView`.

{{< figure src="/img/kmm-app-arch/xcode-error-view.png" >}}


So going with MVP (in this way. If you have found other ways I’ll be more than glad to hear them) was a failure and so I’ve decided to switch back to a MVVM architecture. But, as I said before, my goal is to share as much code as possibile, so I don’t want to create two different platform specific ViewModels that access directly the `MoneyRepository` to make the exact same transformations. Plus, I need to be able to use a CoroutineScope to cancel any ongoing processing when the view is destroyed, and if I access directly the `MoneyRepository`from an iOs ViewModel I won’t be able to do that. 

Given that circumstances, I’ve decided to use a sort of “shared middleware actor” that prepares and serves the data for the UI. And that actor, that I will call `UseCase`, will be used by the native ViewModels. Of course this is not a new thing, I’ve borrowed the concept from the [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html). In this way, the only task that the ViewModel has to do is to serve to the UI the data that come from the UseCase. And by using such architecture, the ViewModel can use platform specific code to better handle and respect the lifecycles of the target platform. 





----

What I have to do:

{{< figure src="/img/kmm-app-arch/what-to-do.gif" >}}

so I've decided to move to a mixed use case:

UseCase:

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

[UseCase Interface](https://github.com/prof18/MoneyFlow/blob/4b628cce71ad145c464b2d3d4100c131cd37fbdc/shared/src/commonMain/kotlin/presentation/home/HomeUseCase.kt)

[UseCaseImpl link](https://github.com/prof18/MoneyFlow/blob/4b628cce71ad145c464b2d3d4100c131cd37fbdc/shared/src/commonMain/kotlin/presentation/home/HomeUseCaseImpl.kt)

Android:

ViewModel

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

[view model link](https://github.com/prof18/MoneyFlow/blob/4b628cce71ad145c464b2d3d4100c131cd37fbdc/androidApp/src/main/java/com/prof18/moneyflow/ui/HomeViewModel.kt)

Screen:

```kotlin

@Composable
fun HomeScreen() {

    val viewModel: HomeViewModel = viewModel()

    val homeModel by viewModel.homeLiveData.observeAsState()

    Scaffold(
        bodyContent = { innerPadding ->

            when (homeModel) {
                is HomeModel.Loading -> CircularProgressIndicator()
                is HomeModel.HomeState -> {

                    val homeState = (homeModel as HomeModel.HomeState)

                    Column(modifier = Modifier.padding(innerPadding)) {

                        HomeRecap(homeState.balanceRecap)
                        HeaderNavigator()

                        LazyColumnFor(items = homeState.latestTransactions) {
                            TransactionCard(it)
                            Divider()
                        }
                    }
                }
                is HomeModel.Error -> Text("Something wrong here!")
            }
        },
        ...
      )

```

[Screen Link](https://github.com/prof18/MoneyFlow/blob/4b628cce71ad145c464b2d3d4100c131cd37fbdc/androidApp/src/main/java/com/prof18/moneyflow/ui/home/HomeScreen.kt)

iOs: 

ViewModel:

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

[ViewModel link](https://github.com/prof18/MoneyFlow/blob/4b628cce71ad145c464b2d3d4100c131cd37fbdc/iosApp/Shared/Home/HomeViewModel.swift)

Screen:

```swift

import SwiftUI
import shared

struct HomeScreen: View {
    
    @ObservedObject var viewModel: HomeViewModel = HomeViewModel()
    
    var body: some View {
        
        NavigationView {
            
            VStack {
                
                if (viewModel.homeModel is HomeModel.Loading) {
                    Loader().edgesIgnoringSafeArea(.all)
                } else if (viewModel.homeModel is HomeModel.HomeState) {
                    
                    HomeRecap(balanceRecap: (viewModel.homeModel as! HomeModel.HomeState).balanceRecap)
                    HeaderNavigator()
                    
                    List {
                        ForEach((viewModel.homeModel as! HomeModel.HomeState).latestTransactions, id: \.self) { transaction in
                            TransactionCard(transaction: transaction)
                                 .listRowInsets(EdgeInsets())
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarTitle(Text("Wallet"), displayMode: .automatic)
            .navigationBarItems(trailing: Button(action: {
                print("tapped")
            }) {
                Text("Add transaction")
                
            })
            .onAppear {
                self.viewModel.startObserving()
            }.onDisappear {
                self.viewModel.stopObserving()
            }
        }
    }
}
```

[Screen link](https://github.com/prof18/MoneyFlow/blob/4b628cce71ad145c464b2d3d4100c131cd37fbdc/iosApp/Shared/Home/HomeScreen.swift)


[Full code showed in this article](https://github.com/prof18/MoneyFlow/tree/4b628cce71ad145c464b2d3d4100c131cd37fbdc) 

