import 'dart:convert';
import 'dart:ffi';

/// Reads a NUL-terminated native string produced by libserialport.
///
/// libserialport does **not** guarantee that its strings are UTF-8 encoded:
/// `wc_to_utf8()` in the Windows backend converts UTF-16 with `CP_ACP`, which
/// is the system ANSI code page. Windows names a USB CDC port
/// `Serielles USB-Gerät (COM7)` on a German system, and that friendly name
/// arrives as CP1252 bytes: `ä` is the single byte `0xE4`. Decoding it strictly
/// as UTF-8 throws `FormatException: Missing extension byte`, which aborts port
/// enumeration and makes the device impossible to detect.
///
/// This function never throws: bytes that form valid UTF-8 are decoded as
/// UTF-8, everything else is decoded as Latin-1. Latin-1 maps the bytes
/// `0x20`-`0x7F` and `0xA0`-`0xFF` identically to CP1252, which covers the
/// accented letters and umlauts found in device names. Only the rarely used
/// CP1252 characters in `0x80`-`0x9F` are not remapped.
String decodeNativeString(Pointer<Char> pointer) {
  if (pointer == nullptr) {
    return '';
  }

  final bytes = pointer.cast<Uint8>();
  final units = <int>[];
  for (var index = 0; bytes[index] != 0; index++) {
    units.add(bytes[index]);
  }

  return decodeNativeBytes(units);
}

/// Decodes the bytes of a libserialport string.
///
/// See [decodeNativeString] for why a tolerant decoder is required.
String decodeNativeBytes(List<int> bytes) {
  if (bytes.isEmpty) {
    return '';
  }

  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}
