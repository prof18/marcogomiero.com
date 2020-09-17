---
layout: post
title:  "CHANGEME - Exploring Kotlin Multiplatform app architecture with Jetpack Compose and SwiftUI"
date:   2020-09-06
show_in_homepage: true
draft: true
tags: [Kotlin Multiplatform]
---

Design:

{{< figure src="/img/kmm-app-arch/app-design.png" >}}

What I have to do:

{{< figure src="/img/kmm-app-arch/what-to-do.gif" >}}

Xcode error:

{{< figure src="/img/kmm-app-arch/xcode-error-view.png" >}}


----



First i tought to do a view model for each platform, since it is code really connected to UI. But i wnated to share more

I started with a MVP approach. A presenter that receives its depedendecies plus a coroutine scope that by default is the Main one (mostly for iOs).

Example:

First example of HomeView

```kotlin

interface HomeView {

    fun presentData(homeModel: HomeModel)

}

```

[link](https://github.com/prof18/MoneyFlow/blob/a508171d5f2c0414484500e1a4d34b10fa22faa9/shared/src/commonMain/kotlin/presentation/home/HomeView.kt)

First example of HomePresenter

```kotlin

class HomePresenter(
    private val moneyRepository: MoneyRepository,
    // A default state only for iOS
    private val coroutineScope: CoroutineScope = MainScope() 
) : BasePresenter<HomeView>() {

    private val homeModel = MutableStateFlow<HomeModel>(HomeModel.Loading)

    fun observeHomeModel(): Flow<HomeModel> = homeModel

    override fun onViewAttached(view: HomeView) {
        super.onViewAttached(view)
        // TODO: start some action?
    }

    fun computeHomeData() {
        val latestTransactionFlow = moneyRepository.getLatestTransactions()
        val balanceRecapFlow = moneyRepository.getBalanceRecap()
        coroutineScope.launch {
            latestTransactionFlow.combine(balanceRecapFlow) { transactions: List<Transaction>, balanceRecap: BalanceRecap ->
                HomeModel.HomeState(
                    balanceRecap = balanceRecap,
                    latestTransactions = transactions
                )
            }.collect {
                homeModel.value = it
            }
        }
    }

    override fun onViewDetached() {
        super.onViewDetached()
        coroutineScope.cancel()
    }
}

```

[link](https://github.com/prof18/MoneyFlow/blob/a508171d5f2c0414484500e1a4d34b10fa22faa9/shared/src/commonMain/kotlin/presentation/home/HomePresenter.kt)

I've integrated on android by using the solution suggested by [Ryan Harter](https://ryanharter.com/blog/2020/03/easy-android-scopes/)
with the attach on the createView and the detach on the destroyView

Example of the Main Activity that calls the ViewModel

```kotlin

class MainActivity : AppCompatActivity(), HomeView {

    private val presenter by scoped { HomePresenter(MoneyRepositoryFake()) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        presenter.attachView(this)
        presenter.computeHomeData()

        setContent {
            MoneyFlowTheme {
                HomeScreen(presenter)
            }
        }
    }

    override fun onDestroy() {
        presenter.detachView()
        super.onDestroy()
    }

    override fun presentData(homeModel: HomeModel) {
        TODO("Not yet implemented")
    }
}

```

https://github.com/prof18/MoneyFlow/blob/a508171d5f2c0414484500e1a4d34b10fa22faa9/androidApp/src/main/java/com/prof18/moneyflow/MainActivity.kt


Then I went to the iOs side and here's the problems

Non-class type 'HomeScreen' cannot conform to class protocol 'HomeView'

(Take the image from telegram of the error)

```swift
import SwiftUI
import shared

struct HomeScreen: View, HomeView {
    
    var body: some View {
        NavigationView {
            VStack {
                HomeRecap()
                HeaderNavigator()
                List {
                    ForEach(0...5, id: \.self) { _ in
                        TransactionCard()
                            .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitle(Text("Wallet"), displayMode: .automatic)
            .navigationBarItems(trailing: Button(action: {
                print("tapped")
            }) {
                Text("Add transaction")
                
            })
        }
    }
}
```

[Swift Example with errors](https://github.com/prof18/MoneyFlow/blob/a508171d5f2c0414484500e1a4d34b10fa22faa9/iosApp/Shared/Home/HomeScreen.swift)

so I've decided to move to a mixed use case:

Code: 

Shared:

Model:

```kotlin

sealed class HomeModel {
    object Loading: HomeModel()
    data class Error(val message: String): HomeModel()
    data class HomeState(val balanceRecap: BalanceRecap, val latestTransactions: List<Transaction>): HomeModel()
}

```

[Model link](https://github.com/prof18/MoneyFlow/blob/4b628cce71ad145c464b2d3d4100c131cd37fbdc/shared/src/commonMain/kotlin/presentation/home/HomeModel.kt)

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

