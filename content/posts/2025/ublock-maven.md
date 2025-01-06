---
layout: post
title:  "Don’t let Maven block you!"
date:   2025-01-05
show_in_homepage: false
---

As developers, we've all encountered build failures in CI (or on our local machines) due to Maven repository issues preventing dependency downloads.

```
> Could not download foo-lib-1.0.aar (org.acme.foo:foo-lib:1.0)
   > Could not get resource 'https://mavenrepo.com/org/acme/foo/foo-lib/1.0/foo-lib-1.0.aar'.
      > Could not GET 'https://mavenrepo.com/org/acme/foo/foo-lib/1.0/foo-lib-1.0.aar'. Received status code 403 from server: 
```

There could be many reasons for this: the Maven repository is currently down or is having an incident, the repository has been shut down (hello, JCenter), and the dependency is old and not republished elsewhere.

Usually, the dependencies are cached by Gradle, but the cache can expire.   

If the cache is not on our side, there's another way instead of just waiting for the problem to be fixed: we can create a `Maven Local` repository for the failing dependency inside the project. 

## Create a project-specific Maven Local Repository

A `Maven Local` repository is a simple directory on a local machine's home folder (`~/.m2` on macOS, for example) that stores the dependencies artifacts. 

```
.
└── .m2
    └── repository
        ├── com
        │   └── acme
		│       └── ...        
        └── org
            └── company
 		        └── ...            
```

Such a folder can be placed anywhere, even inside a project. This way, it's possible to create a `Maven local` repository for the `org.acme.foo:foo-lib` library that cannot be downloaded. 

```
~/my-project/.m2
.
└── .m2
    └── repository
        └── com
            └── acme
                └── foo
                    └── foo-lib
                        └── 1.0
                            └── ...
```


However, the library's binary is needed. Otherwise, the repository is useless. The binary can be retrieved inside the Gradle cache, of course where it’s available. In my scenario, the CI failed because the cache expired, but my local environment was still working.

Gradle is caching the binaries of the dependencies in the `.gradle/caches/modules-2/files-2.1` folder. In the case of the`org.acme.foo:foo-lib` library, the binaries will be in the  `.gradle/caches/modules-2/files-2.1/org.acme.foo` folder.

```
.
└── foo-lib
    └── 1.0
       ├── 296c9bacc53c3c2a8a328cd233b43156f0efb9bb
       │   └── foo-lib-1.0.aar
       └── 3095a593f57c0aff8e93596b12e4588fbfa3a7e3
           └── foo-lib-1.0.pom
```

The `.aar` and the `.pom` files can now be moved to the local Maven repository that was created inside the project.

```
~/my-project/.m2
.
└── .m2
    └── repository
        └── com
            └── acme
                └── foo
                    └── foo-lib
                        └── 1.0
                            ├── foo-lib-1.0.aar
                            └── foo-lib-1.0.pom
```

As the last step, Gradle needs to know that he must grab only the library from the local Maven repository, not from the Internet. To do so,  repositories settings in the `settings.gradle.kts` file need to be modified. 

```kotlin
dependencyResolutionManagement {  
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)  
  
    repositories {  
        mavenCentral()  
        google()  
        // Define local Maven repository for specific dependencies
        maven {
	        // Point to the project-specific Maven repository  
            url = uri("file://${rootProject.projectDir}/.m2/repository")  
            content {
                // Only use this repository for the specified dependency  
                includeModule("org.acme.foo", "foo-lib")  
            }  
        }    
    }
}
```

And voilà! The project can still be built with the local version of the missing dependency until it becomes available again.
