---
layout: post
title:  "How to fix the \"Unable to locate a Java Runtime\" error on Xcode with Kotlin Multiplatform"
date:   2021-12-27
show_in_homepage: false
image: "/img/xcode-jvm-runtime/xcode-java-runtime.jpeg"
---

{{< rawhtml >}}

<div id="banner" style="overflow: hidden;justify-content:space-around;">

    <div style="display: inline-block;margin-right: 10px;">
        <a href="https://androidweekly.net/issues/issue-499"><img style="margin: 0px;" src="https://androidweekly.net/issues/issue-499/badge" /></a>
    </div>
</div>

{{< /rawhtml >}}

A couple of days ago I opened my Kotlin Multiplatform pet project [MoneyFlow](https://github.com/prof18/MoneyFlow) on a different machine than usual. When I tried to run the app on the iOS simulator on Xcode, the build failed with a very strange error: "The operation couldn't be completed. Unable to locate a Java Runtime".

{{< figure src="/img/xcode-jvm-runtime/xcode-java-runtime.jpeg" link="/img/xcode-jvm-runtime/xcode-java-runtime.jpeg" >}}

This was a very strange issue because the JDK is installed and everything is working on the command line and Android Studio/IntelliJ. 

After doing some research, I found out in [a comment of a Youtrack issue](https://youtrack.jetbrains.com/issue/KT-50474#focus=Comments-27-5673712.0-0) that Xcode is taking the JDK version from  `/usr/libexec/java_home`. So I tried to run  `/usr/libexec/java_home` in the command line and I got the same error: `The operation couldn’t be completed. Unable to locate a Java Runtime.` Still strange.

I usually install the JDK manually with Homebrew, but for this time I decided to give [`sdkman`](https://sdkman.io/usage) a try. And that was the problem because `sdkman` “doesn’t expose” the JDK version to `/usr/libexec/java_home`. 

So I went back to the old and good manual way. Since the AdoptOpenJDK tap [is deprecated](https://github.com/AdoptOpenJDK/homebrew-openjdk#-deprecation-notice-), I tried the [Temurin one](https://formulae.brew.sh/cask/temurin) and installed Java 11 and Java 8.

```bash
brew tap homebrew/cask-versions

brew install --cask temurin8

brew install --cask temurin11
```

Then I adapted a couple of alias (to add on `.zshrc` or `.bash_profile` file) that I found out [in this article](https://www.yippeecode.com/topics/upgrade-to-openjdk-temurin-using-homebrew/) to help me switch easily between Java 11 and Java 8, whenever I need. 

```bash
export JAVA_11_HOME=/Library/Java/JavaVirtualMachines/temurin-11.jdk/Contents/Home
export JAVA_8_HOME=/Library/Java/JavaVirtualMachines/temurin-8.jdk/Contents/Home

alias java11="export JAVA_HOME=$JAVA_11_HOME"
alias java8="export JAVA_HOME=$JAVA_8_HOME"

# Set default to Java 11
java11
```

And with the manual installation, the build started working again! 

---

Another solution, suggested by [Martin Bonnin](https://twitter.com/martinbonnin) is to explicitly set the `JAVA_HOME` inside the plist files under `~/Library/LaunchAgents/`

{{< tweet 1474851964521525249 >}}

