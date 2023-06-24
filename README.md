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

#### Package used **dio** ,**flutter_easyloading**, **either_dart**. Thanks All of them.


## Usage

Include short and useful examples for package users. Navigate
to `/test` folder for example.

Add `oneRequest.loadingconfig` under `main()` and async it.

```dart
void main() async {
  // Add Here
  oneRequest.loadingconfig();
  runApp(const MyApp());
}
```

Add `oneRequest.initLoading` under `runapp()` inside Materialapp

```dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Add as Builder
      builder: oneRequest.initLoading,
      title: 'Flutter Demo one_request',
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
```

 Call api example:

```dart
// Create an instance
  final request = oneRequest();
  // store the respone 
  var value = await request.send(
      // Url requared
      url: 'https://google.com',
      // Method ('GET','POST','PUT','DELETE',)           
      method: RequestType.GET, 
      // Header data Map<String,dynamic> (Optional)                      
      header: {'test': 'test'},   
      // Body data Map<String,dynamic> (Optional)          
      body: {'test': 'test'},    
      // Boolean value , true is FormData, Default is false (Optional)           
      formData: false, 
      //MaxRedirect count, Default is 1 (Optional)
      maxRedirects: 1, 
      // Request Timeout, Default is 60 Second (Optional)                     
      timeout: 60,  
      //  ContentType, Default is 'application/json' (Optional)                       
      contentType:  ContentType.json,
      // ['stream','json','plain','bytes'], Default is 'json' (Optional)    
      responseType: ResponseType.json, 
      // If responce type is {'status':success,'message': 'text','data':[]} or indner  content containing all response in 'data' key the make it true,initialy false
      innderData : false,

    );
```

## Additional information


### loading Config can be modified 

```dart
  // Custom loading Configuration
  oneRequest.loadingconfig(
    // BackgroundColor of loading
    backgroundColor: Colors.amber,   
    // Loading indicator Widget                   
    indicator: const CircularProgressIndicator(), 
    //  Loading Indicator Colour      
    indicatorColor: Colors.red,  
    // Progress Indicator Colour                       
    progressColor: Colors.red,  
    // Text Color                        
    textColor: Colors.red,  
    // Success Widget                            
    success : const Icon(                              
        Icons.check,
        color: Colors.green,
      ),
      // Error Widget
      error : const Icon(                              
        Icons.error,
        color: Colors.red,
      ),
      // Info Widget
      info : const Icon(                               
        Icons.info,
        color: Colors.blue,
      ),
  );
```

### loading Widget Only can be modified  to use on multi purpose outside one_request

```dart
// only loading indictor Customize
  oneRequest.loadingconfig(
    // Widget
    indicator: const CircularProgressIndicator(),    
    // Text   
    status: 'loading',                                  
  );
```

### dismiss loading

```dart
// dissmiss loading
oneRequest.dismissLoading;
```
