import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/pages/native/batch_rename_dialog.dart';

FsObject _obj(String name, {DateTime? created, DateTime? modified}) => FsObject(
  name: name,
  size: 0,
  isDir: false,
  created: created,
  modified: modified,
);

void main() {
  group('validateRenameName', () {
    test('rejects empty names', () {
      expect(validateRenameName(''), 'emptyInput');
      expect(validateRenameName('   '), 'emptyInput');
    });

    test('rejects invalid characters', () {
      expect(validateRenameName('a/b'), 'invalidFilenameChars');
      expect(validateRenameName('a\\b'), 'invalidFilenameChars');
      expect(validateRenameName('a?b'), 'invalidFilenameChars');
      expect(validateRenameName('a*b'), 'invalidFilenameChars');
      expect(validateRenameName('a:b'), 'invalidFilenameChars');
      expect(validateRenameName('a|b'), 'invalidFilenameChars');
      expect(validateRenameName('a"b'), 'invalidFilenameChars');
      expect(validateRenameName('a<b'), 'invalidFilenameChars');
      expect(validateRenameName('a>b'), 'invalidFilenameChars');
    });

    test('accepts valid names', () {
      expect(validateRenameName('report 2024.pdf'), isNull);
      expect(validateRenameName('中文名.txt'), isNull);
    });
  });

  group('buildRenamePairs regex', () {
    test('replaces every match and skips non matching names', () {
      final pairs = buildRenamePairs(
        [_obj('a1.txt'), _obj('a2.txt'), _obj('b.txt')],
        mode: BatchRenameMode.regex,
        pattern: r'a\d',
        replacement: 'x',
      );
      expect(pairs.length, 2);
      expect(pairs[0].srcName, 'a1.txt');
      expect(pairs[0].newName, 'x.txt');
      expect(pairs[1].newName, 'x.txt');
    });

    test('replaces all occurrences inside one name', () {
      final pairs = buildRenamePairs(
        [_obj('a-a-a.txt')],
        mode: BatchRenameMode.regex,
        pattern: 'a',
        replacement: 'b',
      );
      expect(pairs.single.newName, 'b-b-b.txt');
    });

    test('expands date placeholders', () {
      final pairs = buildRenamePairs(
        [_obj('x.txt', created: DateTime(2024, 3, 5, 7, 8, 9))],
        mode: BatchRenameMode.regex,
        pattern: '^x',
        replacement: '{created_year}-{created_month}-{created_date}',
      );
      expect(pairs.single.newName, '2024-03-05.txt');
    });

    test('expands date placeholders in local time', () {
      // The backend reports UTC, the placeholders must show the local date.
      final created = DateTime.utc(2024, 3, 5, 23, 30);
      final local = created.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      final pairs = buildRenamePairs(
        [_obj('x.txt', created: created)],
        mode: BatchRenameMode.regex,
        pattern: '^x',
        replacement: '{created_year}/{created_month}/{created_date}',
      );
      final expected = '${local.year}/${two(local.month)}/${two(local.day)}';
      expect(pairs.single.newName, '$expected.txt');
    });
  });

  group('buildRenamePairs sequential', () {
    test('appends an incrementing number and keeps the extension', () {
      final pairs = buildRenamePairs(
        [_obj('a.txt'), _obj('b.png')],
        mode: BatchRenameMode.sequential,
        pattern: 'file',
        replacement: '1',
      );
      expect(pairs[0].newName, 'file1.txt');
      expect(pairs[1].newName, 'file2.png');
    });

    test('honours the start number', () {
      final pairs = buildRenamePairs(
        [_obj('a.txt'), _obj('b.txt')],
        mode: BatchRenameMode.sequential,
        pattern: 'f',
        replacement: '10',
      );
      expect(pairs[0].newName, 'f10.txt');
      expect(pairs[1].newName, 'f11.txt');
    });

    test('pads the number with zeros', () {
      final pairs = buildRenamePairs(
        [_obj('a.txt')],
        mode: BatchRenameMode.sequential,
        pattern: 'f',
        replacement: '1',
        padding: 3,
      );
      expect(pairs.single.newName, 'f001.txt');
    });

    test('uses the {number} placeholder of the pattern', () {
      final pairs = buildRenamePairs(
        [_obj('a.txt'), _obj('b.txt')],
        mode: BatchRenameMode.sequential,
        pattern: 'part-{number}',
        replacement: '1',
      );
      expect(pairs[0].newName, 'part-1.txt');
      expect(pairs[1].newName, 'part-2.txt');
    });

    test('keeps names without an extension intact', () {
      final pairs = buildRenamePairs(
        [_obj('README')],
        mode: BatchRenameMode.sequential,
        pattern: 'f',
        replacement: '1',
      );
      expect(pairs.single.newName, 'f1');
    });
  });

  group('buildRenamePairs findReplace', () {
    test('replaces the first occurrence only', () {
      final pairs = buildRenamePairs(
        [_obj('report-draft.md')],
        mode: BatchRenameMode.findReplace,
        pattern: 'draft',
        replacement: 'final',
      );
      expect(pairs.single.newName, 'report-final.md');
    });

    test('skips names that do not contain the text', () {
      final pairs = buildRenamePairs(
        [_obj('alpha.txt'), _obj('beta.txt')],
        mode: BatchRenameMode.findReplace,
        pattern: 'zzz',
        replacement: 'y',
      );
      expect(pairs, isEmpty);
    });
  });
}
