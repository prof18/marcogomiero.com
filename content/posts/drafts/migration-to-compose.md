---
layout: post
title:  "Migration to compose"
date:   2022-04-25
show_in_homepage: false
draft: true
---

- Update gradle version and move to gradle catalogue
- Update to gradle ktx
- Material compose them adapter
	- https://github.com/material-components/material-components-android-compose-theme-adapter
- copy the text style but without customization of font
- simply migrate the screen and keep the existing activity structure
- use interoperability with fragments https://developer.android.com/jetpack/compose/interop/interop-apis


    https://github.com/prof18/Secure-QR-Reader/commit/b9ce72efb497313215ab7e871e51b52d56ab940b

https://github.com/prof18/Secure-QR-Reader/commit/bcfbc08478b390f55ac508106931eb0bc034a0b4

https://github.com/prof18/Secure-QR-Reader/commit/ef7477e3faa3ef826ca055d9beea5bddea75c97e

https://github.com/prof18/Secure-QR-Reader/commit/be12fd5d23610fea38be0d8ab0143c902afe297c  

- create new theme and delete old stuff

    https://github.com/prof18/Secure-QR-Reader/commit/ff1b3db643d8fdd4d1a1a84b4c0fac542717effd

- compose navigation
- accompanist permissions
- disposable effects with lifecycle owner and different mindsets

    https://github.com/prof18/Secure-QR-Reader/commit/4692b50b6e8248ebd8e3af860b25e70045cb8f8e

-  use compose about libraries

    https://github.com/prof18/Secure-QR-Reader/commit/fa52cabc8daa3955e953f46ffda577051b80baae

- transparent status bar with accompanist system ui controller.

    https://github.com/prof18/Secure-QR-Reader/commit/20e22ecd4539375cd025f28c3f95f37b51d32808

- animation with accompanist

    https://github.com/prof18/Secure-QR-Reader/commit/28628dd051f572f454c68aedbef62590391336a3

- Add horizontal view support

    https://github.com/prof18/Secure-QR-Reader/commit/2a44136000730a8cba32ef6d91f3b88572433fb8
    https://github.com/prof18/Secure-QR-Reader/tree/horizontal-orientation