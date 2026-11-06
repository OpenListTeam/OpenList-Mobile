import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/utils/service_manager.dart';

import '../../generated/l10n.dart';
import 'common.dart';

/// Chooses between the embedded core and a remote OpenList server.
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _pwd = TextEditingController();
  final _otp = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _pwd.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
      // Navigator.pop: Get.back only dismisses an open snackbar.
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      showError(e, title: S.current.connectFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = OpenListSession.instance;
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).connection)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_busy) const LinearProgressIndicator(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text(S.of(context).localServer),
              subtitle:
                  session.kind == ConnectionKind.local && session.isConnected
                      ? Text(session.client!.baseUrl)
                      : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _run(() async {
                await ServiceManager.instance.ensureServiceRunning();
                await session.connectLocal();
              }),
            ),
          ),
          if (session.isConnected && session.kind == ConnectionKind.remote) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _run(session.logout),
              child: Text(S.of(context).logout),
            ),
          ],
          const SizedBox(height: 16),
          Text(S.of(context).remoteServer,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
                labelText: S.of(context).serverUrl,
                hintText: 'https://example.com'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _user,
            decoration: InputDecoration(labelText: S.of(context).username),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pwd,
            obscureText: true,
            decoration: InputDecoration(labelText: S.of(context).password),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: S.of(context).otpCode),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final url = _url.text.trim();
              if (Uri.tryParse(url)?.hasScheme != true ||
                  _user.text.trim().isEmpty) {
                showMessage(S.current.requiredField);
                return;
              }
              _run(() => session.connectRemote(
                  url, _user.text.trim(), _pwd.text,
                  otpCode: _otp.text.trim()));
            },
            child: Text(S.of(context).login),
          ),
        ]),
      ),
    );
  }
}
