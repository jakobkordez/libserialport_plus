import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'libserialport_bindings.g.dart';

const String _libName = 'libserialport_plus';

/// The dynamic library in which the symbols for [FlutterSerialBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final LibSerialPortBindings lib = LibSerialPortBindings(_dylib);

int assertReturn(int value) {
  if (value >= 0) return value;
  if (value == sp_return.FAIL) {
    final ex = getLastError();
    if (ex != null) throw ex;
  }
  String message = switch (value) {
    sp_return.ARG => 'Argument error',
    sp_return.FAIL => 'Fail',
    sp_return.MEM => 'Memory error',
    sp_return.SUPP => 'Unsupported',
    _ => 'Unknown error',
  };
  throw SerialPortException(value, message);
}

SerialPortException? getLastError() {
  final code = lib.last_error_code();
  if (code == 0) return null;
  final ptr = lib.last_error_message();
  try {
    return SerialPortException(
      code,
      ptr != nullptr ? ptr.cast<Utf8>().toDartString() : '',
    );
  } finally {
    lib.free_error_message(ptr);
  }
}

class SerialPortException implements Exception {
  final int code;
  final String message;

  SerialPortException(this.code, this.message);

  @override
  String toString() => 'SerialPortException: $message (code: $code)';
}
