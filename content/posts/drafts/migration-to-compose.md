---
layout: post
title:  “Migrating to Jetpack Compose: a step by step journey"
date:   2022-04-25
show_in_homepage: false
draft: true
---

A couple of months ago, I decided to migrate [Secure QR Reader](https://github.com/prof18/Secure-QR-Reader) to Jetpack Compose. QR Reader Secure is a simple QR Reader that I’ve developed some years ago after a failed search for a simple and secure reader for my parents that doesn’t require sneaky, strange and useless permissions.

The app was pretty basic and fully working with the old View system, but I wanted to move to Compose to experience the entire migration process. 

This article will be a sort of journal that describes step by step the journey to Compose. For each step, there will be the correspondent commit, so it will be possible to keep track of the changes. This way, I want to be helpful to all the people that want to star the migration. 

## Gradle Setup

In every big migration there will always be some Gradle work involved. First of all, it is necessary to enable the Compose feature and set the Compose Compiler Kotlin version in the `build.gradle(.kts)` file

```kotlin
android {
    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "<compiler-version>"
    }
}
```

The Compose Compiler version is tied to the Kotlin version. A compatibility map to help the choice, can be found [on the documentation](https://developer.android.com/jetpack/androidx/releases/compose-kotlin).

The next step is adding some dependencies, depending on the needs of the application. The Compose team recently introduced [the Compose BOM](https://developer.android.com/jetpack/compose/setup#using-the-bom) (Bill of Materials) that links together the stable version of all the different Compose libraries. In this way it’s only necessary to specify the BOM version and the correct library’s version will be pulled.


```kotlin
dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2022.12.00")
    implementation composeBom
    androidTestImplementation composeBom

    // Choose one of the following:
    // Material Design 3
    implementation("androidx.compose.material3:material3")
    // or Material Design 2
    implementation("androidx.compose.material:material")
    // or skip Material Design and build directly on top of foundational components
    implementation("androidx.compose.foundation:foundation")
    // or only import the main APIs for the underlying toolkit systems,
    // such as input and measurement/layout
    implementation("androidx.compose.ui:ui")

    // Android Studio Preview support
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    // UI Tests
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")

    // Optional - Included automatically by material, only add when you need
    // the icons but not the material library (e.g. when using Material3 or a
    // custom design system based on Foundation)
    implementation("androidx.compose.material:material-icons-core")
    // Optional - Add full set of material icons
    implementation("androidx.compose.material:material-icons-extended")
    // Optional - Add window size utils
    implementation("androidx.compose.material3:material3-window-size-class")

    // Optional - Integration with activities
    implementation("androidx.activity:activity-compose:1.5.1")
    // Optional - Integration with ViewModels
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.5.1")
    // Optional - Integration with LiveData
    implementation("androidx.compose.runtime:runtime-livedata")
    // Optional - Integration with RxJava
    implementation("androidx.compose.runtime:runtime-rxjava2")

}
```

> From https://developer.android.com/jetpack/compose/setup#kotlin_1

After this setup, Jetpack Compose is ready to be used. 

> [Commit: “Move to gradle kts. Start integrating Gradle Version Catalog”](https://github.com/prof18/Secure-QR-Reader/commit/078e22a6bbfbb2546f24fbea700213bf0d80decf)

*N.B. The above commit was done before the introduction of the BOM.*

## Reuse existing Theme with Material Theme Adapter 

An existing application already has one or more themes defined in XML. With Compose instead, the theme definition is done with Kotlin code. 

Rewriting the entire theming in Compose before moving on with the migration will be a time consuming process that slows things down. Since a theme is already defined, it would be amazing to have a sort of bridge between the two world and postpone the theme migration. 
And here comes the [Material Theme Adapter](https://google.github.io/accompanist/themeadapter-material/).

After importing the library in the project

```kotlin
dependencies {
	implementation "com.google.accompanist:accompanist-themeadapter-material:<version>"
}
```

a new Material Theme called `MdcTheme` will be created. 

```kotlin
MdcTheme {
	...
}
```

The theme adapter will only work if the Activity/Context theme is extending a Theme.MaterialComponents theme and it will automatically infer colors, typography and shapes. 

For example, all the items defined in the following theme

```xml
<resources>
    <!-- Base application theme. -->
    <style name="AppTheme" parent="Theme.MaterialComponents.DayNight.NoActionBar">
        <!-- Customize your theme here. -->
        <item name="colorPrimary">@color/colorPrimary</item>
        <item name="colorPrimaryVariant">@color/colorPrimaryVariant</item>
        
        <item name="textAppearanceButton">@style/TextAppearance.SecureQRReader.Button</item>

        <item name="shapeAppearanceSmallComponent">@style/AppShapeAppearance.SmallComponent</item>
    </style>

    <style name="TextAppearance.SecureQRReader.Button" parent="TextAppearance.MaterialComponents.Body1">
        <item name="fontFamily">@font/poppins_regular</item>
        <item name="android:textSize">16sp</item>
    </style>

    <style name="AppShapeAppearance.SmallComponent" parent="ShapeAppearance.MaterialComponents.SmallComponent">
        <item name="cornerSize">@dimen/card_corner_radius</item>
        <item name="cornerFamily">rounded</item>
    </style>
</resources>
```
 
can be retrieved from `MaterialTheme.colors`, `MaterialTheme.typography`, and `MaterialTheme.shapes` after applying the `MdcTheme` theme. 

This way, the migration to Compose can start without having  to worry about the theme and without the need of duplicating theme definitions. Theming can be migrated in a later stage after all the other screens.

> [Commit: “Migrate WelcomeActivity to compose”](https://github.com/prof18/Secure-QR-Reader/commit/b9ce72efb497313215ab7e871e51b52d56ab940b)

*N.B. The above commit uses an old version of the material theme adapter artifacts. Now these libraries are deprecated in favor of the new Accompanist Theme Adapter artifacts. For more More details are available in the [migration guide](https://github.com/material-components/material-components-android-compose-theme-adapter#migration).*

## Migrate to Compose while keeping Activity and Fragments

After some housekeeping work, it’s finally time to start writing some Composables. 

Jetpack Compose is fully interoperable with the View system and the degree of migration can be decided depending on the project. It is possible to choose what to write with Compose: a full app, just the content of one Fragment or only an element of the UI. That is made possible by the [Interoperability APIs](https://developer.android.com/jetpack/compose/interop/interop-apis).

This is quite handy expecially in large projects because it enables the migration without having to touch the existing architecture and navigation system. With `ComposeView`, for example, it will be possible to keep an existing fragment and just replace the UI definition from the XML with a composable function. 

```kotlin
class ResultFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {

        val qrResult: String? = arguments?.getString(QR_RESULT)

        return ComposeView(requireContext()).apply {
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
            setContent {
                MdcTheme {
                    ResultScreen(
                        scanResult = qrResult,
                        isUrl = isUrl(qrResult),
                        onOpenButtonClick = { openUrl(qrResult) },
                        onCopyButtonClick = { copyToClipboard(qrResult) },
                        onShareButtonClick = { shareResult(qrResult) },
                        onScanAnotherButtonClick = { performAnotherScan() }
                    )
                }
            }
        }
    }
}
```


```kotlin
@Composable
private fun ResultScreen(
    scanResult: String? = null,
    isUrl: Boolean = false,
    onOpenButtonClick: () -> Unit = {},
    onCopyButtonClick: () -> Unit = {},
    onShareButtonClick: () -> Unit = {},
    onScanAnotherButtonClick: () -> Unit = {},
) {
	...
}
```

This way, the migration will be gradual and faster, not with a big bang approach.   

> [Commit: “Migrate AboutActivity to compose”](https://github.com/prof18/Secure-QR-Reader/commit/bcfbc08478b390f55ac508106931eb0bc034a0b4) 

> [Commit: “Migrate ResultFragment to compose”](https://github.com/prof18/Secure-QR-Reader/commit/ef7477e3faa3ef826ca055d9beea5bddea75c97e)

> [Commit: “Migrate ScanFragment to compose”](https://github.com/prof18/Secure-QR-Reader/commit/be12fd5d23610fea38be0d8ab0143c902afe297c)

## Create to Compose Theme

After migrating every screen to Compose, the next steps are focused on making the app “more Compose”. The first thing that can be addressed is the creation of a Compose theme. This way,  the XML themes definitions can be deleted. 

Compose makes it easy to implement [Material 3](https://developer.android.com/jetpack/compose/designsystems/material3) and [Material 2](https://developer.android.com/jetpack/compose/designsystems/material) themes. 

For this application, I’m still using Material 2. While defining a theme, it’s possible to customize colors, shapes and typography. 

```kotlin
internal object LightAppColors {
    val primary = Color(0XFF1565c0)
    val primaryVariant = Color(0xFF3700B3)
    ...
}

internal object DarkAppColors {
    val primary = Color(0XFF102a43)
    val primaryVariant = Color(0xFF3700B3)
    ...
}

internal val SecureQrReaderShapes = Shapes(
    small = RoundedCornerShape(16.dp),
    medium = RoundedCornerShape(16.dp),
    large = RoundedCornerShape(16.dp)
)

internal val LightThemeColors = lightColors(
    primary = LightAppColors.primary,
    primaryVariant = LightAppColors.primaryVariant,
    ...
)

internal val DarkThemeColors = darkColors(
    primary = DarkAppColors.primary,
    primaryVariant = DarkAppColors.primaryVariant,
    ...
)
```

Those customization will be injected in the definition of the theme.

```kotlin
Composable
internal fun SecureQrReaderTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colors = if (darkTheme) DarkThemeColors else LightThemeColors,
        typography = SecureQrReaderTypography,
        shapes = SecureQrReaderShapes,
        content = content
    )
}
```

At this point, the `Material Theme Adapter` can be removed 

```kotlin
dependencies {
-	 implementation "com.google.accompanist:accompanist-themeadapter-material:<version>"
}
```

and the `MdcTheme` can be replaced with `SecureQrReaderTheme`

```kotlin
private fun AboutScreen() {
-   MdcTheme {
+   SecureQrReaderTheme {
	    // ...
    }
}    
```

> [Commit: “Migrate to compose theme”](https://github.com/prof18/Secure-QR-Reader/commit/ff1b3db643d8fdd4d1a1a84b4c0fac542717effd)

## All-in with Compose




--- 


## Go full compose

- compose navigation
- accompanist permissions
- disposable effects with lifecycle owner and different mindsets
- transparent status bar with accompanist system ui controller.

 
    
> [Commit: “Go full compose”](https://github.com/prof18/Secure-QR-Reader/commit/4692b50b6e8248ebd8e3af860b25e70045cb8f8e)

> [Commit: “Use accompanist system ui controller to change status bar color”](https://github.com/prof18/Secure-QR-Reader/commit/20e22ecd4539375cd025f28c3f95f37b51d32808)

## Bonus: more goodies

- animation with accompanist

> [Commit: “Move to Animated Nav Host”](https://github.com/prof18/Secure-QR-Reader/commit/28628dd051f572f454c68aedbef62590391336a3)

   

- Add horizontal view support

> [Commit: ”Add horizontal orientation support”](https://github.com/prof18/Secure-QR-Reader/commit/2a44136000730a8cba32ef6d91f3b88572433fb8)
   
   
   
## Conclusions
   
   
   Something
   
   
   https://github.com/prof18/Secure-QR-Reader