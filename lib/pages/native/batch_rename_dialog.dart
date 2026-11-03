import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

/// The rename strategies offered by the batch rename dialog.
enum BatchRenameMode {
  /// Replace every occurrence of a regular expression.
  regex,

  /// Append an incrementing number, keeping the original extension.
  sequential,

  /// Replace a literal substring.
  findReplace,
}

/// Characters that are not allowed in a file name.
final _invalidNameChars = RegExp(r'[/\\?<>*:|"]');

/// Validates a name that will be sent to the backend.
///
/// Returns the l10n key of the first problem, or null when the name is fine.
String? validateRenameName(String name) {
  if (name.trim().isEmpty) return 'emptyInput';
  if (_invalidNameChars.hasMatch(name)) return 'invalidFilenameChars';
  return null;
}

/// Builds the rename pairs for [objects].
///
/// [mode] selects the strategy, [pattern] is the regular expression or the
/// literal text to look for and [replacement] is the text to write. For
/// [BatchRenameMode.sequential] the replacement is the first number and
/// [padding] the zero padding width.
List<RenameObj> buildRenamePairs(
  List<FsObject> objects, {
  required BatchRenameMode mode,
  required String pattern,
  required String replacement,
  int padding = 0,
}) {
  switch (mode) {
    case BatchRenameMode.regex:
      final regexp = RegExp(pattern, multiLine: true);
      return [
        for (final o in objects)
          if (regexp.hasMatch(o.name))
            RenameObj(
              srcName: o.name,
              newName: _applyDatePlaceholders(
                o.name.replaceAll(regexp, replacement),
                o,
              ),
            ),
      ];
    case BatchRenameMode.sequential:
      var counter = int.tryParse(replacement.trim()) ?? 0;
      final width = padding > 0 ? padding : 0;
      return [
        for (final o in objects)
          RenameObj(
            srcName: o.name,
            newName: _sequentialName(o.name, pattern, counter++, width),
          ),
      ];
    case BatchRenameMode.findReplace:
      return [
        for (final o in objects)
          if (o.name.contains(pattern))
            RenameObj(
              srcName: o.name,
              newName: o.name.replaceFirst(pattern, replacement),
            ),
      ];
  }
}

/// Builds the new name of [name] for the sequential strategy.
///
/// When [pattern] contains `{number}` it replaces that placeholder, otherwise
/// the number is appended. The original extension is always kept.
String _sequentialName(String name, String pattern, int counter, int width) {
  final dot = name.lastIndexOf('.');
  final suffix = dot != -1 ? name.substring(dot) : '';
  final padded = width > 0 ? counter.toString().padLeft(width, '0') : '$counter';
  final base = pattern.contains('{number}')
      ? pattern.replaceAll('{number}', padded)
      : '$pattern$padded';
  return '$base$suffix';
}

/// Replaces the `{created_*}` and `{modified_*}` placeholders of [name].
///
/// The components are taken in local time, matching the web frontend.
String _applyDatePlaceholders(String name, FsObject o) {
  var result = name;
  final created = o.created?.toLocal();
  final modified = o.modified?.toLocal();
  if (created != null) {
    result = result
        .replaceAll('{created_year}', _pad(created.year, 4))
        .replaceAll('{created_month}', _pad(created.month))
        .replaceAll('{created_date}', _pad(created.day))
        .replaceAll('{created_hour}', _pad(created.hour))
        .replaceAll('{created_minute}', _pad(created.minute))
        .replaceAll('{created_second}', _pad(created.second));
  }
  if (modified != null) {
    result = result
        .replaceAll('{modified_year}', _pad(modified.year, 4))
        .replaceAll('{modified_month}', _pad(modified.month))
        .replaceAll('{modified_date}', _pad(modified.day))
        .replaceAll('{modified_hour}', _pad(modified.hour))
        .replaceAll('{modified_minute}', _pad(modified.minute))
        .replaceAll('{modified_second}', _pad(modified.second));
  }
  return result;
}

String _pad(int value, [int width = 2]) => value.toString().padLeft(width, '0');

/// Resolves an error key returned by [validateRenameName] or the regex check.
String _errorText(S strings, String key) => switch (key) {
      'invalidFilenameChars' => strings.invalidFilenameChars,
      'invalidRegex' => strings.invalidRegex,
      _ => strings.emptyInput,
    };

/// Shows the batch rename dialog for the files of [dir].
///
/// [objects] are the selected entries. Returns true when the renames were
/// applied.
Future<bool> showBatchRenameDialog(
  BuildContext context, {
  required String dir,
  required List<FsObject> objects,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _BatchRenameDialog(dir: dir, objects: objects),
  );
  return result == true;
}

