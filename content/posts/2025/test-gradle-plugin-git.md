---
layout: post
title:  "Testing a Gradle Plugin that interacts with Git"
date:   2025-05-13
show_in_homepage: false
---

Some time ago, I built [KMP Framework Bundler](https://github.com/prof18/kmp-framework-bundler), a Gradle plugin for Kotlin Multiplatform projects that generates an XCFramework for Apple targets or a FatFramework for iOS targets and manages the publishing process to a CocoaPods repository. (Note: the plugin is currently in maintenance mode; using [KMMBridge](https://touchlab.co/kmmbridge/) might be a better option.)

After building the Framework, the plugin handles the publishing process by interacting with a Git-based CocoaPods repository. It copies the Framework into the repository, updates the podspec file with the latest version, commits the changes, and pushes them.

Here’s a simplified example of what the plugin does:

```kotlin
copy {
	from("$buildDir/XCFrameworks/debug")
	into("$rootDir/../kmp-xcframework-dest")
}

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

More details about KMP Framework Bundler are available [in a previous article](https://www.marcogomiero.com/posts/2021/kmp-xcframework-official-support#publish-an-xcframework).

## Automated testing

Before every release, I manually tested the entire publishing process. This involved setting up a simple local Kotlin Multiplatform project, configuring local and remote CocoaPods repositories, running the plugin, and verifying that everything worked correctly.

This manual process was time-consuming, so I started exploring [Gradle TestKit](https://docs.gradle.org/current/userguide/test_kit.html) to automate it. Gradle TestKit allows you to programmatically execute Gradle builds and inspect the results.

However, testing Gradle plugins that interact with Git can be tricky, especially when they involve committing changes and pushing to remote repositories. In this article, I’ll show how I was able to test my plugin using Gradle TestKit and Git bare repositories, eliminating the need for manual testing and actual remote repositories.

## Testing project structure

With GradleTestKit, it’s possible to create a test project inside the test resources and run the plugin on it:


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


To test the publishing process, both local and remote Git repositories are needed. Using an actual remote repository would be unreliable and hard to maintain, so the tests create a local **bare** repository to simulate the remote.

A Git bare repository is a special type of repository that doesn't have a working directory. It contains only the Git database (i.e., the contents of the .git folder) without any checked-out files.

In contrast, a regular Git repository created with `git init` includes both the Git database and a working directory. A bare repository, created with `git init --bare`, contains only the database, making it ideal for simulating a remote server in tests.


## Testing infrastructure

A base class sets up the testing environment, so the test classes can focus on assertions. Here's the whole class, which we'll break down below:

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

The first step involves accessing the test project and backing up its `build.gradle.kts` file to restore it when the test is done quickly.

```kotlin
testProject = File("src/test/resources/test-project")
buildGradleFile = File("src/test/resources/test-project/build.gradle.kts")
tempBuildGradleFile = File("src/test/resources/test-project/build.gradle.kts.new")
buildGradleFile.copyTo(tempBuildGradleFile)
```

### 2. Creating Local and remote directories

Two folders are created:

* `testDestFolder`: acts as the local repository where the Framework is published.
* `remoteDestFolder`: a bare repository that simulates the remote server.

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

This is where the magic happens! A bare Git repository is created in the remote destination folder. This repository will act as a "remote" server without requiring network access.

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

With the setup complete, the publishing pipeline can be fully tested:

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

By combining Gradle TestKit with a Git bare repository, I could fully automate testing for the KMP Framework Bundler plugin, including the entire publishing workflow. This approach eliminates the need to set up complex local environments.

This pattern can easily be adapted for testing other plugins that interact with version control, providing a reliable and automated way to ensure correctness in real-world scenarios.
