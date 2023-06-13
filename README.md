<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->
# one_request

## A simple all in one web request package.

### Features

#### Package used **Dio** ,**Easyloading**, **Either**. Thanks All of them.


## Usage

Include short and useful examples for package users. Navigate
to `/test` folder for example.

Add `oneRequest.loadingconfig` under `main()` and async it.

```dart
void main() async {
  oneRequest.loadingconfig;               // <------- Add here
  runApp(const MyApp());
}
```

Add `oneRequest.initLoading` under `runapp()` before Materialapp

```dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: oneRequest.initLoading,
      title: 'Flutter Demo one_request',
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
```

 Call api example:

```dart
  final request = oneRequest();
  var value = await request.send(
      url: 'https://google.com',            // <------ URL
      method: 'GET',                        // <------ Method ('GET','POST','PUT','DELETE',)
      header: {'test': 'test'},             // <------ Header data Map<String,dynamic> (Optional)
      body: {'test': 'test'},               // <------ Body data Map<String,dynamic> (Optional)
      formData: false,                      // <------ Boolean value , true is FormData, Default is false (Optional)
      maxRedirects: 1,                      // <------ MaxRedirect count, Default is 1 (Optional)
      timeout: 60,                          // <------ Request Timeout, Default is 60 Second (Optional)
      contentType:  'application/json',     // <------ ContentType, Default is 'application/json' (Optional)
      responseType: 'json',                 // <------ ['stream','json','plain','bytes'], Default is 'json' (Optional)
    );
```

## Additional information


### loading Config can be modified 

```dart
  oneRequest.loadingconfig(
    backgroundColor: Colors.amber,                      // <----- BackgroundColor of loading
    indicator: const CircularProgressIndicator(),       // <----- Widget
    indicatorColor: Colors.red,                         // <----- Loading Indicator Colour
    progressColor: Colors.red,                          // <----- Pogress Indicator Colour
    textColor: Colors.red,                              // <----- Text Color
    success : const Icon(                               // <----- Success Widget
        Icons.check,
        color: Colors.green,
      ),
      error : const Icon(                               // <----- Error Widget
        Icons.error,
        color: Colors.red,
      ),
      info : const Icon(                                // <----- Info Widget
        Icons.info,
        color: Colors.blue,
      ),
  );
```

### loading Widget Only can be modified 

```dart
  oneRequest.loadingconfig(
    indicator: const CircularProgressIndicator(),       // <----- Widget
    status: 'loading',                                  // <----- Text 
  );
```
