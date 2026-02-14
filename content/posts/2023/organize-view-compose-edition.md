---
layout: post
title:  "Organize your Views: Jetpack Compose edition"
date:   2023-03-15
show_in_homepage: false
---

{{< rawhtml >}}

<div class="post-award-container">

    <a href="https://androidweekly.net/issues/issue-562">
        <img src="https://androidweekly.net/issues/issue-562/badge" />
    </a>

    <a href="https://jetc.dev/issues/157.html">
        <img src="https://img.shields.io/badge/As_Seen_In-jetc.dev_Newsletter_Issue_%23157-blue?logo=Jetpack+Compose&amp;logoColor=white"/>
    </a>
</div>

{{< /rawhtml >}}



One of the pros of Jetpack Compose (in the rest of the article, I will just call it Compose, for brevity), and generally of declarative UI frameworks, is the capability of defining the UI with the same programming language the rest of the application uses. 

With Compose, it is not necessary anymore to bridge the UI definitions from XML (e.g. with the [in]famous `findViewById`), resulting in less context switching between two different environments (XML and Kotlin code).

But “with great power comes great responsibility”, and a codebase can quickly become a nightmare without some structure and organization. Long files, large composable functions, and stateful UI components that hinder reusability are examples that can lead to a messy codebase. 

In this article, I will show how I organized the codebase of [MoneyFlow](https://github.com/prof18/MoneyFlow), a money management app written with Kotlin Multiplatform, Jetpack Compose, and Swift UI. 

> I wrote a similar article that covers the same topic for SwiftUI, the declarative UI framework for iOS: [“Organize your Views: SwiftUI edition”](/posts/2023/organize-view-swiftui-edition)


## Jetpack Navigation and “god classes”

[Jetpack Compose Navigation](https://developer.android.com/jetpack/compose/navigation) is the navigation solution for Compose provided by Google. With that, it is possible to create a “central” navigation graph, and then navigation between different screens can be triggered by using URIs.

The navigation graph can be created by defining a `NavHost` containing each route. A route is defined by a string (the URI of that route) and a composable function (the UI that the user will see).
 
```kotlin
NavHost(navController = navController, startDestination = "profile") {
    composable("profile") { Profile(/*...*/) }
    composable("friendslist") { FriendsList(/*...*/) }
    /*...*/
}
``` 

> From https://developer.android.com/jetpack/compose/navigation#create-navhost

With this approach, the class that contains the `NavHost` will start to grow a lot. 
For example, here’s a snippet of an old version of MoneyFlow (N.B. Don’t copy this code, it’s old and without proper and clean state hoisting):

```kotlin
NavHost(navController, startDestination = Screen.HomeScreen.route) { 
    composable(Screen.HomeScreen.route) {
        HomeScreen(navController, paddingValues)
    }

    composable(Screen.AddTransactionScreen.route) {
        // Get back the category
        val category = it.savedStateHandle
            .getLiveData<CategoryUIData>( NavigationArguments.Category.key)
            .observeAsState()

        AddTransactionScreen(
            categoryName = category.value?.name,
            categoryId = category.value?.id,
            categoryIcon = category.value?.icon,
            navigateUp = { navController.popBackStack() },
            navigateToCategoryList = {
                navController.navigate("${Screen.CategoriesScreen.route}/true")
            },
        )
    }

    composable(
        route = Screen.CategoriesScreen.route + "/{${ NavigationArguments.FromAddTransaction.key}}",
        arguments = listOf(navArgument( NavigationArguments.FromAddTransaction.key) {
            type = NavType.BoolType
        })
    ) { backStackEntry ->
        CategoriesScreen(
            navigateUp = { navController.popBackStack() },
            sendCategoryBack = { navArguments, categoryData ->
                navController.previousBackStackEntry?.savedStateHandle?.set(
                    navArguments.key,
                    categoryData
                )
            },
            isFromAddTransaction = backStackEntry.arguments?.getBoolean(
                NavigationArguments.FromAddTransaction.key
            ) ?: false,
        )
    }
    
	composable(Screen.RecapScreen.route) {
	    RecapScreen()
    }

	composable(Screen.BudgetScreen.route) {
		BudgetScreen()
    }

    composable(Screen.SettingsScreen.route) {
        SettingsScreen()
    }
}
```

If the application keeps growing with more and more screens, this snippet of code will become harder and harder to read, understand and maintain.

## A slim NavHost

On the mission to tackle this issue, I found an interesting approach described in [Lachlan McKee](https://twitter.com/lachlantmckee)’s article: [Scalable Jetpack Compose Navigation](https://medium.com/bumble-tech/scalable-jetpack-compose-navigation-9c0659f7c912), and I decided to follow a similar approach.

Creating the composable for a screen is delegated to a factory that can be defined outside the `NavHost`. 

```kotlin
internal interface ComposeNavigationFactory {
    fun create(navGraphBuilder: NavGraphBuilder, navController: NavController)
}
```

The factory can even be defined in a feature module, leaving all the implementation details hidden.

```kotlin
class HomeScreenFactory() : ComposeNavigationFactory {
    override fun create(navGraphBuilder: NavGraphBuilder, navController: NavController) {
        navGraphBuilder.composable(Screen.HomeScreen.route) {
            HomeScreen()
        }
    }
}
```

This way, the `NavHost` will become cleaner.

```kotlin
NavHost(navController, startDestination = Screen.HomeScreen.route) {
    HomeScreenFactory().create(this, navController)
}
```


## Screens Code Structure

To easily reach the entry point of a screen, I’ve decided to embrace the following structure. 
Every screen has a single Kotlin file containing the screen’s factory, the screen’s composable function, and the screen’s preview. 

For example, for the MoneyFlow Home Screen, there is a `HomeScreen.kt` file that contains `HomeScreenFactory`, `HomeScreen`, and `HomeScreenPreview`.  

```kotlin
// HomeScreen.kt
internal class HomeScreenFactory(private val paddingValues: PaddingValues) : ComposeNavigationFactory {
    override fun create(navGraphBuilder: NavGraphBuilder, navController: NavController) {
        navGraphBuilder.composable(Screen.HomeScreen.route) {
            HomeScreen(
                paddingValues = paddingValues,
            )
        }
    }
}

@Composable
internal fun HomeScreen(
    paddingValues: PaddingValues = PaddingValues(0.dp),
) {
    ... 
}

@Preview(name = "HomeScreenError Light")
@Preview(name = "HomeScreenError Night", uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun HomeScreenPreview() {
    MoneyFlowTheme {
        Surface {
            HomeScreen()
        }
    }
}
```

The screen’s composable function should just be an entry point and should not contain the entire screen’s code to avoid growing the length of the function too much. Every piece of UI  can be split into smaller (maybe even reusable) components.  

To improve testability and increase reusability, the screen’s composable function (and in general, all the composable functions) should be stateless. To achieve stateless functions, the state needs to be hoisted. 

State hoisting is a pattern of moving state to a composable's caller. Instead of passing a state variable to a function or even a reference to the ViewModel, only the current values to display and callbacks to react on events are passed.  

```kotlin
@Composable
internal fun HomeScreen(
    paddingValues: PaddingValues = PaddingValues(0.dp),
    homeModel: HomeModel,
    deleteTransaction: (Long) -> Unit = {},
    hideSensitiveDataState: Boolean,
    changeSensitiveDataVisibility: (Boolean) -> Unit = {},
    navigateToAddTransaction: () -> Unit = {},
    navigateToAllTransactions: () -> Unit,
) {
    ... 
}
```

This way, a compossable function can be reused or tested in different scenarios without any external dependencies. 

The connection with the ViewModel and with the navigation logic instead is made inside the screen factory, 

```kotlin
internal class HomeScreenFactory(private val paddingValues: PaddingValues) : ComposeNavigationFactory {
    override fun create(navGraphBuilder: NavGraphBuilder, navController: NavController) {
        navGraphBuilder.composable(Screen.HomeScreen.route) {
            val homeViewModel = getViewModel<HomeViewModel>()
            val homeModelState: HomeModel by homeViewModel.homeState.collectAsState()
            val hideSensitiveDataState: Boolean by homeViewModel.hideSensitiveDataState.collectAsState()

            HomeScreen(
                paddingValues = paddingValues,
                homeModel = homeModelState,
                deleteTransaction = { transactionId ->
                    homeViewModel.deleteTransaction(transactionId)
                },
                hideSensitiveDataState = hideSensitiveDataState,
                changeSensitiveDataVisibility = { visibility ->
                    homeViewModel.changeSensitiveDataVisibility(
                        visibility
                    )
                },
                navigateToAllTransactions = { 
                navController.navigate(Screen.AllTransactionsScreen.route) 
                },
                navigateToAddTransaction = {
                navController.navigate(Screen.AddTransactionScreen.route)
                },
            )
        }
    }
}
```

To ensure that state hoisting is done correctly without any dependencies, a rule of thumb is to write composable’s previews. That’s because a Preview, for example, won’t easily work with a dependency on a ViewModel (it would work by writing a Fake ViewModel, but it will require more additional work).    

```kotlin
@Preview(name = "HomeScreenError Light")
@Preview(name = "HomeScreenError Night", uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun HomeScreenErrorPreview() {
    MoneyFlowTheme {
        Surface {
            HomeScreen(
                homeModel = HomeModel.Error(
                    UIErrorMessage(
                        "An error occurred",
                        "Error code 101",
                    )
                ),
                hideSensitiveDataState = true,
                navigateToAllTransactions = {}
            )
        }
    }
}
```

For more information about state and state hoisting, you can look at the Android documentation:

- [State and Jetpack Compose](https://developer.android.com/jetpack/compose/state)
- [Where to hoist state](https://developer.android.com/jetpack/compose/state-hoisting)

And that’s all. With this approach, the readability and maintainability of the project really increased, especially when opening it after a few months of inactivity.

You can find all the code mentioned in the article on [GitHub](https://github.com/prof18/MoneyFlow).

{{< smalltext >}} // Thanks to <a href="https://twitter.com/stewemetal">István</a> for helping me review the post {{< /smalltext >}}