---
layout: post
title:  "Organize your Views: SwiftUI edition"
date:   2023-03-23
show_in_homepage: false
---

One of the pros of SwiftUI, and generally of declarative UI frameworks, is the capability of defining the UI with the same programming language the application uses. 

With SwiftUI, it is not necessary anymore to bridge the UI definitions from somewhere else, resulting in a decrease of context switching between two different environments (Storyboards and Swift code, for example)

But “with great power comes great responsibility”, and a codebase can quickly become a nightmare without some structure and organization. Long files, large structs, and stateful UI components that hinder reusability are examples that can lead to a messed codebase. 

In this article, I will show how I organized the codebase of [MoneyFlow](https://github.com/prof18/MoneyFlow), a money management app written with Kotlin Multiplatform, Jetpack Compose, and Swift UI. 

> I wrote a similar article that covers the same topic for Jetpack Compose, the declarative UI framework for Android: [“Organize your Views: Jetpack Compose edition”](/posts/2023/organize-view-compose-edition)


## Screens Code Structure

To easily reach the entry point of a screen, I’ve decided to embrace the following structure. 
Every screen has a single Swift file containing the screen’s View Struct, and the screen’s preview. 

For example, for the MoneyFlow Home Screen, there is a `HomeScreen.swift` file that contains `HomeScreen`, and `HomeScreen_Previews `.  

```swift
// HomeScreen.swift

struct HomeScreen: View {
    var body: some View {
        ...
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}        
```

The screen’s struct should just be an entry point and should not contain the entire screen’s code to avoid growing the length of the class too much. Every piece of UI can be split into smaller (maybe even reusable) components.  

To improve testability and increase reusability, the screen’s struct (and in general, all SwiftUI views) should be stateless. To achieve stateless views, the state needs to be hoisted. 

State hoisting is a pattern of moving state to a view's caller. Instead of passing a state variable to a function or even a reference to the ViewModel, only the current values to display and callbacks to react on events are passed.  

```swift
struct HomeScreenContent: View {

    @Binding var appErrorData: SnackbarData
    @Binding var screenErrorData: SnackbarData
    @Binding var homeModel: HomeModel

    let onAppear  : () -> Void
    let deleteTransaction: (Int64) -> Void

    @State private var showAddTransaction = false

    var body: some View {
	   ...
   }
}
```

This way, a view can be reused or tested in different scenarios without any external dependencies. 

The connection with the ViewModel and with external dependencies is made in another View, only responsible for the connection. 

```swift
struct HomeScreen: View {

    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: HomeViewModel = HomeViewModel()

    var body: some View {
        HomeScreenContent(
            appErrorData: $appState.snackbarData,
            screenErrorData: $viewModel.snackbarData,
            homeModel: $viewModel.homeModel,
            onAppear: { viewModel.startObserving() },
            deleteTransaction: { transactionId in
                viewModel.deleteTransaction(transactionId: transactionId)
            }
        )
    }
}
```

To ensure that state hoisting is done correctly without any dependency, a rule of thumb is to write views’s previews. That’s because a Preview, for example, won’t easily work with external dependencies.   

```swift
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenContent(
            appErrorData: .constant(SnackbarData.init()),
            screenErrorData: .constant(SnackbarData.init()),
            homeModel: .constant(
                HomeModel.HomeState(
                    balanceRecap: BalanceRecap(totalBalance: 100, monthlyIncome: 150, monthlyExpenses: 50),
                    latestTransactions: [
                        MoneyTransaction(
                            id: 1,
                            title: "Transaction",
                            icon: CategoryIcon.icAddressBook,
                            amount: 50,
                            type: TransactionTypeUI.expense,
                            milliseconds: 123456,
                            formattedDate: "20/10/21"
                        )
                    ]
                )
            ),
            onAppear: {},
            deleteTransaction: {_ in }
        )

        HomeScreenContent(
            appErrorData: .constant(SnackbarData.init()),
            screenErrorData: .constant(SnackbarData.init()),
            homeModel: .constant(HomeModel.Loading()) ,
            onAppear: {},
            deleteTransaction: {_ in }
        )

        HomeScreenContent(
            appErrorData: .constant(
                SnackbarData(
                    title: "An error occoured",
                    subtitle: "Error code 1012",
                    showBanner: true
                )
            ),
            screenErrorData: .constant(SnackbarData.init()),
            homeModel: .constant(
                HomeModel.Error(
                    uiErrorMessage: UIErrorMessage(
                        message: "Error!",
                        nerdMessage: "Error code: 101"
                    )
                )
            ) ,
            onAppear: {},
            deleteTransaction: {_ in }
        )
    }
}
```

And that’s all. With this approach, the readability and maintainability of the project really increased, especially when opening it after a few months of inactivity.

You can find all the code mentioned in the article on [GitHub](https://github.com/prof18/MoneyFlow).