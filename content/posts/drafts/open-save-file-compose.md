---
layout: post
title:  "How to open and save files on Jetpack Compose"
date:   2021-01-24
show_in_homepage: false 
draft: true
tags: [Android, Jetpack Compose]
---

During the development of the Android client of [MoneyFlow](https://github.com/prof18/MoneyFlow), I found myself in the situation of opening and saving a file from the device memory and the location of the file is chosen by the user with the system file picker.   Usually, for this task, I launch a Activity with the `ACTION_OPEN_DOCUMENT` Intent and I wait for a result.

```kotlin
// Request code for selecting a PDF document.
const val PICK_PDF_FILE = 2

fun openFile(pickerInitialUri: Uri) {
    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
        addCategory(Intent.CATEGORY_OPENABLE)
        type = "application/pdf"

        // Optionally, specify a URI for the file that should appear in the
        // system file picker when it loads.
        putExtra(DocumentsContract.EXTRA_INITIAL_URI, pickerInitialUri)
    }

    startActivityForResult(intent, PICK_PDF_FILE)
}
```
{{< smalltext >}} <a href="https://developer.android.com/training/data-storage/shared/documents-files#open-file">Code taken from the Android Documentation</a> {{< /smalltext >}}

But the UI of *MoneyFlow* is totally written with Jetpack Compose with a single activity and the screen on which I open and save a file is deep in the navigation flow. For this reason the `startActivityForResult` way is not viable.  
Well, I can still be able to launch an activity on a Composable view by doing this:

```kotlin
val context = AmbientContext.current
context.startActivityForResult(Intent(context, MyActivity::class.java), CODE)
```                            
but, the `onActivityResult` must be override in the base Activity and then dispatching the result to the caller will be a tough task. Plus, this is not a beatiful solution, beacuse the main Activity will be bloated with too much things.

So I’ve started to look around and I found out that now it is possible (and it is highly suggested) to use the new Activity Result APIs that has been introduced in AndroidX Activity 1.2.0-alpha02 and Fragment 1.3.0-alpha02. These APIs allows to handle the onActivityResult callback in a better and reusable way, even outside an Activity. For more information, you can give a look [to the official documentation](https://developer.android.com/training/basics/intents/result). 

Then, I found out how to use the Activity Result APIs in a Composable function, thanks to [an answer on StackOverflow](https://stackoverflow.com/a/64722700 ) of [Ian Lake](https://twitter.com/ianhlake).



```kotlin
@Composable
fun <I, O> registerForActivityResult(
    contract: ActivityResultContract<I, O>,
    onResult: (O) -> Unit
) : ActivityResultLauncher<I> {
    // First, find the ActivityResultRegistry by casting the Context
    // (which is actually a ComponentActivity) to ActivityResultRegistryOwner
    val owner = AmbientContext.current as ActivityResultRegistryOwner
    val activityResultRegistry = owner.activityResultRegistry

    // Keep track of the current onResult listener
    val currentOnResult = rememberUpdatedState(onResult)

    // It doesn't really matter what the key is, just that it is unique
    // and consistent across configuration changes
    val key = rememberSavedInstanceState { UUID.randomUUID().toString() }

    // Since we don't have a reference to the real ActivityResultLauncher
    // until we register(), we build a layer of indirection so we can
    // immediately return an ActivityResultLauncher
    // (this is the same approach that Fragment.registerForActivityResult uses)
    val realLauncher = mutableStateOf<ActivityResultLauncher<I>?>(null)
    val returnedLauncher = remember {
        object : ActivityResultLauncher<I>() {
            override fun launch(input: I, options: ActivityOptionsCompat?) {
                realLauncher.value?.launch(input, options)
            }

            override fun unregister() {
                realLauncher.value?.unregister()
            }

            override fun getContract() = contract
        }
    }

    // DisposableEffect ensures that we only register once
    // and that we unregister when the composable is disposed
    DisposableEffect(activityResultRegistry, key, contract) {
        realLauncher.value = activityResultRegistry.register(key, contract) {
            currentOnResult.value(it)
        }
        onDispose {
            realLauncher.value?.unregister()
        }
    }
    return returnedLauncher
}

```


The function take as input an ActivityResultContract - describe what it is - and a callback where the result will be handled.

An ActivityResultContract defines the input type needed to produce a result along with the output type of the result. The APIs provide default contracts for basic intent actions like taking a picture, requesting permissions, and so on. You can also create your own custom contracts.

public static class OpenDocument extends ActivityResultContract<String[], Uri> {

public static class CreateDocument extends ActivityResultContract<String, Uri> {

https://developer.android.com/reference/androidx/activity/result/contract/ActivityResultContract

——-

The function return a ActivityResultLauncher<I> that we can launch to start the process


```kotlin
// First, find the ActivityResultRegistry by casting the Context
// (which is actually a ComponentActivity) to ActivityResultRegistryOwner
val owner = AmbientContext.current as ActivityResultRegistryOwner
val activityResultRegistry = owner.activityResultRegistry
```

```kotlin
 // Keep track of the current onResult listener
val currentOnResult = rememberUpdatedState(onResult)
```

```kotlin
// It doesn't really matter what the key is, just that it is unique
// and consistent across configuration changes
val key = rememberSavedInstanceState { UUID.randomUUID().toString() }
```

```kotlin
// Since we don't have a reference to the real ActivityResultLauncher
// until we register(), we build a layer of indirection so we can
// immediately return an ActivityResultLauncher
// (this is the same approach that Fragment.registerForActivityResult uses)
val realLauncher = mutableStateOf<ActivityResultLauncher<I>?>(null)
val returnedLauncher = remember {
    object : ActivityResultLauncher<I>() {
        override fun launch(input: I, options: ActivityOptionsCompat?) {
            realLauncher.value?.launch(input, options)
        }

        override fun unregister() {
            realLauncher.value?.unregister()
        }

        override fun getContract() = contract
    }
}
```

```kotlin
// DisposableEffect ensures that we only register once
// and that we unregister when the composable is disposed
DisposableEffect(activityResultRegistry, key, contract) {
    realLauncher.value = activityResultRegistry.register(key, contract) {
        currentOnResult.value(it)
    }
    onDispose {
        realLauncher.value?.unregister()
    }
}
```

///

So, i find out the result contract. 
Link Question from Iam
Paste source code from question
Describe a bit about the activity result api
Describe a bit about the composable stuff of the snippet
Show the end result
Show that you can use also the result to open a simple activity for result


//


ActivityResultCallback is a single method interface with an onActivityResult() method that takes an object of the output type defined in the ActivityResultContract:

Calling launch() starts the process of producing the result. When the user is done with the subsequent activity and returns, the onActivityResult() from the ActivityResultCallback is then executed, as shown in the following example:

A registry that stores activity result callbacks for registered calls. You can create your own instance for testing by overriding onLaunch(int, ActivityResultContract, I, ActivityOptionsCompat) and calling dispatchResult(int, O) immediately within it, thus skipping the actual Activity.startActivityForResult(Intent, int) call. When testing, make sure to explicitly provide a registry instance whenever calling ActivityResultCaller.registerForActivityResult(ActivityResultContract, ActivityResultCallback), to be able to inject a test instance.

https://developer.android.com/reference/androidx/activity/result/ActivityResultRegistry


IDEA FROM
https://stackoverflow.com/questions/64721218/jetpack-compose-launch-activityresultcontract-request-from-composable-function

Composable Activity Result:

remember a mutableStateOf and update its value to newValue on each recomposition of the rememberUpdatedState call.

rememberUpdatedState should be used when parameters or values computed during composition are referenced by a long-lived lambda or object expression. Recomposition will update the resulting State without recreating the long-lived lambda or object, allowing that object to persist without cancelling and resubscribing, or relaunching a long-lived operation that may be expensive or prohibitive to recreate and restart. This may be common when working with DisposableEffect or LaunchedEffect, for example:

https://developer.android.com/reference/kotlin/androidx/compose/runtime/package-summary#rememberupdatedstate


A side effect of composition that must run for any new unique value of subject and must be reversed or cleaned up if subject changes or if the DisposableEffect leaves the composition.

A DisposableEffect's subject is a value that defines the identity of the DisposableEffect. If a subject changes, the DisposableEffect must dispose its current effect and reset by calling effect again. Examples of subjects include:

Observable objects that the effect subscribes to
Unique request parameters to an operation that must cancel and retry if those parameters change
DisposableEffect may be used to initialize or subscribe to a subject and reinitialize when a different subject is provided, performing cleanup for the old operation before initializing the new. For example:

A DisposableEffect must include an onDispose clause as the final statement in its effect block. If your operation does not require disposal it might be a SideEffect instead, or a LaunchedEffect if it launches a coroutine that should be managed by the composition.

There is guaranteed to be one call to dispose for every call to effect. Both effect and dispose will always be run on the composition's apply dispatcher and appliers are never run concurrent with themselves, one another, applying changes to the composition tree, or running CompositionLifecycleObserver event callbacks.

https://developer.android.com/reference/kotlin/androidx/compose/runtime/package-summary#disposableeffect_1

It behaves similarly to remember, but the stored value will survive the activity or process recreation using the saved instance state mechanism (for example it happens when the screen is rotated in the Android application).

https://developer.android.com/reference/kotlin/androidx/compose/runtime/savedinstancestate/package-summary#rememberSavedInstanceState(kotlin.Any,%20androidx.compose.runtime.savedinstancestate.Saver,%20kotlin.String,%20kotlin.Function0)

Screen Code:

```kotlin
@Composable
fun HomeContent() {

    val context = AmbientContext.current

    val createFileAction =
        registerForActivityResult(ActivityResultContracts.CreateDocument()) { createFileURI ->
            // Do something with your URI, for example saving it with
            // context.contentResolver.openOutputStream(uri)!!.use { }
            val url = "${createFileURI.scheme}:${createFileURI.schemeSpecificPart}"
            Toast.makeText(context, "Save File url: $url", Toast.LENGTH_SHORT).show()
        }

    val openFileAction =
        registerForActivityResult(ActivityResultContracts.OpenDocument()) { openFileURI ->
            // Do something with your URI, set to state or process it for example with
            //  context.contentResolver.openInputStream(uri)?.use { }
            val url = "${openFileURI.scheme}:${openFileURI.schemeSpecificPart}"
            Toast.makeText(context, "Open File url: $url", Toast.LENGTH_SHORT).show()
        }

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier.fillMaxSize()
    ) {
        Column {
            Button(
                modifier = Modifier.padding(8.dp),
                onClick = {
                    // Use the type that you want to open or use *
                    openFileAction.launch(arrayOf("image/*"))
                }
            ) {
                Text("Open File")
            }
            Button(
                modifier = Modifier.padding(8.dp),
                onClick = {
                    createFileAction.launch("filename.txt")
                }
            ) {
                Text("Save file")
            }
        }
    }
}
```

CreateDocument contract just for reference. Maybe link the official doc
```kotlin
    public static class CreateDocument extends ActivityResultContract<String, Uri> {

        @CallSuper
        @NonNull
        @Override
        public Intent createIntent(@NonNull Context context, @NonNull String input) {
            return new Intent(Intent.ACTION_CREATE_DOCUMENT)
                    .setType("*/*")
                    .putExtra(Intent.EXTRA_TITLE, input);
        }

        @Nullable
        @Override
        public final SynchronousResult<Uri> getSynchronousResult(@NonNull Context context,
                @NonNull String input) {
            return null;
        }

        @Nullable
        @Override
        public final Uri parseResult(int resultCode, @Nullable Intent intent) {
            if (intent == null || resultCode != Activity.RESULT_OK) return null;
            return intent.getData();
        }
    }
}

```

Open Document contract just for referece. Maybe link the official doc
```kotlin
@TargetApi(19)
    public static class OpenDocument extends ActivityResultContract<String[], Uri> {

        @CallSuper
        @NonNull
        @Override
        public Intent createIntent(@NonNull Context context, @NonNull String[] input) {
            return new Intent(Intent.ACTION_OPEN_DOCUMENT)
                    .putExtra(Intent.EXTRA_MIME_TYPES, input)
                    .setType("*/*");
        }

        @Nullable
        @Override
        public final SynchronousResult<Uri> getSynchronousResult(@NonNull Context context,
                @NonNull String[] input) {
            return null;
        }

        @Nullable
        @Override
        public final Uri parseResult(int resultCode, @Nullable Intent intent) {
            if (intent == null || resultCode != Activity.RESULT_OK) return null;
            return intent.getData();
        }
    }
```

For starting an activity for result
```kotlin
 val notificationAccessActivityAction =
        registerForActivityResult(contract = ActivityResultContracts.StartActivityForResult()) {
            notificationAccessState = isNotificationAccessAllowed(context)
            viewModel.showLoading = false
        }
```

Sample

https://github.com/prof18/open-save-file-compose-sample

In action on MoneyFlow:

https://github.com/prof18/MoneyFlow/blob/develop/androidApp/src/main/java/com/prof18/moneyflow/features/settings/SettingsScreen.kt