import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_request/one_request.dart';

void main() {
  oneRequest(
    url: 'https://jsonplaceholder.typicode.com/todos/1',
    method: 'GET',
    responsetype: 'json',
  );
  oneRequest.config!(
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
  oneRequest.loader!(
    indicator: const CircularProgressIndicator(),
    status: 'loading',
  );
}
