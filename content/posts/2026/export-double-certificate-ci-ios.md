---
layout: post
title: "How to import multiple iOS signing certificates to CI"
date: 2026-07-02
show_in_homepage: false
---

Some time ago, I shared the GitHub Actions workflow that I use for deploying the iOS version of [FeedFlow](https://feedflow.dev) to the App Store.

> [How to publish a Kotlin Multiplatform iOS app on App Store with GitHub Actions](https://www.marcogomiero.com/posts/2024/kmp-ci-ios)

One step of that CI job is [setting up the required certificates](https://www.marcogomiero.com/posts/2024/kmp-ci-ios#setup-signing-certificates) for signing the app: `Apple Development` and `Apple Distribution`. In the past, it was possible to extract these two certificates from the local Keychain by selecting them and using the `Export 2 items…` option.

Unfortunately, this eventually stopped working for reasons that remain obscure to me (and I'm happy to keep it that way :)). So I fixed the issue, and now I'm sharing it so I can remember it in the future.

The first step is exporting both certificates (`Apple Development` and `Apple Distribution`) from the Keychain separately. To combine them, it's necessary to first convert them to the `pem` format:

```bash
openssl pkcs12 -in cert1.p12 -out cert1.pem -nodes -legacy
```

where `cert1.p12` is the certificate exported from the Keychain. This command will prompt for the password used when exporting the certificate.

After running the same command for the second certificate (producing `cert2.pem`), both certificates can be combined:

```bash
cat cert1.pem cert2.pem > combined.pem
```

and converted to the `p12` format:

```bash
openssl pkcs12 -export -in combined.pem -out final.p12 -name "Combined Certificates"
```

This command prompts to set an export password for the `final.p12` file. It's the value that will be stored in the `CERTIFICATES_PASSWORD` secret below.

The resulting `final.p12` can be base64-encoded and uploaded to GitHub secrets as `CERTIFICATES_P12`, ready to be used in GitHub Actions:

```yml
- name: import certs
  uses: apple-actions/import-codesign-certs@v2
  with:
    p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
    p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}
```
