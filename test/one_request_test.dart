/// This file contains the implementation of a Flutter app that sends a GET request to 'https://catfact.ninja/fact' using the 'one_request' package.
/// The app also demonstrates how to send files as part of the request body.
/// The response from the server is displayed on the app's home page.
/// The 'one_request' package is used to create an instance of the request and send it.
/// The app also loads the 'one_request' configuration and initializes the loading builder.
/// The app has three classes: MyApp, MyHomePage, and _MyHomePageState.
/// MyApp is the main app widget that initializes the 'one_request' configuration and sets up the app's theme.
/// MyHomePage is a stateful widget that displays the response from the server.
/// _MyHomePageState is the state object for MyHomePage that sends the GET request and updates the UI with the response.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:one_request/one_request.dart';

// Main App
void main() async {
  // Loading config Add  esential
  oneRequest.loadingconfig();
  runApp(const MyApp());
}

// Main App Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Loading config Builder initialize
      builder: oneRequest.initLoading,
      title: 'Flutter Demo',
      theme: ThemeData(
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _counter = '';
  List<int> filebytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];
  Future<void> _incrementCounter() async {
    // One Request instance create
    final request = oneRequest();
    // Send request
    var value = await request.send(
      // Request Url
      url: 'https://catfact.ninja/fact',
      // Request Method
      method: RequestType.GET,

      formData: true,
      body: {
        'file': [
          // file  send
          request.file(file: File('path'), filename: 'file'),
          request.fileFromByte(filebyte: filebytes),
          request.fileFormString(filestring: 'fileString'),
        ],
      },
    );
    setState(() {
      // Response value
      value.fold(
        // Success
        (l) => _counter = l['fact'],
        // Error
        (r) => _counter = r.toString(),
      );
    });
  }

  String value = '';

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
            const Text(
              'Here is Responce:',
            ),
            Text(
              // Response value
              _counter,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // Send request on click
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
