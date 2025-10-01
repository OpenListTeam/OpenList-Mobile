import 'package:flutter/material.dart';
import '../../generated/l10n.dart';

class TroubleshootingPage extends StatelessWidget {
  const TroubleshootingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).troubleshooting),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildIssueCard(
            context,
            icon: Icons.power_settings_new,
            title: S.of(context).autoStartIssue,
            description: S.of(context).autoStartIssueDesc,
          ),
          _buildIssueCard(
            context,
            icon: Icons.storage,
            title: S.of(context).databaseNotSavedIssue,
            description: S.of(context).databaseNotSavedIssueDesc,
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
