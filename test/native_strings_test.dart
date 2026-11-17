import 'dart:convert';

import 'package:libserialport_plus/src/native_strings.dart';
import 'package:test/test.dart';

/// libserialport converts device strings on Windows with `CP_ACP` (the system
/// ANSI code page) while the package used to decode them as strict UTF-8. On a
/// non-English Windows every USB CDC device therefore failed enumeration with
/// `FormatException: Missing extension byte`.
void main() {
  group('decodeNativeBytes', () {
    test('decodes CP1252 device names that are not valid UTF-8', () {
      // Windows' German friendly name for a USB CDC port,
      // "Serielles USB-Gerät (COM7)": the umlaut is the single CP1252 byte
      // 0xE4 at index 17, so strict UTF-8 decoding rejects it with
      // "Missing extension byte (at offset 18)".
      final cp1252 = <int>[
        ...latin1.encode('Serielles USB-Ger'),
        0xE4,
        ...latin1.encode('t (COM7)'),
      ];

      expect(
        () => utf8.decode(cp1252),
        throwsA(isA<FormatException>()),
        reason: 'precondition: the bytes are not valid UTF-8',
      );
      expect(decodeNativeBytes(cp1252), 'Serielles USB-Gerät (COM7)');
    });

    test('decodes valid UTF-8 unchanged', () {
      final utf8Bytes = utf8.encode('Zebra Technologies – DS2208');

      expect(decodeNativeBytes(utf8Bytes), 'Zebra Technologies – DS2208');
    });

    test('passes ASCII through unchanged', () {
      expect(
        decodeNativeBytes(latin1.encode('USB Serial Device (COM3)')),
        'USB Serial Device (COM3)',
      );
    });

    test('returns an empty string for empty input', () {
      expect(decodeNativeBytes(const <int>[]), '');
    });
  });
}
