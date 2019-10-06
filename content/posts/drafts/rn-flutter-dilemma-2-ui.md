---
layout: post
title:  "Flutter or React Native, a cross platfrom dilemma - How to build User Interfaces - (Part 2)"
date:   2019-09-09
draft: true
---

<!-- How it works to buil UI stuff. Components vs Widgets, some pills about state management. Talks about declarative pattern vs the imperative one. -->


<!-- 

Components

Basic UI building blocks
Fit together to form a custom component
Domain specific language called JSX
Customisable with CSS 
Or better “usually match how CSS works on the web”


 -->

```javascript
// React Native
import React from "react";
import { StyleSheet, Text, View } from "react-native";

export default class App extends React.Component {
  render() {
    return (
      <View style={styles.container}>
        <Text>Hello world!</Text>
      </View>
    );
  }
}
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center"
  }
});
```

 <!-- 
 
Widgets 

 Basic UI building blocks
Takes inspiration from RN
Everything is a Widget
 
  -->

```dart
// Flutter
import 'package:flutter/material.dart';

void main() {
  runApp(
    Center(
      child: Text(
        'Hello, world!',
        textDirection: TextDirection.ltr,
      ),
    ),
  );
}
```

  <!-- Possibility of UI modularization -->

  <!-- Maybe talk a little bit about UI modularization -->

<!-- Declerative vs Imperative UI as wrappping up all the stuff -->

