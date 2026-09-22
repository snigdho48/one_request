/// Turns HTTP(S) or relative paths into a `ws` / `wss` [Uri].
Uri resolveSocketUri(String url, {String? baseUrl}) {
  final raw = url.trim();
  if (raw.isEmpty) {
    throw ArgumentError.value(url, 'url', 'WebSocket url is empty');
  }
  if (raw.startsWith('ws://') || raw.startsWith('wss://')) {
    return Uri.parse(raw);
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return Uri.parse(raw.replaceFirst(RegExp(r'^http'), 'ws'));
  }
  if (baseUrl == null || baseUrl.trim().isEmpty) {
    return Uri.parse(raw);
  }
  var httpBase = baseUrl.trim();
  if (httpBase.startsWith('wss://')) {
    httpBase = 'https://${httpBase.substring(6)}';
  } else if (httpBase.startsWith('ws://')) {
    httpBase = 'http://${httpBase.substring(5)}';
  }
  final resolved = Uri.parse(httpBase).resolve(raw);
  final scheme = resolved.scheme == 'https'
      ? 'wss'
      : resolved.scheme == 'http'
          ? 'ws'
          : resolved.scheme;
  return resolved.replace(scheme: scheme);
}
