import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fuel_tracker_app/core/web_lan_runtime.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';

/// Debug overlay: Local / LAN URL and active port (Web + debug only).
class WebLanDebugOverlay extends StatefulWidget {
  const WebLanDebugOverlay({super.key});

  @override
  State<WebLanDebugOverlay> createState() => _WebLanDebugOverlayState();
}

class _WebLanDebugOverlayState extends State<WebLanDebugOverlay> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !WebLanRuntime.hasInfo) {
      return const SizedBox.shrink();
    }

    final top = MediaQuery.paddingOf(context).top + 48;

    return Positioned(
      top: top,
      right: 8,
      left: 8,
      child: Align(
        alignment: Alignment.topRight,
        child: Material(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi_tethering, color: Colors.lightGreenAccent, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'LAN debug',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _expanded = !_expanded),
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    _row('Port', WebLanRuntime.lanPort),
                    _row('Local', WebLanRuntime.localUrl),
                    _row('LAN', WebLanRuntime.lanUrl, highlight: true),
                    _row('CORS', WebLanRuntime.corsLabel),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _copyButton('Copy LAN URL', WebLanRuntime.lanUrl),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => WebLanRuntime.logStartup(),
                          child: const Text('Log', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Colors.white70),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(
              text: value,
              style: TextStyle(
                color: highlight ? Colors.lightGreenAccent : Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _copyButton(String label, String text) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.copy, size: 14, color: Colors.white70),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        AppToastService.info(
          title: 'Đã sao chép',
          message: 'LAN URL copied',
          duration: const Duration(seconds: 2),
        );
      },
    );
  }
}
