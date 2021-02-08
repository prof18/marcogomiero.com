Not going to explain to how to publish, you can follow this guide

Publishing Android libraries to MavenCentral in 2021 - Márton Braun

https://getstream.io/blog/publishing-libraries-to-mavencentral-2021/


Go to the bintray directory

For example: https://bintray.com/package/files/prof18/maven/RSS-Parser

https://bintray.com/package/files/{your-bintray-username}/maven/{your-library-name}

fro here you can download the old artifacts

after downloading the artifacts, you need to manually sign all the artifacts with the command

```bash
 gpg -ab rssparser-1.0.pom
```

In the staging upload section you can manually upload the artifacts already signed.

Add the pom. Then in the bottom add all the artifacts and the end upload them. 
Remember to add also the signature with the asc extension.
Remember also to upload here the signature of the pom.

Then after uploading, the automatic close task is started and you need to wait the end.

After the end, you can release the library.






