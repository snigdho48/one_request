import 'package:flutter_test/flutter_test.dart';

import 'package:one_request/one_request.dart';

void main() {
  oneRequest(
    url: 'https://jsonplaceholder.typicode.com/todos/1',
    method: 'GET',
  );
  oneRequest.config!();
}
