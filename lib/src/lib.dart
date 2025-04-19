import 'dart:ffi';
import 'dart:io';

import 'package:flutter_serial/flutter_serial_bindings_generated.dart';

const String _libName = 'flutter_serial';

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
final FlutterSerialBindings lib = FlutterSerialBindings(_dylib);

int assertReturn(sp_return value) {
  if (value.value >= 0) return value.value;
  throw SerialPortException(value.value, value.name);
}

class SerialPortException implements Exception {
  final int code;
  final String message;

  SerialPortException(this.code, this.message);

  @override
  String toString() => 'SerialPortException: $message (code: $code)';
}
