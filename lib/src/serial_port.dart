import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_serial/flutter_serial_bindings_generated.dart';
import 'package:flutter_serial/src/lib.dart';
import 'package:flutter_serial/src/serial_port_config.dart';

class SerialPort {
  final Pointer<sp_port> _port;

  SerialPort._(this._port);

  factory SerialPort(String portName, {SerialPortConfig? config}) {
    final out = calloc<Pointer<sp_port>>();
    final cStr = portName.toNativeUtf8().cast<Char>();
    try {
      assertReturn(lib.sp_get_port_by_name(cStr, out));
      final port = SerialPort._(out.value);
      if (config != null) port.setConfig(config);
      return port;
    } finally {
      calloc.free(out);
      calloc.free(cStr);
    }
  }

  void dispose() => lib.sp_free_port(_port);

  //#region Opening and closing

  void open(SerialPortMode mode) =>
      assertReturn(lib.sp_open(_port, mode._value));

  void openRead() => open(SerialPortMode.read);

  void openWrite() => open(SerialPortMode.write);

  void openReadWrite() => open(SerialPortMode.readWrite);

  void close() => assertReturn(lib.sp_close(_port));

  bool isOpen() => using((arena) {
    final ptr = arena<Int>();
    assertReturn(lib.sp_get_port_handle(_port, ptr.cast()));
    return ptr.value > 0;
  });

  //#endregion

  //#region Reading and writing

  /// Read bytes from the specified serial port, blocking until complete.
  Uint8List read(int bytes, {int timeout = 0}) => using((arena) {
    final ptr = arena<Uint8>(bytes);
    final ret = lib.sp_blocking_read(_port, ptr.cast(), bytes, timeout);
    return Uint8List.fromList(ptr.asTypedList(assertReturn(ret)));
  });

  /// Write bytes to the specified serial port, blocking until complete.
  int write(Uint8List bytes, {int timeout = 0}) => using((arena) {
    final len = bytes.length;
    final ptr = arena<Uint8>(len);
    ptr.asTypedList(len).setAll(0, bytes);
    final ret = lib.sp_blocking_write(_port, ptr.cast(), bytes.length, timeout);
    return assertReturn(ret);
  });

  //#endregion

  //#region Configuration

  SerialPortConfig getConfig() => using((arena) {
    final ptr = arena<Pointer<sp_port_config>>();
    assertReturn(lib.sp_new_config(ptr));
    assertReturn(lib.sp_get_config(_port, ptr.value));

    final valPtr = arena<Int>();
    get(sp_return Function(Pointer<sp_port_config>, Pointer<Int>) func) {
      assertReturn(func(ptr.value, valPtr));
      return valPtr.value;
    }

    final baudRate = get(lib.sp_get_config_baudrate);
    final bits = get(lib.sp_get_config_bits);
    final parity = SerialPortParity.fromValue(get(lib.sp_get_config_parity));
    final stopBits = get(lib.sp_get_config_stopbits);
    final rts = SerialPortRts.fromValue(get(lib.sp_get_config_rts));
    final cts = SerialPortCts.fromValue(get(lib.sp_get_config_cts));
    final dtr = SerialPortDtr.fromValue(get(lib.sp_get_config_dtr));
    final dsr = SerialPortDsr.fromValue(get(lib.sp_get_config_dsr));
    final flow = SerialPortXonXoff.fromValue(get(lib.sp_get_config_xon_xoff));

    lib.sp_free_config(ptr.value);

    return SerialPortConfig(
      baudRate: baudRate,
      bits: bits,
      parity: parity,
      stopBits: stopBits,
      rts: rts,
      cts: cts,
      dtr: dtr,
      dsr: dsr,
      xonXoff: flow,
    );
  });

  void setConfig(SerialPortConfig value) {
    set<T>(sp_return Function(Pointer<sp_port>, T value) func, T? value) {
      if (value == null) return;
      assertReturn(func(_port, value));
    }

    set(lib.sp_set_baudrate, value.baudRate);
    set(lib.sp_set_bits, value.bits);
    set(lib.sp_set_parity, value.parity?.native);
    set(lib.sp_set_stopbits, value.stopBits);
    set(lib.sp_set_rts, value.rts?.native);
    set(lib.sp_set_cts, value.cts?.native);
    set(lib.sp_set_dtr, value.dtr?.native);
    set(lib.sp_set_dsr, value.dsr?.native);
    set(lib.sp_set_xon_xoff, value.xonXoff?.native);
  }

  //#endregion

  //#region Static methods

  static List<String> listPorts() {
    final out = calloc<Pointer<Pointer<sp_port>>>();

    try {
      assertReturn(lib.sp_list_ports(out));

      final ports = <String>[];
      int count = 0;
      while (out.value[count] != nullptr) {
        final portPtr = lib.sp_get_port_name(out.value[count]);
        final portName = portPtr.cast<Utf8>().toDartString();
        ports.add(portName);
        count++;
      }

      return ports;
    } finally {
      lib.sp_free_port_list(out.value);
      calloc.free(out);
    }
  }

  static SerialPortException getLastError() {
    final ptr = lib.sp_last_error_message();
    try {
      return SerialPortException(
        lib.sp_last_error_code(),
        ptr.cast<Utf8>().toDartString(),
      );
    } finally {
      lib.sp_free_error_message(ptr);
    }
  }

  //#endregion
}

enum SerialPortMode {
  read(sp_mode.SP_MODE_READ),
  write(sp_mode.SP_MODE_WRITE),
  readWrite(sp_mode.SP_MODE_READ_WRITE);

  final sp_mode _value;

  const SerialPortMode(this._value);
}
