---
layout: post
title:  "Testing a Gradle Plugin interacting with Git"
date:   2025-03-15
show_in_homepage: false
draft: true
---


Some time ago, I built [KMP Framework Bundler](https://github.com/prof18/kmp-framework-bundler), a Gradle plugin for Kotlin Multiplatform projects that generates an XCFramework for Apple targets or a FatFramework for iOS targets and manages the publishing process in a CocoaPod repository (the plugin is in maintenance mode; using [KMMBridge](https://kmmbridge.touchlab.co/) might be a better idea).

After building the Framework, the plugin takes care (with a Gradle task) of the publication process in a CocoaPods repository through git. It copies the Framework in the repository, automatically updates the podspec file with the latest version, and commits and pushes all the new changes.

Here’s a simplified example of what the plugin is doing to understand the topic of the article better:

```kotlin
copy {
	from("$buildDir/XCFrameworks/debug")
	into("$rootDir/../kmp-xcframework-dest")
}

// Update podspec file
project.exec {
    workingDir = File("$rootDir/../kmp-xcframework-dest")
    commandLine(
        "git",
        "add",
        "."
    ).standardOutput
}

val dateFormatter = SimpleDateFormat("dd/MM/yyyy - HH:mm", Locale.getDefault())
project.exec {
    workingDir = File("$rootDir/../kmp-xcframework-dest")
    commandLine(
        "git",
        "commit",
        "-m",
        "\"New dev release: ${libVersionName}-${dateFormatter.format(Date())}\""
    ).standardOutput
}

project.exec {
    workingDir = File("$rootDir/../kmp-xcframework-dest")
    commandLine("git", "push", "origin", "develop").standardOutput
}
```

More details about KMP Framework Bundler are available [in my previous article](https://www.marcogomiero.com/posts/2021/kmp-xcframework-official-support#publish-an-xcframework).

## Automated testing

Before every release, I manually tested all the publication processes. This included setting up a simple local Kotlin Multiplatform project and a local and remote CocoaPods repository that hosts the Framework, running the plugin, and checking that everything worked as expected.
 
This manual process required a lot of effort for every release. I started looking into Gradle TestKit to write automated tests to avoid that. [Gradle TestKit](https://docs.gradle.org/current/userguide/test_kit.html) allows you to execute Gradle programmatically, build, and inspect the results.

Testing Gradle plugins that interact with Git can be challenging, especially when they must perform operations like committing changes and pushing to remote repositories. This article presents a solution for automated testing of such plugins using Gradle TestKit and Git bare repositories, eliminating the need for manual testing and remote repositories.

## Testing project structure

With GradleTestKit, it’s possible to create a test project inside the testing resources and run the Gradle Plugin in this project.


```bash
.
└── kmp-framework-bundler
    └── src
        ├── main
        └── test
            ├── kotlin
            └── resources
                └── test-project
                    ├── build.gradle.kts
                    ├── gradle.properties
                    ├── settings.gradle
                    └── src
                        └── commonMain
                            └── ...
```


To test the publishing process, local and remote git repositories are required. Using an actual remote git repository during testing would be unreliable and hard to maintain. To overcome this, the tests create a local “bare” git repository.

### Git bare repository

A Git bare repository is a special type of repository that doesn't have a working directory. It only contains the Git database (the `.git` folder contents) without any checked-out files. Bare repositories are typically used as central repositories that developers push to and pull from.

When a normal Git repository is created with `git init`, both the Git database (in the `.git` folder) and a working directory where files can be edited are created. With a bare repository (`git init --bare`), only the Git database is created, making it perfect for simulating a remote repository.

## Testing infrastructure

A base class performs all the testing setup, so the test classes can be cleaner and will have all the infrastructure ready. Here’s the entire class for convenience, before breaking it down step by step

```kotlin
abstract class BasePublishTest(
	// Enum that specifies whether to test FatFramework or XCFramework publishing
    private val frameworkType: FrameworkType,
) {
    lateinit var testDestFolder: File
    lateinit var podSpecFile: File
    lateinit var testProject: File

    private lateinit var buildGradleFile: File
    private lateinit var remoteDestFolder: File
    private lateinit var tempBuildGradleFile: File

    @Before
    fun setup() {
        // Setup test environment
        testProject = File("src/test/resources/test-project")
        buildGradleFile = File("src/test/resources/test-project/build.gradle.kts")
        tempBuildGradleFile = File("src/test/resources/test-project/build.gradle.kts.new")
        buildGradleFile.copyTo(tempBuildGradleFile)

        val currentPath = Paths.get("").toAbsolutePath().toString()
        testDestFolder = File("$currentPath/../test-dest")
        testDestFolder.mkdirs()

        remoteDestFolder = File("$currentPath/../remote-dest")
        remoteDestFolder.mkdirs()

        buildGradleFile.appendText(getGradleFile())

        // Initialize local Git repository
        testDestFolder.runBashCommand("git", "init")
        testDestFolder.runBashCommand("git", "branch", "-m", "main")

        // Create and commit podspec file
        podSpecFile = File("${testDestFolder.path}/LibraryName.podspec")
        podSpecFile.writeText(getPodSpec())

        testDestFolder.runBashCommand("git", "add", ".")
        testDestFolder.runBashCommand("git", "commit", "-m", "\"First commit\"")

        // Initialize bare repository as remote
        remoteDestFolder.runBashCommand("git", "init", "--bare")

        // Connect local repo to remote and push
        testDestFolder.runBashCommand("git", "remote", "add", "origin", remoteDestFolder.path)
        testDestFolder.runBashCommand("git", "push", "origin", "--all")

        // Create develop branch for testing
        testDestFolder.runBashCommand("git", "checkout", "-b", "develop")
    }

    @After
    fun cleanUp() {
        // Clean up test environment
        buildGradleFile.deleteRecursively()
        tempBuildGradleFile.renameTo(buildGradleFile)
        testDestFolder.deleteRecursively()
        remoteDestFolder.deleteRecursively()
        File("${testProject.path}/build").deleteRecursively()
    }

    // Helper methods
    private fun getGradleFile(): String = when (frameworkType) {
        FrameworkType.FAT_FRAMEWORK -> fatFrameworkGradleFile
        FrameworkType.XC_FRAMEWORK -> xcFrameworkGradleFile
    }

    private fun getPodSpec(): String = when (frameworkType) {
        FrameworkType.XC_FRAMEWORK -> xcFrameworkPodSpec
        FrameworkType.FAT_FRAMEWORK -> fatFrameworkPodSpec
    }
}
```

### 1. Setting Up the Test Project

The first step is to access the test project and make a backup of its build file so that it can be quickly restored when the test is done.

```kotlin
testProject = File("src/test/resources/test-project")
buildGradleFile = File("src/test/resources/test-project/build.gradle.kts")
tempBuildGradleFile = File("src/test/resources/test-project/build.gradle.kts.new")
buildGradleFile.copyTo(tempBuildGradleFile)
```

### 2. Creating Local and remote directories

Two directories need to be created: the former (`testDestFolder`) will act as the  local repository where the Framework will be published, while the latter (`remoteDestFolder`) will be the bare repository that simulates a remote server.

```kotlin
val currentPath = Paths.get("").toAbsolutePath().toString()
testDestFolder = File("$currentPath/../test-dest")
testDestFolder.mkdirs()

remoteDestFolder = File("$currentPath/../remote-dest")
remoteDestFolder.mkdirs()
```

### 3. Configuring the build file

The test project provides a `build.gradle.kts` file with a basic setup. The file needs to be customized based on the type of Framework that the test needs to validate:

```kotlin
buildGradleFile.appendText(getGradleFile())
```
### 4. Setting Up the Local Git Repository

A new Git repository is initialized in the test destination folder

```kotlin
testDestFolder.runBashCommand("git", "init")
testDestFolder.runBashCommand("git", "branch", "-m", "main")
```

and a `PodSpec` file is committed to the repository
```kotlin
podSpecFile = File("${testDestFolder.path}/LibraryName.podspec")
podSpecFile.writeText(getPodSpec())

testDestFolder.runBashCommand("git", "add", ".")
testDestFolder.runBashCommand("git", "commit", "-m", "\"First commit\"")
```

### 5. Creating the Bare Repository

This is where the magic happens! A bare Git repository is created in the remote destination folder. This repository will act as a "remote" server without actually requiring network access.

```kotlin
remoteDestFolder.runBashCommand("git", "init", "--bare")
```

After configuring the “remote” repository, the initial content can be pushed

```kotlin
testDestFolder.runBashCommand("git", "remote", "add", "origin", remoteDestFolder.path)
testDestFolder.runBashCommand("git", "push", "origin", "--all")
```

### 6. Creating a Development Branch

The final step is creating a development branch that will be used to test the debug framework publishing.

```kotlin
testDestFolder.runBashCommand("git", "checkout", "-b", "develop")
```

### 7. Cleaning Up After Tests

After running the test, all temporary files and directories are cleaned up, and the original build file is restored.

```kotlin
@After
fun cleanUp() {
    buildGradleFile.deleteRecursively()
    tempBuildGradleFile.renameTo(buildGradleFile)
    testDestFolder.deleteRecursively()
    remoteDestFolder.deleteRecursively()
    File("${testProject.path}/build").deleteRecursively()
}
```

## Testing the plugin

After the setup, the publishing pipeline can be fully tested 

```kotlin

class XCFrameworkTasksPublishTests : BasePublishTest(frameworkType = FrameworkType.XC_FRAMEWORK) {

    @Test
    fun `When running the publish debug fat framework task, in the destination, the version number is updated in the pod spec, the branch is develop and the commit message is correct`() {

		GradleRunner.create()
            .withProjectDir(this)
            .withArguments(PublishDebugXCFrameworkTask.NAME, "--stacktrace")
            .forwardOutput()
            .build()


        // version on pod spec
        assertTrue(podSpecFile.getPlainText().contains(POD_SPEC_VERSION_NUMBER))

        // branch name
        val branchOutput = testDestFolder.runBashCommandAndGetOutput("git", "branch", "--list", "develop")
        assertTrue(branchOutput.contains("develop"))

        // commit message
        val commitOutput = testDestFolder.runBashCommandAndGetOutput("git", "log", "-1")
        assertTrue(commitOutput.contains("New debug release: $FRAMEWORK_VERSION_NUMBER -"))
    }
}
```


> `runBashCommandAndGetOutput` and `runBashCommand` are custom helpers that use Gradle APIs. You can find the implementation [in the project repository](https://github.com/prof18/kmp-framework-bundler/blob/main/src/main/kotlin/com/prof18/kmpframeworkbundler/utils/Utils.kt). 


## Conclusions

By combining Gradle TestKit with a Git bare repository, I could automate and quickly test the KMP Framework Bundler Gradle plugin, including the entire publishing workflow. This allows me to quickly and easily test the plugin without setting up complex scenarios locally.

This pattern can be easily adapted for testing other plugins that interact with version control systems, providing a reliable way to ensure your plugin works correctly in real-world scenarios.