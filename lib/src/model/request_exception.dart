import 'dart:convert';

/// Typed HTTP failure from [OneRequest.request] / [OneRequest.send].
///
/// Parses Django REST / JSON:API style payloads:
/// `{error, detail, message, details, code, data}`.
class RequestException implements Exception {
  RequestException(
    this.message, {
    this.code,
    this.data,
    this.statusCode,
    this.url,
  });

  factory RequestException.fromClient(dynamic error,
      {int? statusCode, String? url}) {
    if (error is RequestException) {
      return error;
    }
    if (error is Map) {
      return RequestException.fromBody(
        Map<String, dynamic>.from(error),
        statusCode: statusCode,
        url: url,
      );
    }
    final text = error?.toString() ?? 'Something went wrong';
    final decoded = _tryDecodeJsonMap(text);
    if (decoded != null) {
      return RequestException.fromBody(
        decoded,
        statusCode: statusCode,
        url: url,
        fallback: text,
      );
    }
    return RequestException(text, statusCode: statusCode, url: url);
  }

  factory RequestException.fromBody(
    Map<String, dynamic> map, {
    int? statusCode,
    String? url,
    String? fallback,
  }) {
    final nested = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : null;
    var message = RestErrorParser.messageFromBody(map, statusCode: statusCode);
    if (message.trim().isEmpty) {
      message = fallback?.trim().isNotEmpty == true
          ? fallback!.trim()
          : 'Something went wrong. Please try again.';
    }
    return RequestException(
      message,
      code: map['code']?.toString(),
      data: nested,
      statusCode: statusCode,
      url: url,
    );
  }

  final String message;
  final String? code;
  final Map<String, dynamic>? data;
  final int? statusCode;
  final String? url;

  @override
  String toString() => message;
}

/// Shared REST/Django error extraction used as the default error handler.
class RestErrorParser {
  RestErrorParser._();

  /// Default [OneRequest.setErrorHandler] implementation.
  ///
  /// When the payload includes `code` or nested `data`, returns JSON so
  /// [RequestException.fromClient] can recover structured fields.
  static String handler(
    Map<String, dynamic> body,
    int? status,
    String? url,
  ) {
    final message = messageFromBody(body, statusCode: status);
    final code = body['code']?.toString();
    final data = body['data'];
    if ((code != null && code.isNotEmpty) || data is Map) {
      return jsonEncode({
        'message': message,
        'code': code,
        'data': data is Map ? Map<String, dynamic>.from(data) : null,
      });
    }
    return message;
  }

  static String messageFromBody(
    Map<String, dynamic> body, {
    int? statusCode,
  }) {
    final extracted = _extractIfPresent(body);
    if (extracted != null) return extracted;

    if (statusCode == 401) return 'Unauthorized. Please login again.';
    if (statusCode == 403) {
      return 'Access forbidden. You do not have permission.';
    }
    if (statusCode == 404) return 'Resource not found.';
    if (statusCode == 500) return 'Server error. Please try again later.';
    if (statusCode != null) return 'Request failed ($statusCode)';
    return 'Something went wrong';
  }

  static String? fromData(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html')) {
        return 'Server returned an unexpected response.';
      }
      return trimmed;
    }
    if (data is Map) {
      return _extractIfPresent(Map<String, dynamic>.from(data));
    }
    if (data is List && data.isNotEmpty) {
      final first = data.first.toString().trim();
      return first.isEmpty ? null : first;
    }
    return null;
  }

  static String? _extractIfPresent(Map<String, dynamic> body) {
    final details = body['details'];
    if (details is Map && details.isNotEmpty) {
      final messages = <String>[];
      for (final value in details.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first.toString().trim();
          if (first.isNotEmpty) messages.add(first);
        } else if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) messages.add(text);
        }
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }

    for (final key in ['error', 'detail', 'message', 'msg']) {
      final value = body[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    if (body['errors'] != null) {
      return _fromErrorsField(body['errors']);
    }
    return null;
  }

  static String? _fromErrorsField(dynamic errors) {
    if (errors is List && errors.isNotEmpty) {
      final firstItem = errors.first;
      if (firstItem is Map && firstItem.isNotEmpty) {
        final first = firstItem.values.first.toString().trim();
        if (first.isNotEmpty) return first;
      }
      final first = firstItem.toString().trim();
      return first.isEmpty ? null : first;
    }
    if (errors is Map && errors.isNotEmpty) {
      final value = errors.values.first;
      if (value is List && value.isNotEmpty) {
        final first = value.first.toString().trim();
        if (first.isNotEmpty) return first;
      }
      final first = value.toString().trim();
      return first.isEmpty ? null : first;
    }
    final errStr = errors.toString().trim();
    return errStr.isEmpty ? null : errStr;
  }
}

Map<String, dynamic>? _tryDecodeJsonMap(String text) {
  var t = text.trim();
  if (t.isEmpty) return null;
  final start = t.indexOf('{');
  final end = t.lastIndexOf('}');
  if (start >= 0 && end > start) {
    t = t.substring(start, end + 1);
  }
  if (!t.startsWith('{') || !t.endsWith('}')) return null;
  try {
    final decoded = jsonDecode(t);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}

/// Pulls the inner `data` field from Django-style `{data: ...}` envelopes.
dynamic unwrapPayload(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['data'] ?? data;
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    return map['data'] ?? map;
  }
  return data;
}
