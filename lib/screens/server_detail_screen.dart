import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:openlist_mobile/utils/service_manager.dart';

/// Server detail screen showing connection info, runtime stats, and diagnostics
class ServerDetailScreen extends StatefulWidget {
  const ServerDetailScreen({super.key});

  @override
  State<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends State<ServerDetailScreen> {
  final _sm = ServiceManager.instance;

  ServerStatus? _status;
  Map<String, dynamic> _runtime = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _sm.checkServiceStatus();
      final runtimeJson = await _sm.getRuntimeStatus();

      if (mounted) {
        setState(() {
          _status = _sm.status;
          _runtime = _parseJson(runtimeJson);
        });
      }
    } catch (e) {
      debugPrint('Failed to load server details: $e');
    }
  }

  Map<String, dynamic> _parseJson(String json) {
    try {
      return {};
    } catch (e) {
      return {};
    }
  }

  List<String> _getUrls() {
    final s = _status;
    if (s == null || !s.running) return [];

    final https = s.httpsPort > 0 && (s.forceHttps || s.httpPort <= 0);
    final port = https ? s.httpsPort : s.httpPort;
    final hosts = s.addresses.isEmpty ? ['127.0.0.1'] : s.addresses;
    return [
      for (final h in hosts) '${https ? 'https' : 'http'}://$h:$port'
    ];
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRunning = _status?.running ?? false;
    final urls = _getUrls();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Details'),
        actions: [
          if (isRunning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppDesign.space16),
        children: [
          // Status section
          _SectionHeader(title: 'Status'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppDesign.space16),
            child: Padding(
              padding: const EdgeInsets.all(AppDesign.space16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isRunning ? AppDesign.successGreen : Colors.grey)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRunning ? Icons.check_circle : Icons.cancel,
                      color: isRunning ? AppDesign.successGreen : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppDesign.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRunning ? 'Server Running' : 'Server Stopped',
                          style: AppDesign.headline3.copyWith(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: AppDesign.space4),
                        Text(
                          isRunning ? 'All systems operational' : 'Start server to accept connections',
                          style: AppDesign.body2.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Connection URLs
          if (isRunning && urls.isNotEmpty) ...[
            const SizedBox(height: AppDesign.space24),
            _SectionHeader(title: 'Connection URLs'),
            ...urls.map((url) => _ConnectionUrlCard(
              url: url,
              onCopy: () => _copyToClipboard(url),
            )),
          ],

          // Runtime statistics
          if (isRunning && _runtime.isNotEmpty) ...[
            const SizedBox(height: AppDesign.space24),
            _SectionHeader(title: 'Runtime Statistics'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: AppDesign.space16),
              child: Column(
                children: [
                  if (_runtime['uptime_sec'] != null)
                    _StatRow(
                      icon: Icons.schedule,
                      label: 'Uptime',
                      value: _formatDuration((_runtime['uptime_sec'] as num).toInt()),
                    ),
                  if (_runtime['goroutines'] != null)
                    _StatRow(
                      icon: Icons.settings,
                      label: 'Goroutines',
                      value: '${_runtime['goroutines']}',
                    ),
                  if (_runtime['heap_alloc'] != null)
                    _StatRow(
                      icon: Icons.memory,
                      label: 'Memory',
                      value: _formatBytes((_runtime['heap_alloc'] as num).toInt()),
                    ),
                ],
              ),
            ),
          ],

          // Server configuration
          const SizedBox(height: AppDesign.space24),
          _SectionHeader(title: 'Configuration'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppDesign.space16),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.http,
                  label: 'HTTP Port',
                  value: '${_status?.httpPort ?? 5244}',
                ),
                if ((_status?.httpsPort ?? -1) > 0)
                  _InfoRow(
                    icon: Icons.https,
                    label: 'HTTPS Port',
                    value: '${_status?.httpsPort}',
                  ),
                _InfoRow(
                  icon: Icons.network_check,
                  label: 'Mode',
                  value: _status?.mode ?? 'local',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDesign.space24),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.space16,
        AppDesign.space8,
        AppDesign.space16,
        AppDesign.space12,
      ),
      child: Text(
        title,
        style: AppDesign.headline3.copyWith(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _ConnectionUrlCard extends StatelessWidget {
  const _ConnectionUrlCard({
    required this.url,
    required this.onCopy,
  });

  final String url;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesign.space16,
        vertical: AppDesign.space4,
      ),
      child: ListTile(
        leading: Icon(
          Icons.link,
          color: AppDesign.primaryBlue,
        ),
        title: SelectableText(
          url,
          style: AppDesign.body1.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'monospace',
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: onCopy,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: AppDesign.primaryBlue, size: 20),
      title: Text(
        label,
        style: AppDesign.body2.copyWith(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: Text(
        value,
        style: AppDesign.body1.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(
        label,
        style: AppDesign.body2.copyWith(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: Text(
        value,
        style: AppDesign.body1.copyWith(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
