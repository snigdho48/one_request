library one_request;

import 'src/dio_request.dart';
import 'src/resourses/utils.dart';

class oneRequest extends basehttpRequest {
  oneRequest(
      {required super.url,
      required super.method,
      super.body,
      super.queryParameters,
      super.formData,
      super.header,
      super.maxRedirects,
      super.timeout,
      super.options});
}
