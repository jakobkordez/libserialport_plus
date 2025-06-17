import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:ffi/ffi.dart';

import 'lib.dart';
import 'libserialport_bindings.g.dart';

part 'serial_port_config.dart';
part 'serial_port_reader.dart';
part 'serial_port_info.dart';

class SerialPort extends Equatable {
  final Pointer<sp_port> _port;

  const SerialPort._(this._port);

  factory SerialPort(String portName, {SerialPortConfig? config}) {
    final out = calloc<Pointer<sp_port>>();
    final cStr = portName.toNativeUtf8().cast<Char>();
    try {
      assertReturn(lib.get_port_by_name(cStr, out));
      final port = SerialPort._(out.value);
      if (config != null) port.setConfig(config);
      return port;
    } finally {
      calloc.free(out);
      calloc.free(cStr);
    }
  }

  void dispose() => lib.free_port(_port);

  //#region Opening and closing

  /// Opens the serial port for reading and/or writing.
  ///
  /// [mode] can be one of the following:
  /// - [SerialPortMode.read]
  /// - [SerialPortMode.write]
  /// - [SerialPortMode.readWrite]
  ///
  /// If [mode] is not specified, defaults to [SerialPortMode.readWrite].
  void open([SerialPortMode mode = SerialPortMode.readWrite]) =>
      assertReturn(lib.open(_port, mode._value));

  /// Closes an open serial port.
  void close() => assertReturn(lib.close(_port));

  /// Returns true if the serial port is open.
  bool isOpen() => using((arena) {
        final ptr = arena<Int>();
        assertReturn(lib.get_port_handle(_port, ptr.cast()));
        return ptr.value > 0;
      });

  //#endregion

  //#region Reading and writing

  /// Read bytes from the specified serial port
  ///
  /// [timeout] in milliseconds:
  /// - if 0 (default), the function will block until some bytes are available
  /// - if < 0, the function will be non-blocking
  /// - if > 0, the function will block until some bytes are available or timeout
  ///
  /// Returns the bytes read.
  Uint8List read(int bytes, {int timeout = 0}) => using((arena) {
        final ptr = arena<Uint8>(bytes);
        final ret = timeout < 0
            ? lib.nonblocking_read(_port, ptr.cast(), bytes)
            : lib.blocking_read(_port, ptr.cast(), bytes, timeout);
        return Uint8List.fromList(ptr.asTypedList(assertReturn(ret)));
      });

  /// Write bytes to the specified serial port
  ///
  /// [timeout] in milliseconds:
  /// - if 0 (default), the function will block until complete
  /// - if < 0, the function will be non-blocking
  /// - if > 0, the function will block until complete or timeout
  ///
  /// Returns the number of bytes written.
  int write(Uint8List bytes, {int timeout = 0}) => using((arena) {
        final len = bytes.length;
        final ptr = arena<Uint8>(len);
        ptr.asTypedList(len).setAll(0, bytes);
        final ret = timeout < 0
            ? lib.nonblocking_write(_port, ptr.cast(), len)
            : lib.blocking_write(_port, ptr.cast(), len, timeout);
        return assertReturn(ret);
      });

  //#endregion

  //#region Configuration

  SerialPortConfig getConfig() => using((arena) {
        final ptr = arena<Pointer<sp_port_config>>();
        assertReturn(lib.new_config(ptr));
        assertReturn(lib.get_config(_port, ptr.value));

        final valPtr = arena<Int>();
        get(int Function(Pointer<sp_port_config>, Pointer<Int>) func) {
          assertReturn(func(ptr.value, valPtr));
          return valPtr.value;
        }

        final baudRate = get(lib.get_config_baudrate);
        final bits = get(lib.get_config_bits);
        final parity = SerialPortParity.fromValue(get(lib.get_config_parity));
        final stopBits = get(lib.get_config_stopbits);
        final rts = SerialPortRts.fromValue(get(lib.get_config_rts));
        final cts = SerialPortCts.fromValue(get(lib.get_config_cts));
        final dtr = SerialPortDtr.fromValue(get(lib.get_config_dtr));
        final dsr = SerialPortDsr.fromValue(get(lib.get_config_dsr));
        final flow = SerialPortXonXoff.fromValue(get(lib.get_config_xon_xoff));

        lib.free_config(ptr.value);

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
    set<T>(int Function(Pointer<sp_port>, T value) func, T? value) {
      if (value == null) return;
      assertReturn(func(_port, value));
    }

    set(lib.set_baudrate, value.baudRate);
    set(lib.set_bits, value.bits);
    set(lib.set_parity, value.parity?._native);
    set(lib.set_stopbits, value.stopBits);
    set(lib.set_rts, value.rts?._native);
    set(lib.set_cts, value.cts?._native);
    set(lib.set_dtr, value.dtr?._native);
    set(lib.set_dsr, value.dsr?._native);
    set(lib.set_xon_xoff, value.xonXoff?._native);
  }

  //#endregion

  //#region Port info

  SerialPortInfo getInfo() {
    getS(Pointer<Char> Function(Pointer<sp_port>) func) {
      final ptr = func(_port);
      if (ptr == nullptr) return '';
      return ptr.cast<Utf8>().toDartString();
    }

    getI(int Function(Pointer<sp_port>, Pointer<Int>, Pointer<Int>) func) =>
        using((arena) {
          final ptr1 = calloc<Int>();
          final ptr2 = calloc<Int>();
          final ret = func(_port, ptr1, ptr2);
          if (ret == sp_return.SUPP) return (null, null);
          assertReturn(ret);
          return (ptr1.value, ptr2.value);
        });

    final name = getS(lib.get_port_name);
    final description = getS(lib.get_port_description);
    final transport = SerialPortTransport.fromValue(
        assertReturn(lib.get_port_transport(_port).value));

    String? manufacturer, product, serial;
    int? bus, address, vid, pid;
    if (transport == SerialPortTransport.usb) {
      (bus, address) = getI(lib.get_port_usb_bus_address);
      (vid, pid) = getI(lib.get_port_usb_vid_pid);
      getS(lib.get_port_usb_manufacturer);
      getS(lib.get_port_usb_product);
      getS(lib.get_port_usb_serial);
    }

    String? btAddress;
    if (transport == SerialPortTransport.bluetooth) {
      btAddress = getS(lib.get_port_bluetooth_address);
    }

    return SerialPortInfo(
      name: name,
      description: description,
      transport: transport,
      usbBus: bus,
      usbAddress: address,
      usbVid: vid,
      usbPid: pid,
      usbManufacturer: manufacturer,
      usbProduct: product,
      usbSerialNumber: serial,
      bluetoothAddress: btAddress,
    );
  }

  //#endregion

  //#region Static methods

  static List<String> getAvailablePorts() {
    final out = calloc<Pointer<Pointer<sp_port>>>();

    try {
      assertReturn(lib.list_ports(out));

      final ports = <String>[];
      int count = 0;
      while (out.value[count] != nullptr) {
        final portPtr = lib.get_port_name(out.value[count]);
        if (portPtr != nullptr) {
          final portName = portPtr.cast<Utf8>().toDartString();
          ports.add(portName);
        }
        count++;
      }

      return ports;
    } finally {
      lib.free_port_list(out.value);
      calloc.free(out);
    }
  }

  //#endregion

  @override
  List<Object?> get props => [_port];
}

enum SerialPortMode {
  read(sp_mode.READ),
  write(sp_mode.WRITE),
  readWrite(sp_mode.READ_WRITE);

  final sp_mode _value;

  const SerialPortMode(this._value);
}
