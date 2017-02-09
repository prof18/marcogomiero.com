---
layout: post
title:  "How to deal with backup on Android"
date:   2017-01-26
---

<p class="intro" align="justify"><span class="dropcap" >N</span>owadays the frequency of changing smartphone is increased, so it's important to give the user the possibility to transfer their workflow. In fact one of the most annoying thing is losing all data from the favorite app.
</p>

<p align="justify"> Google provides two ways to deal with backup and restore but as we'll see it's not enough for me or better, it's not enough for a backup that covers all possible situations.
</p>

<p align="justify"> The first method is <a href="https://developer.android.com/guide/topics/data/autobackup.html"><b>Auto Backup</b></a> and, as the name suggest, its goal is to make developers' life easier. This feature is available from API 23 and backups app data to the user's Google Drive Account. Every app can upload 25 MB and this space isn't charged from the user quota. All you need to do to enable Auto Backup is setting the following attribute in the application element of the Manifest.
</p>

{% highlight xml %}

<application ...
    android:allowBackup="true">
</app>

{% endhighlight %}

<p align=justify>
Be aware that in applications that target API 23 (Android 6.0) or higher, automatically this attribute is set to true if omitted. For the sake of clarity you should always declare it. By default, Auto Backup will backup most all the file and the directories that are assigned to the app by default. For example:

<ul>
  <li>Shared Preferences Files</li>
  <li>Files in the directory returned by getFilesDir()</li>
  <li>Files in the directory returned by getDatabasePath(String), which also includes files created with the SQLiteOpenHelper class.</li>
  <li>Files in directories created with getDir(String, int)</li>
  <li>Files on external storage in the directory returned by getExternalFilesDir(String). </li>
</ul>



</p>





https://developer.android.com/guide/topics/data/autobackup.html

https://developer.android.com/guide/topics/data/keyvaluebackup.html