class _BatchRenameDialog extends StatefulWidget {
  const _BatchRenameDialog({required this.dir, required this.objects});

  final String dir;
  final List<FsObject> objects;

  @override
  State<_BatchRenameDialog> createState() => _BatchRenameDialogState();
}

class _BatchRenameDialogState extends State<_BatchRenameDialog> {
  final _pattern = TextEditingController();
  final _replacement = TextEditingController();
  final _padding = TextEditingController();

  BatchRenameMode _mode = BatchRenameMode.regex;
  String? _patternError;
  String? _replacementError;
  bool _submitting = false;

  /// The pairs shown in the preview, null while the preview is hidden.
  List<RenameObj>? _preview;

  @override
  void dispose() {
    _pattern.dispose();
    _replacement.dispose();
    _padding.dispose();
    super.dispose();
  }

  /// Validates the current input and computes the rename pairs.
  void _previewRename() {
    final pattern = _pattern.text.trim();
    final replacement = _replacement.text;

    if (pattern.isEmpty) {
      setState(() => _patternError = 'emptyInput');
      return;
    }
    if (_mode == BatchRenameMode.regex) {
      try {
        RegExp(pattern);
      } catch (_) {
        setState(() => _patternError = 'invalidRegex');
        return;
      }
    } else {
      // In the other modes the pattern is a literal name fragment, so it must
      // not contain characters that are invalid in a file name.
      final patternError = validateRenameName(pattern);
      if (patternError != null) {
        setState(() => _patternError = patternError);
        return;
      }
      final replacementError = validateRenameName(replacement);
      if (replacementError != null) {
        setState(() => _replacementError = replacementError);
        return;
      }
    }

    final pairs = buildRenamePairs(
      widget.objects,
      mode: _mode,
      pattern: pattern,
      replacement: replacement,
      padding: int.tryParse(_padding.text.trim()) ?? 0,
    );
    setState(() {
      _patternError = null;
      _replacementError = null;
      _preview = pairs;
    });
  }

  Future<void> _apply() async {
    final pairs = _preview;
    if (pairs == null || pairs.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await OpenListSession.instance.fs.batchRename(widget.dir, pairs);
      if (mounted) Navigator.of(context).pop(true);
      showMessage(S.current.operationDone);
      return;
    } catch (e) {
      showError(e);
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final preview = _preview;
    return AlertDialog(
      title: Text(strings.batchRename),
      content: preview == null ? _buildForm(strings) : _buildPreview(strings, preview),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        if (preview == null)
          FilledButton(
            onPressed: _previewRename,
            child: Text(strings.preview),
          )
        else ...[
          TextButton(
            onPressed: () => setState(() => _preview = null),
            child: Text(strings.back),
          ),
          FilledButton(
            onPressed: preview.isEmpty || _submitting ? null : _apply,
            child: Text(strings.confirm),
          ),
        ],
      ],
    );
  }

  Widget _buildForm(S strings) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.batchRenameDesc(widget.objects.length)),
          const SizedBox(height: 12),
          SegmentedButton<BatchRenameMode>(
            segments: [
              ButtonSegment(
                value: BatchRenameMode.regex,
                label: Text(strings.regexRename),
              ),
              ButtonSegment(
                value: BatchRenameMode.sequential,
                label: Text(strings.sequentialRename),
              ),
              ButtonSegment(
                value: BatchRenameMode.findReplace,
                label: Text(strings.findReplace),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _patternError = null;
              _replacementError = null;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pattern,
            autofocus: true,
            onChanged: (_) => setState(() => _patternError = null),
            decoration: InputDecoration(
              labelText: _mode == BatchRenameMode.regex
                  ? strings.renamePattern
                  : strings.renameSearchText,
              errorText: _patternError == null
                  ? null
                  : _errorText(strings, _patternError!),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _replacement,
            keyboardType: _mode == BatchRenameMode.sequential
                ? TextInputType.number
                : TextInputType.text,
            onChanged: (_) => setState(() => _replacementError = null),
            decoration: InputDecoration(
              labelText: _mode == BatchRenameMode.sequential
                  ? strings.renameStartNumber
                  : strings.renameReplacement,
              errorText: _replacementError == null
                  ? null
                  : _errorText(strings, _replacementError!),
            ),
          ),
          if (_mode == BatchRenameMode.sequential) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _padding,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: strings.renamePaddingZeros),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview(S strings, List<RenameObj> pairs) {
    return SizedBox(
      width: double.maxFinite,
      child: pairs.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(strings.renameNoMatch)),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: pairs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = pairs[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.srcName,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        p.newName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
