---
layout: post
title:  "How to open and save files on Jetpack Compose"
date:   2021-01-24
show_in_homepage: false 
draft: true
tags: [Android, Jetpack Compose]
---

IDEA FROM
https://stackoverflow.com/questions/64721218/jetpack-compose-launch-activityresultcontract-request-from-composable-function

Composable Activity Result:

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