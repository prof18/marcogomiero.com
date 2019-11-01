---
layout: post
title:  "Flutter or React Native, a cross platfrom dilemma - How to build User Interfaces - (Part 2)"
date:   2019-09-09
draft: true
---

Welcome to the second part of this comparison about React Native and Flutter. In the first episode, we have introduced the two frameworks with some history and with a comparison between the languages that these two frameworks uses. 

If you have lost the first episode, I suggest you to read it before moving on.

> [Flutter or React Native, a cross platfrom dilemma - Introduction - (Part 1)](http://marcogomiero.com/posts/2019/rn-flutter-dilemma-1-intro/)

In this article, I will explain how to build user interfaces in React Native and Flutter. 
Disclaimer: This article will not cover all the deep aspects of the two frameworks, but I want to give you an overview to better understand the differences. For much deeper details, I suggest you give a look to the official documentation ([React Native](https://facebook.github.io/react-native/) - [Flutter](https://flutter.dev/docs))

## React Native

Let's jump immediately into some code (a simple *Hello World*).

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

The entry point of this Hello World is the `render` method. Inside this method, we declare all the *items* (these items have a precise name, but I'll reveal it in a moment) that has to be rendered on the screen. In this case, there is a `View` with inside a `Text`. These *items* are called **Components** and a **Component** is the basic building block that composes the UI. Of course, as showed in the example above, the **Components** can be nested together to build more complex components and UIs. 

The **Components** are declared and stylized (the styling is done by using *CSS*) by using a **D**omain **S**pecific **L**anguage called **JSX**. This **DSL** is basically a (very simple) mixture of *Javascript* and *XML*. For more information about **JSX**, please refear to the [documentation](https://reactjs.org/docs/glossary.html#jsx).  

```jsx
<Text
    ellipsizeMode={"tail"}
    numberOfLines={this.props.numberOfLines || 100}
    style={{fontSize: 14}}
>
  "Hello World"
</Text>
```

The React team has already developed lots of Components that we can use (there is a list of the available Components in the [documentation](https://facebook.github.io/react-native/docs/components-and-apis.html)) but we can also download and use Components developed by third-party developers. Every Component can be used in a standalone way or it can be combined with other ones to create a more complex one.

{{< figure src="/img/flutter-rn/components.png" alt="image" caption="Google Search Trends for "React Native" and "Flutter"." >}}

## Flutter

And now, let's move to Flutter. As before, we start with a simple Hello World.

```dart
// Flutter
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter Demo Home Page"),
        ),
        body: Center(
          child: Text("Hello World"),
        ),
      ),
    );
  }
}
```
  In Flutter, the equivalent of Components are **Widgets** and  in the example above, instead of `View` and `Text` we have `Center` and `Text`.  Flutter takes inspiration from React and the main idea is that the UI is build out of widgets. In fact, in Flutter everything is a widget: for example the structural elements of the application ( buttons, menu, dialogs, etc ), the stylistic elements ( opacity, transformations, etc ) and also the aspect of layout ( margins, paddings, alignments, etc ) are widgets. And even the application itself are a widget. 

introdurre in widget

nominare quindi il fatto che in Flutter tutto e' un widget.

Esempi di cosa sono widget

Tutta l'app e' un widget

Infatti abbiamo cominciato a definere il nostro Hello Wordl come un stateless widget

e poi passare  a descrivere i widget dell'Hello World

<!-- How it works to buil UI stuff. Components vs Widgets, some pills about state management. Talks about declarative pattern vs the imperative one. -->

<!-- 

Components

Basic UI building blocks
Fit together to form a custom component
Domain specific language called JSX
Customisable with CSS 
Or better “usually match how CSS works on the web”


 -->

<!-- 

Widgets 

 Basic UI building blocks
Takes inspiration from RN
Everything is a Widget

cambiare l'esempio con uno stateful widget, come sulle slide del codelab

  -->



{{< figure src="/img/flutter-rn/widgets.png" alt="image" caption="Google Search Trends for \"React Native\" and \"Flutter\"." >}}



<!-- Possibility of UI modularization -->

<!-- Maybe talk a little bit about UI modularization -->

<!-- Declerative vs Imperative UI as wrappping up all the stuff -->

<!--

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}




 -->