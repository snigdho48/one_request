import 'dart:async';

import 'package:flutter/material.dart';

import 'connectivity_watch.dart';

/// Overlay for snackbar / banner / popover. No-op while connectivity is off.
class ConnectivityNoticeHost extends StatefulWidget {
  const ConnectivityNoticeHost({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityNoticeHost> createState() => _ConnectivityNoticeHostState();
}

class _ConnectivityNoticeHostState extends State<ConnectivityNoticeHost> {
  int _handledEventId = -1;
  bool _dismissedPopover = false;
  bool _showOnlineSnack = false;
  Timer? _snackTimer;

  ConnectivityWatch get _watch => ConnectivityWatch.instance;

  @override
  void initState() {
    super.initState();
    _watch.addListener(_onWatch);
  }

  @override
  void dispose() {
    _snackTimer?.cancel();
    _watch.removeListener(_onWatch);
    super.dispose();
  }

  void _onWatch() {
    final event = _watch.lastEvent;
    if (event != null && event.id != _handledEventId) {
      _handledEventId = event.id;
      if (!event.online) {
        _dismissedPopover = false;
        _showOnlineSnack = false;
        _snackTimer?.cancel();
      } else if (ConnectivityWatch.ui == ConnectivityUi.snackbar &&
          ConnectivityWatch.showOnline &&
          ConnectivityWatch.builder == null) {
        _showOnlineSnack = true;
        _snackTimer?.cancel();
        _snackTimer = Timer(ConnectivityWatch.noticeDuration, () {
          if (mounted) setState(() => _showOnlineSnack = false);
        });
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ConnectivityWatch.isEnabled;
    final builder = ConnectivityWatch.builder;
    if (enabled && builder != null) {
      return builder(context, _watch.status, widget.child);
    }
    final ui = ConnectivityWatch.ui;
    final offline =
        enabled && !_watch.status.online && ConnectivityWatch.showOffline;
    final snackMessage = !enabled || ui != ConnectivityUi.snackbar
        ? null
        : offline
            ? ConnectivityWatch.offlineMessage
            : _showOnlineSnack
                ? ConnectivityWatch.onlineMessage
                : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (snackMessage != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _ConnectivitySnack(message: snackMessage),
          ),
        if (ui == ConnectivityUi.banner && offline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _OfflineBanner(message: ConnectivityWatch.offlineMessage),
          ),
        if (ui == ConnectivityUi.popover && offline && !_dismissedPopover)
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: _OfflinePopover(
              message: ConnectivityWatch.offlineMessage,
              onDismiss: () => setState(() => _dismissedPopover = true),
            ),
          ),
      ],
    );
  }
}

class _ConnectivitySnack extends StatelessWidget {
  const _ConnectivitySnack({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('one_request_connectivity_snackbar'),
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      color: scheme.inverseSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          message,
          style: TextStyle(color: scheme.onInverseSurface),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('one_request_connectivity_banner'),
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflinePopover extends StatelessWidget {
  const _OfflinePopover({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Material(
          key: const ValueKey('one_request_connectivity_popover'),
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: scheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: scheme.error),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
