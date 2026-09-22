/// Shared HTTP / WebSocket URL joining. Absolute hosts are never prefixed.
bool isAbsoluteNetworkUrl(String url) {
  final raw = url.trim();
  return raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.startsWith('ws://') ||
      raw.startsWith('wss://');
}

/// Prefix [url] with [baseUrl] only when [url] is relative.
///
/// Concatenation matches the historical `baseUrl + url` behavior so existing
/// apps that pass `/path` or `path` keep the same result.
String resolveRequestUrl(String url, {String? baseUrl}) {
  final raw = url.trim();
  if (raw.isEmpty || isAbsoluteNetworkUrl(raw)) {
    return raw;
  }
  final base = baseUrl?.trim();
  if (base == null || base.isEmpty) {
    return raw;
  }
  return base + raw;
}
