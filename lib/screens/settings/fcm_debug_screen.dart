import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/fcm_service.dart';

/// Developer-only FCM debug screen.
/// Only accessible when kDebugMode is true.
class FcmDebugScreen extends StatefulWidget {
  const FcmDebugScreen({super.key});

  @override
  State<FcmDebugScreen> createState() => _FcmDebugScreenState();
}

class _FcmDebugScreenState extends State<FcmDebugScreen> {
  final _fcm = FcmService();
  String _storedToken = '';
  bool _hasPermission = false;
  bool _isSubscribed = false;
  bool _hasLastMessage = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token') ?? '';

    if (mounted) {
      setState(() {
        _storedToken = token;
        _hasPermission = _fcm.permissionGranted;
        _isSubscribed = _fcm.isSubscribed;
        _hasLastMessage = _fcm.lastMessage != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('FCM Debug')),
        body: const Center(
          child: Text('Available only in debug mode'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Debug'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'Service Status',
            icon: LucideIcons.activity,
            color: const Color(0xFF10B981),
            child: _buildKeyValue([
              ('Initialized', 'yes'),
              ('Permission', _hasPermission ? 'granted' : 'denied'),
              ('Subscribed', _isSubscribed ? 'yes' : 'no'),
              ('Has last msg', _hasLastMessage ? 'yes' : 'no'),
            ]),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            title: 'FCM Token',
            icon: LucideIcons.key,
            color: const Color(0xFF3B82F6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  _storedToken.isNotEmpty ? _storedToken : '(no token stored)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniButton(
                      label: 'Refresh Token',
                      onTap: () async {
                        await _fcm.refreshToken();
                        _refresh();
                      },
                    ),
                    const SizedBox(width: 8),
                    _miniButton(
                      label: 'Copy',
                      onTap: () {
                        if (_storedToken.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: _storedToken));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            title: 'Topic: snapcal_all_users',
            icon: LucideIcons.hash,
            color: const Color(0xFF8B5CF6),
            child: Row(
              children: [
                _miniButton(
                  label: 'Resubscribe',
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _fcm.subscribeToTopic('snapcal_all_users');
                    _refresh();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Resubscribed to snapcal_all_users'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _miniButton(
                  label: 'Unsubscribe',
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _fcm.unsubscribeAllUsers();
                    _refresh();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Unsubscribed from snapcal_all_users'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            title: 'Last Received Notification',
            icon: LucideIcons.messageCircle,
            color: const Color(0xFFF59E0B),
            child: _buildLastMessage(),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.terminal,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Send test notification',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'curl -X POST -H "Authorization: Bearer YOUR_KEY" '
                  '-H "Content-Type: application/json" '
                  '-d \'{"message":{"topic":"snapcal_all_users",'
                  '"notification":{"title":"Hello","body":"Test"}}}\' '
                  'https://fcm.googleapis.com/v1/projects/snapcal-ef333/'
                  'messages:send',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValue(List<(String, String)> pairs) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pairs.map((pair) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  pair.$1,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Text(
                pair.$2,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildLastMessage() {
    final msg = _fcm.lastMessage;
    if (msg == null) {
      return Text(
        '(no notification received yet)',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    final n = msg.notification;
    final buf = StringBuffer()
      ..writeln('messageId : ${msg.messageId}')
      ..writeln('title     : ${n?.title}')
      ..writeln('body      : ${n?.body}')
      ..writeln('sentTime  : ${msg.sentTime}')
      ..writeln('data      : ${jsonEncode(msg.data)}');

    return SelectableText(
      buf.toString(),
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _miniButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }
}
