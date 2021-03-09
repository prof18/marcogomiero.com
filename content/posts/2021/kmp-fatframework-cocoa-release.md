---
layout: post
title:  "Introducing KMP FatFramework Cocoa, a Gradle plugin for iOS FatFramework"
date:   2021-03-02
show_in_homepage: false 
tags: [Kotlin Multiplatform]
---

Today I want to share [**KMP FatFramework Cocoa**](https://github.com/prof18/kmp-fatframework-cocoa), a Gradle plugin for Kotlin Multiplatform projects that generate a FatFramework for iOS targets and manages the publishing process in a CocoaPod Repository. 

The plugin is born from a set of unbundled Gradle tasks that I wrote to manage the building and the publishing process of Kotlin Multiplatform libraries for iOS that we use at [Uniwhere](https://www.uniwhere.com/) and [Revelop](https://revelop.app/). The libraries are published in a **FatFramework** that contains the code for every required architecture (real devices use the *Arm64* architecture, while the simulator uses the host computer architecture which in most of the cases is *X64*).

After copying and pasting the task between different projects, I thought that having them bundled into a Gradle plugin, would be a good idea. 

## Features

The plugin is composed of a bunch of tasks that let you build the FatFramework with the `Debug` or `Release` target, publish both the versions to a CocoaPod repository, and also create the repository. 

The task that publishes the debug version of the FatFramework will use the `develop` branch of the CocoaPod repository, while the task for the release version will use the `main` (or `master`) branch and it will also tag the release with the provided version number. In this way, in the iOS project you can get the latest changes published on the develop branch:

```ruby
pod '<your-library-name>', :git => "git@github.com:<git-username>/<repo-name>.git", :branch => 'develop'
```
  
or specify a tag to get the release version:

```ruby
pod '<your-library-name>', :git => "git@github.com:<git-username>/<repo-name>.git", :tag => '<version-number>'
```
  
For all the details about the tasks and the required configurations, you can give a look at the documentation on the [GitHub repo](https://github.com/prof18/kmp-fatframework-cocoa). 
Instead, if you are interested in the internals of the tasks, I’ve recently written [an article about the topic](https://www.marcogomiero.com/posts/2021/kmp-existing-project/).

This is my first Gradle plugin and I’ve learned a lot during the process. If you notice a bug or something strange, feel free to [report it on GitHub](https://github.com/prof18/kmp-fatframework-cocoa/issues) or to contribute (contributions are always appreciated). 

And, if you have any suggestion or any kind of doubt, feel free to reach me out on Twitter [@marcoGomier](https://twitter.com/marcoGomier). or specify a tag to get the release version: