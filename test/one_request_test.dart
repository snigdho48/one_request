import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_request/one_request.dart';

Future<void> main() async {
  final request = oneRequest();
  var value = await request.send(
    url: 'https://catfact.ninja/fact',
    method: 'GET',
    responsetype: 'json',
  );
  value.fold(
    (l) => print(l),
    (r) => print(r),
  );
  oneRequest.loadingconfig(
    backgroundColor: Colors.amber,
    indicator: const CircularProgressIndicator(),
    indicatorColor: Colors.red,
    progressColor: Colors.red,
    textColor: Colors.red,
    error: const Icon(
      Icons.error,
      color: Colors.red,
    ),
    success: const Icon(
      Icons.check,
      color: Colors.green,
    ),
    info: const Icon(
      Icons.info,
      color: Colors.blue,
    ),
  );
  oneRequest.loadingWidget(
    indicator: const CircularProgressIndicator(),
    status: 'loading',
  );
}
