import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:ffi/ffi.dart';

import 'lib.dart';
import 'libserialport_bindings.g.dart' as sp;

part 'serial_port_config.dart';
part 'serial_port_reader.dart';
part 'serial_port_info.dart';

class SerialPort extends Equatable implements Finalizable {
  static final _finalizer = NativeFinalizer(sp.addresses.close.cast());

  final Pointer<sp.Port> _port;

  const SerialPort._(this._port);

  factory SerialPort(String portName) {
    final out = calloc<Pointer<sp.Port>>();
    final cStr = portName.toNativeUtf8().cast<Char>();
    try {
      assertReturn(sp.getPortByName(cStr, out));
      return SerialPort._(out.value);
    } finally {
      calloc.free(out);
      calloc.free(cStr);
    }
  }

  void dispose() => sp.freePort(_port);

  //#region Opening and closing

  /// Opens the serial port for reading and/or writing.
  ///
  /// [mode] can be one of the following:
  /// - [SerialPortMode.read]
  /// - [SerialPortMode.write]
  /// - [SerialPortMode.readWrite]
  ///
  /// If [mode] is not specified, defaults to [SerialPortMode.readWrite].
  void open([SerialPortMode mode = SerialPortMode.readWrite]) {
    assertReturn(sp.open(_port, mode));
    _finalizer.attach(this, _port.cast(), detach: this);
  }

  /// Closes an open serial port.
  void close() {
    _finalizer.detach(this);
    assertReturn(sp.close(_port));
  }

  /// Returns true if the serial port is open.
  bool isOpen() => using((arena) {
    final ptr = arena<Int>();
    assertReturn(sp.getPortHandle(_port, ptr.cast()));
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
        ? sp.nonblockingRead(_port, ptr.cast(), bytes)
        : sp.blockingRead(_port, ptr.cast(), bytes, timeout);
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
        ? sp.nonblockingWrite(_port, ptr.cast(), len)
        : sp.blockingWrite(_port, ptr.cast(), len, timeout);
    return assertReturn(ret);
  });

  //#endregion

  //#region Configuration

  SerialPortConfig getConfig() => using((arena) {
    final ptr = arena<Pointer<sp.PortConfig>>();
    assertReturn(sp.newConfig(ptr));
    assertReturn(sp.getConfig(_port, ptr.value));

    final valPtr = arena<Int>();
    get(int Function(Pointer<sp.PortConfig>, Pointer<Int>) func) {
      assertReturn(func(ptr.value, valPtr));
      return valPtr.value;
    }

    final baudRate = get(sp.getConfigBaudrate);
    final bits = get(sp.getConfigBits);
    final parity = SerialPortParity.fromValue(get(sp.getConfigParity));
    final stopBits = get(sp.getConfigStopbits);
    final rts = SerialPortRts.fromValue(get(sp.getConfigRts));
    final cts = SerialPortCts.fromValue(get(sp.getConfigCts));
    final dtr = SerialPortDtr.fromValue(get(sp.getConfigDtr));
    final dsr = SerialPortDsr.fromValue(get(sp.getConfigDsr));
    final flow = SerialPortXonXoff.fromValue(get(sp.getConfigXonXoff));

    sp.freeConfig(ptr.value);

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
    set<T>(int Function(Pointer<sp.Port>, T value) func, T? value) {
      if (value == null) return;
      assertReturn(func(_port, value));
    }

    set(sp.setBaudrate, value.baudRate);
    set(sp.setBits, value.bits);
    set(sp.setParity, value.parity);
    set(sp.setStopbits, value.stopBits);
    set(sp.setRts, value.rts);
    set(sp.setCts, value.cts);
    set(sp.setDtr, value.dtr);
    set(sp.setDsr, value.dsr);
    set(sp.setXonXoff, value.xonXoff);
  }

  //#endregion

  //#region Port info

  SerialPortInfo getInfo() {
    getS(Pointer<Char> Function(Pointer<sp.Port>) func) {
      final ptr = func(_port);
      if (ptr == nullptr) return '';
      return ptr.cast<Utf8>().toDartString();
    }

    getI(int Function(Pointer<sp.Port>, Pointer<Int>, Pointer<Int>) func) =>
        using((arena) {
          final ptr1 = arena<Int>();
          final ptr2 = arena<Int>();
          final ret = func(_port, ptr1, ptr2);
          if (ret == sp.Return.ERR_SUPP) return (null, null);
          assertReturn(ret);
          return (ptr1.value, ptr2.value);
        });

    getOptionalS(Pointer<Char> Function(Pointer<sp.Port>) func) {
      final value = getS(func);
      return value.isEmpty ? null : value;
    }

    final name = getS(sp.getPortName);
    final description = getS(sp.getPortDescription);
    final transport = SerialPortTransport.fromValue(
      assertReturn(sp.getPortTransport(_port).value),
    );

    String? manufacturer, product, serial;
    int? bus, address, vid, pid;
    if (transport == SerialPortTransport.usb) {
      (bus, address) = getI(sp.getPortUsbBusAddress);
      (vid, pid) = getI(sp.getPortUsbVidPid);
      manufacturer = getOptionalS(sp.getPortUsbManufacturer);
      product = getOptionalS(sp.getPortUsbProduct);
      serial = getOptionalS(sp.getPortUsbSerial);
    }

    String? btAddress;
    if (transport == SerialPortTransport.bluetooth) {
      btAddress = getS(sp.getPortBluetoothAddress);
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
    final out = calloc<Pointer<Pointer<sp.Port>>>();

    try {
      assertReturn(sp.listPorts(out));

      final ports = <String>[];
      int count = 0;
      while (out.value[count] != nullptr) {
        final portPtr = sp.getPortName(out.value[count]);
        if (portPtr != nullptr) {
          final portName = portPtr.cast<Utf8>().toDartString();
          ports.add(portName);
        }
        count++;
      }

      return ports;
    } finally {
      sp.freePortList(out.value);
      calloc.free(out);
    }
  }

  //#endregion

  @override
  List<Object?> get props => [_port];
}

typedef SerialPortMode = sp.Mode;
