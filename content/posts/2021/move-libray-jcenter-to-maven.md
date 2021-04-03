---
layout: post
title:  "Migrating old artifacts from JCenter to MavenCentral"
date:   2021-02-11
show_in_homepage: false 
---

As you may have heard, JCenter is shutting down in May 2021.

> Into the Sunset on May 1st: Bintray, JCenter, GoCenter, and ChartCenter  
> https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/

So, if you are using JCenter as the repository for your libraries (as me), it’s time to migrate. 

In this article, I will not go through the publishing process of a library to MavenCentral, because there are already plenty of resources available. For example, I followed the one written by Márton Braun.

> Publishing Android libraries to MavenCentral in 2021
> https://getstream.io/blog/publishing-libraries-to-mavencentral-2021/

Instead, the topic of this article is to show how to manually migrate the old artifacts of a library without recompiling them. 

It’s important to migrate also the old artifacts because not all the users of your library are using the latest version. But if the library is old, it’s difficult to recompile it from scratch. For example, I’ve tried to manually rebuild the first version of [YoutubeParser](https://github.com/prof18/YoutubeParser), but I quickly failed because it was using a version of the Android Gradle Plugin of 5 years ago that is now incompatible with Android Studio 4. 

## Download old artifacts from Bintray 

The first thing to do is downloading the old library’s artifacts from Bintray. It is possible to download them, directly from the Bintray directory page:

> https://bintray.com/package/files/{your-bintray-username}/maven/{your-library-name}

For example, this is the URL for my other library, [RSS-Parser](https://github.com/prof18/RSS-Parser): https://bintray.com/package/files/prof18/maven/RSS-Parser

{{< figure src="/img/move-libray-jcenter-to-maven/bintray-dir.png" link="/img/move-libray-jcenter-to-maven/bintray-dir.png" >}}

Here, it is possible to download the artifacts by simply clicking on them.

## Sign artifacts

The next step is signing the artifacts, with a GPG key (to generate one, you can follow the instruction on [Márton‘s article](https://getstream.io/blog/publishing-libraries-to-mavencentral-2021/)). The command to perform the signing is the following:

```bash
 gpg -ab rssparser-1.0.pom
```

{{< figure src="/img/move-libray-jcenter-to-maven/sign-terminal.png" link="/img/move-libray-jcenter-to-maven/sign-terminal.png" >}}

Remember that all the files uploaded to MavenCentral must be signed. In my case, I have to sign the *.aar* file, the *.pom* and the *jar* that contains the sources and the *JavaDoc* of the library.

The signing command produces a *.asc* file, that must be uploaded as well on MavenCentral. 

{{< figure src="/img/move-libray-jcenter-to-maven/signed-files.png" link="/img/move-libray-jcenter-to-maven/signed-files.png" >}}

## Manual upload artifacts 

Now, it’s time to upload the artifacts. Login on [Sonatype](https://oss.sonatype.org/) and from the menu on the left, select *Staging Upload*

{{< figure src="/img/move-libray-jcenter-to-maven/manual-upload.png" link="/img/move-libray-jcenter-to-maven/manual-upload.png" >}}

First of all, in the *Staging Upload* section, it is necessary to upload the *pom* file.

Switch the upload mode to *Artifact(s) with a pom* in the dropdown window and then select to *pom* to upload.

{{< figure src="/img/move-libray-jcenter-to-maven/add-pom.png" link="/img/move-libray-jcenter-to-maven/add-pom.png" >}}

Then, in the section below, it is possible to upload the other artifacts. To do that, it is necessary to select them from the file system with the *Select Artifact(s) to Upload...* button and then add them to the list with the *Add Artifact* button.

{{< figure src="/img/move-libray-jcenter-to-maven/artifacts-to-upload.png" link="/img/move-libray-jcenter-to-maven/artifacts-to-upload.png" >}}

Don’t forget to upload also the signatures (the *.asc* files)!

After adding all the artifacts, upload them with the *Upload Artifact(s)* button. It is also necessary to provide a brief description, for example `1.1 manual upload`
 
{{< figure src="/img/move-libray-jcenter-to-maven/add-artifacts.png" link="/img/move-libray-jcenter-to-maven/add-artifacts.png" >}}

It could happen the the upload is stuck and the progress bar never goes away. If it happens, reload the page and redo the process (I’ve noticed that it can happen when the browser tab is open for a while).

After the upload is successful, select *Staging Repositories* from the left menu. 

{{< figure src="/img/move-libray-jcenter-to-maven/staging-repo.png" link="/img/move-libray-jcenter-to-maven/staging-repo.png" >}}

Now, the process is the same as when the artifacts are upload from Android Studio (or from the CI). The only exception is that the close task is started automatically (if it not starts, you can start it manually from the top bar). 

{{< figure src="/img/move-libray-jcenter-to-maven/wait-close.png" link="/img/move-libray-jcenter-to-maven/wait-close.png" >}}

The close task takes a few moments to perform, and after that, it’s time to release the library with the button in the toolbar.  

And that’s it! After the processing time (usually between 10 to 15 minutes) your library will be available to [MavenCentral](https://repo1.maven.org/maven2/).

