---
layout: post
title:  "How to fix the \"Unable to locate a Java Runtime\" error on Xcode with Kotlin Multiplatform"
date:   2021-12-25
show_in_homepage: false
draft: true
---

{{< tweet 1474798883117092870 >}} -> (This is my tweet figuring out the problem)

"The operation couldn't be completed. Unable to locate a Java Runtime"

{{< figure src="/img/xcode-jvm-runtime/xcode-java-runtime.jpeg" link="/img/xcode-jvm-runtime/xcode-java-runtime.jpeg" >}}


syncFramework task

Everything was working on command line and android studio. But on xcode I got the error

Weird, made some research and found out that Xcode is taking the java version from `/usr/libexec/java_home` -> https://youtrack.jetbrains.com/issue/KT-50474#focus=Comments-27-5673712.0-0

I tried to run `/usr/libexec/java_home` and got `The operation couldn’t be completed. Unable to locate a Java Runtime.`

I used sdk man to setup the java version -> https://sdkman.io/usage

So I tried to install manually the jdk throug Homebrew

Install the OpenJDK with brew and the Temurin tap because the AdoptOpenJDK is deprecated -> https://github.com/AdoptOpenJDK/homebrew-openjdk#-deprecation-notice-

```bash
brew tap homebrew/cask-versions

brew install --cask temurin8

brew install --cask temurin11
```

On `.zshrc` added a couple of alias to jump from java 8 to 11 easily when needed

```bash
export JAVA_11_HOME=$(/usr/libexec/java_home -v 11.0.11)
export JAVA_8_HOME=$(/usr/libexec/java_home -v 1.8.0_242)

alias java11="export JAVA_HOME=$JAVA_11_HOME"
alias java8="export JAVA_HOME=$JAVA_8_HOME"

#set default to Java 11
java11
```

Adapted from: https://www.yippeecode.com/topics/upgrade-to-openjdk-temurin-using-homebrew/

Another solution suggested by Martin Bonnin https://twitter.com/martinbonnin
{{< tweet 1474851964521525249 >}}