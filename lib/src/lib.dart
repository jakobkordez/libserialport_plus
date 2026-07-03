import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'libserialport_bindings.g.dart' as sp;

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
      ptr != nullptr ? ptr.cast<Utf8>().toDartString() : '',
    );
  } finally {
    sp.freeErrorMessage(ptr);
  }
}

class SerialPortException implements Exception {
  final int code;
  final String message;

  SerialPortException(this.code, this.message);

  @override
  String toString() => 'SerialPortException: $message (code: $code)';
}
