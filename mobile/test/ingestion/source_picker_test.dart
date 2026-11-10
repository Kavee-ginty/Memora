import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/ingestion/data/source_picker.dart';

void main() {
  group('Temporary picker copy cleanup', () {
    late Directory sandbox;
    late Directory temporaryRoot;

    setUp(() async {
      sandbox = await Directory.systemTemp.createTemp('memora_picker_cleanup_');
      temporaryRoot = await Directory(
        '${sandbox.path}${Platform.pathSeparator}temp',
      ).create();
    });

    tearDown(() async {
      if (await sandbox.exists()) await sandbox.delete(recursive: true);
    });

    test('deletes a picker copy inside the temporary root', () async {
      final file = File(
        '${temporaryRoot.path}${Platform.pathSeparator}notes.pdf',
      );
      await file.writeAsBytes(<int>[1, 2, 3]);

      await deleteTemporaryCopy(file.path, temporaryRoot: temporaryRoot.path);

      expect(await file.exists(), isFalse);
    });

    test(
      'keeps a sibling whose name shares the temporary root prefix',
      () async {
        final sibling = File('${temporaryRoot.path}_notes.pdf');
        await sibling.writeAsBytes(<int>[1, 2, 3]);

        await deleteTemporaryCopy(
          sibling.path,
          temporaryRoot: temporaryRoot.path,
        );

        expect(await sibling.exists(), isTrue);
      },
    );

    test('keeps a file outside the temporary root', () async {
      final original = File(
        '${sandbox.path}${Platform.pathSeparator}original.pdf',
      );
      await original.writeAsBytes(<int>[1, 2, 3]);

      await deleteTemporaryCopy(
        original.path,
        temporaryRoot: temporaryRoot.path,
      );

      expect(await original.exists(), isTrue);
    });
  });
}
