import 'dart:ffi';

import 'libserialport_bindings.g.dart' as sp;
import 'native_strings.dart';

int assertReturn(int value) {
  if (value >= 0) return value;
  if (value == sp.Return.ERR_FAIL) {
    final ex = getLastError();
    if (ex != null) throw ex;
  }
  String message = switch (value) {
    sp.Return.ERR_ARG => 'Argument error',
    sp.Return.ERR_FAIL => 'Fail',
    sp.Return.ERR_MEM => 'Memory error',
    sp.Return.ERR_SUPP => 'Unsupported',
    _ => 'Unknown error',
  };
  throw SerialPortException(value, message);
}

SerialPortException? getLastError() {
  final code = sp.lastErrorCode();
  if (code == 0) return null;
  final ptr = sp.lastErrorMessage();
  try {
    return SerialPortException(
      code,
      ptr != nullptr ? decodeNativeString(ptr) : '',
    );
  } finally {
    sp.freeErrorMessage(ptr);
  }
}

/// An error reported by the native serial port library.
class SerialPortException implements Exception {
  /// The native error code.
  final int code;

  /// A human-readable description of the error.
  final String message;

  /// Creates an exception with a native [code] and [message].
  SerialPortException(this.code, this.message);

  @override
  String toString() => 'SerialPortException: $message (code: $code)';
}
