import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:get/get.dart';
import '../../contant/native_bridge.dart';
import '../../generated/l10n.dart';

/// Config.json Editor
class ConfigEditorPage extends StatefulWidget {
  const ConfigEditorPage({Key? key}) : super(key: key);

  @override
  State<ConfigEditorPage> createState() => _ConfigEditorPageState();
}

class _ConfigEditorPageState extends State<ConfigEditorPage> {
  final TextEditingController _controller = TextEditingController();
  String _filePath = '';
  bool _isLoading = true;
  bool _isPreview = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfigFile();
  }

  Future<void> _loadConfigFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final dataDir = await NativeBridge.appConfig.getDataDir();
      _filePath = '$dataDir/config.json';
      final file = File(_filePath);
      
      if (await file.exists()) {
        _controller.text = await file.readAsString();
      } else {
        _controller.text = '{\n  \n}';
        _errorMessage = 'File not found. Will create on save.';
      }
    } catch (e) {
      _errorMessage = 'Load failed: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfigFile() async {
    try {
      final file = File(_filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(_controller.text);
      
      if (mounted) {
        Get.showSnackbar(const GetSnackBar(
          message: 'Saved',
          duration: Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        Get.showSnackbar(GetSnackBar(
          message: 'Save failed: $e',
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('config.json'),
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
            onPressed: () => setState(() => _isPreview = !_isPreview),
            tooltip: _isPreview ? 'Edit' : 'Preview',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfigFile,
            tooltip: S.of(context).refresh,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfigFile,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    color: Colors.orange.withOpacity(0.2),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!, 
                            style: const TextStyle(color: Colors.orange, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(_filePath, 
                    style: Theme.of(context).textTheme.bodySmall),
                ),
                
                Expanded(
                  child: _isPreview
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: HighlightView(
                            _controller.text,
                            language: 'json',
                            theme: isDark ? monokaiSublimeTheme : githubTheme,
                            textStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        )
                      : TextField(
                          controller: _controller,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
