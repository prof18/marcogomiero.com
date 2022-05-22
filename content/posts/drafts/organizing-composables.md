---
layout: post
title:  "CHANGEME: Organizing composables"
date:   2022-05-09
show_in_homepage: false
draft: true
---

--- 




https://twitter.com/marcogomier/status/1414620909856493573?



 cleaning up the compose part of MoneyFlow



[Lachlan McKee](https://twitter.com/lachlantmckee)’s article: [Scalable Jetpack Compose Navigation](https://medium.com/bumble-tech/scalable-jetpack-compose-navigation-9c0659f7c912)


To make the preview work you need to avoid passing ViewModel instances and other dependencies. By doing that composables start becoming "real clean"

Another thing that I'm doing is better organize the navigation, inspired by the article of @LachlanTMcKee (link.medium.com/AnSLjySYQhb)

I've created a factory responsible to create the composable for a screen, in this way the NavHost will be "cleaner".

hoisting some state and avoid passing ViewModel instances. 
A rule of thumb that I found useful is to make your composable work for the preview. 



```kotlin
internal interface ComposeNavigationFactory {
    fun create(navGraphBuilder: NavGraphBuilder, navController: NavController)
}
```


```kotlin

 val navController = rememberNavController()

        NavHost(navController, startDestination = Screen.HomeScreen.route) {

            HomeScreenFactory(paddingValues).create(this, navController)

            AddTransactionScreenFactory(categoryState).create(this, navController)

            CategoriesScreenFactory(categoryState).create(this, navController)

            // Coming Soon
//                RecapScreenFactory.create(this, navController)

            // Coming Soon
//                BudgetScreenFactory.create(this, navController)

            SettingsScreenFactory.create(this, navController)

            AllTransactionsScreenFactory.create(this, navController)
        }
```



```kotlin
internal class HomeScreenFactory(private val paddingValues: PaddingValues) : ComposeNavigationFactory {
    override fun create(navGraphBuilder: NavGraphBuilder, navController: NavController) {
        navGraphBuilder.composable(Screen.HomeScreen.route) {
            val homeViewModel = getViewModel<HomeViewModel>()
            val homeModelState: HomeModel by homeViewModel.homeState.collectAsState()
            val hideSensitiveDataState: Boolean by homeViewModel.hideSensitiveDataState.collectAsState()

            HomeScreen(
                navigateToAddTransaction = {
                    navController.navigate(Screen.AddTransactionScreen.route)
                },
                paddingValues = paddingValues,
                deleteTransaction = { transactionId ->
                    homeViewModel.deleteTransaction(transactionId)
                },
                homeModel = homeModelState,
                hideSensitiveDataState = hideSensitiveDataState,
                changeSensitiveDataVisibility = { visibility ->
                    homeViewModel.changeSensitiveDataVisibility(
                        visibility
                    )
                },
                navigateToAllTransactions = { navController.navigate(Screen.AllTransactionsScreen.route) }
            )
        }
    }
}

@Composable
@Suppress("LongMethod") // TODO: reduce method length
internal fun HomeScreen(
    navigateToAddTransaction: () -> Unit = {},
    paddingValues: PaddingValues = PaddingValues(0.dp),
    deleteTransaction: (Long) -> Unit = {},
    homeModel: HomeModel,
    hideSensitiveDataState: Boolean,
    changeSensitiveDataVisibility: (Boolean) -> Unit = {},
    navigateToAllTransactions: () -> Unit
) {

	... 

}

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





