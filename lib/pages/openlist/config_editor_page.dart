import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:get/get.dart';
import '../../contant/native_bridge.dart';
import '../../generated/l10n.dart';
import '../../utils/service_manager.dart';

/// Config.json Editor with validation, backup, and real-time syntax checking
class ConfigEditorPage extends StatefulWidget {
  const ConfigEditorPage({Key? key}) : super(key: key);

  @override
  State<ConfigEditorPage> createState() => _ConfigEditorPageState();
}

class _ConfigEditorPageState extends State<ConfigEditorPage> {
  final TextEditingController _controller = TextEditingController();
  String _filePath = '';
  String _backupFilePath = '';
  bool _isLoading = true;
  bool _isPreview = false;
  String? _errorMessage;
  String? _jsonErrorMessage;
  int? _jsonErrorLine;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadConfigFile();
    // Real-time JSON validation
    _controller.addListener(_validateJson);
  }

  /// Real-time JSON syntax validation with debounce
  void _validateJson() {
    if (_isPreview) return; // Skip validation in preview mode
    
    // Cancel previous timer to implement debounce
    _debounceTimer?.cancel();
    
    // Create new timer with 300ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final text = _controller.text.trim();
      if (text.isEmpty) {
        if (mounted) {
          setState(() {
            _jsonErrorMessage = null;
            _jsonErrorLine = null;
          });
        }
        return;
      }

      try {
        jsonDecode(text);
        if (mounted) {
          setState(() {
            _jsonErrorMessage = null;
            _jsonErrorLine = null;
          });
        }
      } on FormatException catch (e) {
        if (mounted) {
          // Extract line number from error message
          final match = RegExp(r'line (\d+)').firstMatch(e.message);
          setState(() {
            _jsonErrorMessage = e.message;
            _jsonErrorLine = match != null ? int.tryParse(match.group(1) ?? '') : null;
          });
        }
      }
    });
  }

  /// Load config file with permission checking
  Future<void> _loadConfigFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final dataDir = await NativeBridge.appConfig.getDataDir();
      _filePath = '$dataDir/config.json';
      _backupFilePath = '$dataDir/config.json.backup';
      final file = File(_filePath);
      
      if (await file.exists()) {
        _controller.text = await file.readAsString();
      } else {
        _controller.text = '{\n  \n}';
        if (mounted) {
          setState(() {
            _errorMessage = S.of(context).fileNotFoundWillCreateOnSave;
          });
        }
      }
    } on FileSystemException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.osError?.errorCode == 13 
            ? S.of(context).filePermissionDenied 
            : S.of(context).loadFailed(e.message);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = S.of(context).loadFailed(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Restore from backup file
  Future<void> _restoreBackup() async {
    try {
      final backupFile = File(_backupFilePath);
      if (!await backupFile.exists()) {
        if (mounted) {
          Get.showSnackbar(GetSnackBar(
            message: S.of(context).noBackupFound,
            duration: const Duration(seconds: 2),
          ));
        }
        return;
      }

      final backupContent = await backupFile.readAsString();
      setState(() {
        _controller.text = backupContent;
      });

      if (mounted) {
        Get.showSnackbar(GetSnackBar(
          message: S.of(context).backupRestored,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        Get.showSnackbar(GetSnackBar(
          message: S.of(context).restoreBackupFailed(e.toString()),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  /// Show confirmation dialog before saving
  /// Provides three options: Cancel, Save Only, Save and Restart
  Future<void> _showSaveConfirmation() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).confirmSaveConfigTitle),
        content: Text(S.of(context).confirmSaveConfigMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: Text(S.of(context).saveOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save_restart'),
            child: Text(S.of(context).saveAndRestart),
          ),
        ],
      ),
    );

    if (result == 'save' || result == 'save_restart') {
      final saveSuccess = await _saveConfigFile();
      
      // Restart service if requested and save was successful
      if (saveSuccess && result == 'save_restart') {
        await _restartOpenListService();
      }
    }
  }

  /// Restart OpenList service after config changes
  /// Calls ServiceManager.instance.restartService() to stop and start the service
  /// Only works on Android platform
  Future<void> _restartOpenListService() async {
    if (!Platform.isAndroid) {
      if (mounted) {
        Get.showSnackbar(GetSnackBar(
          message: S.of(context).serviceRestartOnlyAndroid,
          duration: const Duration(seconds: 2),
        ));
      }
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        Get.showSnackbar(GetSnackBar(
          message: S.of(context).restartingService,
          duration: const Duration(seconds: 2),
          showProgressIndicator: true,
        ));
      }

      // Restart service via ServiceManager
      final success = await ServiceManager.instance.restartService();
      
      if (mounted) {
        if (success) {
          Get.showSnackbar(GetSnackBar(
            message: S.of(context).serviceRestartSuccess,
            duration: const Duration(seconds: 3),
          ));
        } else {
          Get.showSnackbar(GetSnackBar(
            message: S.of(context).serviceRestartFailed,
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        Get.showSnackbar(GetSnackBar(
          message: S.of(context).saveFailed(e.toString()),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  /// Save config file with JSON validation and backup mechanism
  /// Returns true if save was successful, false otherwise
  Future<bool> _saveConfigFile() async {
    final text = _controller.text.trim();
    
    // Validate JSON format before saving
    try {
      jsonDecode(text);
    } on FormatException catch (e) {
      if (mounted) {
        final match = RegExp(r'line (\d+)').firstMatch(e.message);
        final line = match != null ? int.tryParse(match.group(1) ?? '') : null;
        Get.showSnackbar(GetSnackBar(
          message: line != null 
            ? S.of(context).invalidJsonFormat(line, e.message)
            : S.of(context).saveFailed(e.message),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }
      return false;
    }

    File? backupFile;
    try {
      final file = File(_filePath);
      
      // Create backup before saving
      if (await file.exists()) {
        backupFile = File(_backupFilePath);
        await file.copy(_backupFilePath);
      }

      // Ensure parent directory exists
      await file.parent.create(recursive: true);
      
      // Write new config
      await file.writeAsString(text);
      
      if (mounted) {
        Get.showSnackbar(GetSnackBar(
          message: S.of(context).saved,
          duration: const Duration(seconds: 2),
        ));
      }
      
      return true;
    } on FileSystemException catch (e) {
      // Restore backup on failure
      if (backupFile != null && await backupFile.exists()) {
        try {
          await backupFile.copy(_filePath);
        } catch (_) {}
      }
      
      if (mounted) {
        final errorMsg = e.osError?.errorCode == 13 
          ? S.of(context).filePermissionDenied 
          : S.of(context).saveFailed(e.message);
        Get.showSnackbar(GetSnackBar(
          message: errorMsg,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }
      return false;
    } catch (e) {
      // Restore backup on failure
      if (backupFile != null && await backupFile.exists()) {
        try {
          await backupFile.copy(_filePath);
        } catch (_) {}
      }
      
      if (mounted) {
        Get.showSnackbar(GetSnackBar(
          message: S.of(context).saveFailed(e.toString()),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('config.json'),
        actions: [
          // Restore backup button
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _restoreBackup,
            tooltip: S.of(context).restoreBackup,
          ),
          // Toggle preview/edit mode
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
            onPressed: () => setState(() => _isPreview = !_isPreview),
            tooltip: _isPreview ? S.of(context).edit : S.of(context).preview,
          ),
          // Reload file
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfigFile,
            tooltip: S.of(context).refresh,
          ),
          // Save with confirmation
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _showSaveConfirmation,
            tooltip: S.of(context).save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning message banner
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
                
                // File path display
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(_filePath, 
                    style: Theme.of(context).textTheme.bodySmall),
                ),
                
                // Editor or preview
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
                
                // JSON syntax error display at bottom
                if (_jsonErrorMessage != null && !_isPreview)
                  Container(
                    color: Colors.red.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_jsonErrorLine != null)
                                Text(
                                  'Line $_jsonErrorLine',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                _jsonErrorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
