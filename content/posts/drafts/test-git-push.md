---
layout: post
title:  "TODO Test Git pushing Gradle plugin"
date:   2023-09-20
show_in_homepage: false
draft: true
---

---

Some time ago, I built KMP Framework Bundler, a Gradle plugin for Kotlin Multiplatform projects that generates a XCFramework for Apple targets or a FatFramework for iOS targets, and manages the publishing process in a CocoaPod repository.

After building the framework, the plugin takes care (with a Gradle task) of the publication process in a CocoaPods repository through git. It copies the framework in the repository, automatically updates the podspec file with the latest version, commits and pushes all the new changes.

Here’s a simplified example of what the plugin is doing, to better understand the topic of the article:

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

More details are available [in my previous article](https://www.marcogomiero.com/posts/2021/kmp-xcframework-official-support#publish-an-xcframework).

## Automated testing

Before every release, I was manually testing all the publication processes. This includes setting up a simple local Kotlin Multiplatform project and a local and remote CocoaPods repository that hosts the Framework, running the plugin and checking that everything is working as expected.
 
All this manual process required a lot of effort for every release. To avoid that, I decided to start looking into Gradle TestKit, to write automated tests. Gradle TestKit allows to programmatically executing Gradle builds and inspecting the result.

More information can be found [in the documentation](https://docs.gradle.org/current/userguide/test_kit.html).



### Testing project structure

// TODO: add a graph about the usual scenario. A repository with KMP where the plugin is applied. One repository that will be the destination

```bash
.
├── kmp-framework-bundler
│   └── src
│       ├── main
│       └── test
├── kmp-framework-bundler-test-project
│   └── src
│       ├── androidMain
│       ├── commonMain
│       ├── iosMain
│       ├── macOsMain
└── xcframework-cocoa-repo-test
    ├── LibraryName.podspec
    ├── LibraryName.xcframework
    └── README.md
```

// TODO: show the situation replicated on the test scenario

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
                            └── kotlin
                                └── com
                                    └── prof18
                                        └── example
                                            └── Greeting.kt
```

just talk about the test project without going into details of the configuration

## Automating Testing for Consistency



In the test you can create a test project that next gradle will use as the gradle proejct where the plugin will be added. 

To make the push work, some initial setup is required in the folder for the cocoa repository (testDestFolder in the code). It's the classc work for setting up a git repository

This includes initializing a Git repository in the folder designated for the CocoaPods repository (referred to as testDestFolder in the code). The setup process is straightforward, mirroring classic Git repository initialization steps.

```bash

$ git init
$ git branch -m main
$ git add .
$ git commit -m "First commit"

```

then another git repository needs to be setup. this repository will act as the remote one. 

A secondary repository is then set up as a remote repository, using the --bare flag. This creates a storage-only repository, ideal for pushing and pulling branches but not for direct commits.

```bash

$ git init --bare

```

```
The --bare flag creates a repository that doesn’t have a working directory, making it impossible to edit files and commit changes in that repository. You would create a bare repository to git push and git pull from, but never directly commit to it. Central repositories should always be created as bare repositories because pushing branches to a non-bare repository has the potential to overwrite changes. Think of --bare as a way to mark a repository as a storage facility, as opposed to a development environment. This means that for virtually all Git workflows, the central repository is bare, and developers local repositories are non-bare.

From https://www.atlassian.com/git/tutorials/setting-up-a-repository/git-init
```

Then add on the test cocoapod repo the newone created as a remote repository (remoteDestFolder in the code). And we can push to it

```bash
$ git remote add origin remoteRepoPath
$ git push origin --all
```

This is the code to setup the test with waht described above


```kotlin
testDestFolder.runBashCommand("git", "init")
testDestFolder.runBashCommand("git", "branch", "-m", "main")

podSpecFile = File("${testDestFolder.path}/LibraryName.podspec")
podSpecFile.writeText(getPodSpec())

testDestFolder.runBashCommand("git", "add", ".")
testDestFolder.runBashCommand("git", "commit", "-m", "\"First commit\"")

remoteDestFolder.runBashCommand("git", "init", "--bare")

testDestFolder.runBashCommand("git", "remote", "add", "origin", remoteDestFolder.path)
testDestFolder.runBashCommand("git", "push", "origin", "--all")

testDestFolder.runBashCommand("git", "checkout", "-b", "develop")
```

This is the complete setup code for reference


```kotlin

abstract class BasePublishTest(
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

        testDestFolder.runBashCommand("git", "init")
        testDestFolder.runBashCommand("git", "branch", "-m", "main")

        podSpecFile = File("${testDestFolder.path}/LibraryName.podspec")
        podSpecFile.writeText(getPodSpec())

        testDestFolder.runBashCommand("git", "add", ".")
        testDestFolder.runBashCommand("git", "commit", "-m", "\"First commit\"")

        remoteDestFolder.runBashCommand("git", "init", "--bare")

        testDestFolder.runBashCommand("git", "remote", "add", "origin", remoteDestFolder.path)
        testDestFolder.runBashCommand("git", "push", "origin", "--all")

        testDestFolder.runBashCommand("git", "checkout", "-b", "develop")
    }

    @After
    fun cleanUp() {
        buildGradleFile.deleteRecursively()
        tempBuildGradleFile.renameTo(buildGradleFile)
        testDestFolder.deleteRecursively()
        remoteDestFolder.deleteRecursively()
        File("${testProject.path}/build").deleteRecursively()
    }

    private fun getGradleFile(): String = when (frameworkType) {
        FrameworkType.FAT_FRAMEWORK -> fatFrameworkGradleFile
        FrameworkType.XC_FRAMEWORK_LEGACY_BUILD -> legacyXCFrameworkGradleFile
        FrameworkType.XC_FRAMEWORK -> xcFrameworkGradleFile
    }

    private fun getPodSpec(): String = when (frameworkType) {
        FrameworkType.XC_FRAMEWORK, FrameworkType.XC_FRAMEWORK_LEGACY_BUILD -> xcFrameworkPodSpec
        FrameworkType.FAT_FRAMEWORK -> fatFrameworkPodSpec
    }
}


```

After thet setup, we can run tests that tests all the publishing process


```kotlin

class XCFrameworkTasksPublishTests : BasePublishTest(frameworkType = FrameworkType.XC_FRAMEWORK) {

    @Test
    fun `When running the publish debug fat framework task, in the destination, the version number is updated in the pod spec, the branch is develop and the commit message is correct`() {
        testProject.buildAndRun(PublishDebugXCFrameworkTask.NAME)

        // version on pod spec
        assertTrue(podSpecFile.getPlainText().contains(POD_SPEC_VERSION_NUMBER))

        // branch name
        val branchOutput = testDestFolder.runBashCommandAndGetOutput("git", "branch", "--list", "develop")
        assertTrue(branchOutput.contains("develop"))

        // commit message
        val commitOutput = testDestFolder.runBashCommandAndGetOutput("git", "log", "-1")
        assertTrue(commitOutput.contains("New debug release: $FRAMEWORK_VERSION_NUMBER -"))
    }

    @Test
    fun `When running the publish release fat framework task, in the destination, the version number is updated in the pod spec, the branch is main, the commit message and the git tag are correct`() {
        testProject.buildAndRun(PublishReleaseXCFrameworkTask.NAME)

        // version on pod spec
        assertTrue(podSpecFile.getPlainText().contains(POD_SPEC_VERSION_NUMBER))

        // branch name
        val branchOutput = testDestFolder.runBashCommandAndGetOutput("git", "branch", "--list", "main")
        assertTrue(branchOutput.contains("main"))

        // commit message
        val commitOutput = testDestFolder.runBashCommandAndGetOutput("git", "log", "-1")
        assertTrue(commitOutput.contains("New release: $FRAMEWORK_VERSION_NUMBER -"))

        // git tag
        val tagOutput = testDestFolder.runBashCommandAndGetOutput("git", "tag")
        assertTrue(tagOutput.contains(FRAMEWORK_VERSION_NUMBER))
    }
    
    fun File.buildAndRun(vararg commands: String): BuildResult = 
        GradleRunner.create()
            .withProjectDir(this)
            .withArguments(*commands, "--stacktrace")
            .forwardOutput()
            .build()


    fun File.runBashCommandAndGetOutput(vararg arguments: String): String {
        val pb = ProcessBuilder(*arguments).directory(this)
        val process = pb.start()

        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val builder = StringBuilder()
        var line: String?
        while (reader.readLine().also { line = it } != null) {
            builder.append(line)
            builder.append(System.lineSeparator())
        }
        return builder.toString()
    }


}
```

https://github.com/prof18/kmp-framework-bundler

https://github.com/prof18/kmp-framework-bundler/blob/main/src/test/kotlin/com/prof18/kmpframeworkbundler/testutils/BasePublishTest.kt

