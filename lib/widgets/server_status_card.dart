import 'package:flutter/material.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated_api.dart';

/// Server status card with start/stop controls and network mode toggle
class ServerStatusCard extends StatelessWidget {
  const ServerStatusCard({
    super.key,
    required this.status,
    required this.mode,
    required this.onStartStop,
    required this.onModeChange,
    required this.onTapDetails,
  });

  final ServerStatus? status;
  final String mode;
  final VoidCallback onStartStop;
  final VoidCallback onModeChange;
  final VoidCallback onTapDetails;

  @override
  Widget build(BuildContext context) {
    final isRunning = status?.running ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(AppDesign.space16),
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isRunning ? AppDesign.successGreen : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppDesign.space12),
                Text(
                  isRunning ? 'Server Running' : 'Server Stopped',
                  style: AppDesign.headline3.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (isRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesign.space12,
                      vertical: AppDesign.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppDesign.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppDesign.radiusSmall,
                      ),
                    ),
                    child: Text(
                      _modeLabel(mode),
                      style: AppDesign.caption.copyWith(
                        color: AppDesign.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppDesign.space20),

            // Main action button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onStartStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning
                      ? colorScheme.error
                      : AppDesign.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isRunning ? Icons.stop_circle : Icons.play_circle),
                    const SizedBox(width: AppDesign.space8),
                    Text(
                      isRunning ? 'Stop Server' : 'Start Server',
                      style: AppDesign.button.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDesign.space16),
            InkWell(
              onTap: onModeChange,
              borderRadius: BorderRadius.circular(AppDesign.radiusButton),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.space16,
                  vertical: AppDesign.space12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? AppDesign.borderDark
                        : AppDesign.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(AppDesign.radiusButton),
                ),
                child: Row(
                  children: [
                    Icon(
                      mode == 'local' ? Icons.computer : Icons.wifi,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppDesign.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Network Mode',
                            style: AppDesign.body2.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Text(
                            _modeLabel(mode),
                            style: AppDesign.body1.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ],
                ),
              ),
            ),

            // Connection details (when running)
            if (isRunning && status != null) ...[
              const SizedBox(height: AppDesign.space16),
              InkWell(
                onTap: onTapDetails,
                borderRadius: BorderRadius.circular(AppDesign.radiusButton),
                child: Container(
                  padding: const EdgeInsets.all(AppDesign.space16),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? AppDesign.primaryBlue : AppDesign.primaryBlue)
                            .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppDesign.radiusButton),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 20, color: colorScheme.primary),
                      const SizedBox(width: AppDesign.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connection Info',
                              style: AppDesign.body2.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _getAddress(status!),
                              style: AppDesign.caption.copyWith(
                                color: (isDark ? Colors.white : Colors.black87)
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _modeLabel(String m) {
    return switch (m) {
      'lan' => 'LAN Access',
      'public' => 'Public Access',
      _ => 'Localhost Only',
    };
  }

  String _getAddress(ServerStatus s) {
    final https = s.httpsPort > 0 && (s.forceHttps || s.httpPort <= 0);
    final port = https ? s.httpsPort : s.httpPort;
    final host = s.addresses.isNotEmpty ? s.addresses.first : '127.0.0.1';
    return '${https ? 'https' : 'http'}://$host:$port';
  }
}
