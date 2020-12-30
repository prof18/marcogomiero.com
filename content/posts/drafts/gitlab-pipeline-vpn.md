---
layout: post
title:  "Connect to Open VPN during Gitlab Pipeline"
date:   2020-12-29
show_in_homepage: false 
draft: true
---

Gitlab CI/CD offers the possibility to create a pipeline, which runs when something changes in the repository. A pipeline consist of one or more stages that run in order and in these stages, for example, it is possible to build the project, run the tests, create the artifacts, etc. For more information about Gitlab CI/CD, I suggest you look over the [documentation](https://docs.gitlab.com/ee/ci/).

These out-of-the-box solutions really simplify the work to be done to have a CI up and running. For example, this is the configuration file (a file called `.gitlab-ci.yml` placed at the repository’s root) needed for running all the tests of a Kotlin project.

```yaml
image: openjdk:11-jdk

cache:
  key: ${CI_PROJECT_ID}
  paths:
    - .gradle/

before_script:
  - export GRADLE_USER_HOME=$(pwd)/.gradle
  - chmod +x ./gradlew

stages:
  - test

test:
  stage: test
  script:
    - ./gradlew test --info --stacktrace
```

But, let’s assume that the project is using some libraries that are published on a private Maven repository behind a VPN. The pipeline will fail because it can’t download the dependencies.

To connect to a VPN, it is necessary to do some tweaks before starting the stages of the pipeline. And it is possible to do it by writing the commands inside the `before_script:` phase. 

For this example, I will use OpenVPN but the script can adapted for whatever type of VPN.

Before writing any code, it is necessary to write some secret variables (the menu is available under Settings > CI/CD > Variables - [here](https://docs.gitlab.com/ee/ci/variables/README.html#create-a-custom-variable-in-the-ui) for more info). 
Three variables are necessary:
- CLIENT_OVPN -> the content of the .ovpn file
- VPN_USER -> the VPN user
- VPN_PWD -> the VPN password

First of all, some dependencies are needed 

```yaml
before_script:
  ...
  ## VPN
  - echo "Setup Open VPN"
  - which openvpn || (apt-get update -y -qq && apt-get install -y -qq openvpn && apt-get install -y -qq iputils-ping)
```

Then the secrets need to be loaded:

```yaml
before_script:
  ...
  - cat <<< $CLIENT_OVPN > /etc/openvpn/client.ovpn
  - cat <<< $VPN_USER > /etc/openvpn/cred.txt
  - cat <<< $VPN_PWD >> /etc/openvpn/cred.txt # append at the bottom
```

Now, the connection can be performed:

```yaml
before_script:
  ...
  - openvpn --config /etc/openvpn/client.ovpn --auth-user-pass /etc/openvpn/cred.txt --daemon
```

To check that everything is ok I make a 30 seconds sleep (yes, it’s brutal but it works) and then I ping the server:

```yaml
before_script:
  ...
  - sleep 30s
  - ping -c 1 <your-ip>
```

And that’s it! Now the pipeline can download all the dependencies, even the ones under VPN.

For reference, here’s the complete `.gitlab-ci.yml` file:

```yaml
image: openjdk:11-jdk

cache:
  key: ${CI_PROJECT_ID}
  paths:
    - .gradle/

before_script:
  - export GRADLE_USER_HOME=$(pwd)/.gradle
  - chmod +x ./gradlew
  ## VPN
  - echo "Setup Open VPN"
  - which openvpn || (apt-get update -y -qq && apt-get install -y -qq openvpn && apt-get install -y -qq iputils-ping)
  - cat <<< $CLIENT_OVPN > /etc/openvpn/client.ovpn
  - cat <<< $VPN_USER > /etc/openvpn/cred.txt
  - cat <<< $VPN_PWD >> /etc/openvpn/cred.txt 
  - openvpn --config /etc/openvpn/client.ovpn --auth-user-pass /etc/openvpn/cred.txt --daemon
  - sleep 30s
  - ping -c 1 <your-ip>

stages:
  - test

test:
  stage: test
  script:
    - ./gradlew test --info --stacktrace
```

If you have any kind of suggestion or doubt, feel free to reach me out on Twitter [@marcoGomier](https://twitter.com/marcoGomier).

