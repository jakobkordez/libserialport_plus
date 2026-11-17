import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:ffi/ffi.dart';

import 'lib.dart';
import 'libserialport_bindings.g.dart' as sp;

import 'libserialport_bindings.g.dart'
    show
        SerialPortMode,
        SerialPortParity,
        SerialPortRts,
        SerialPortCts,
        SerialPortDtr,
        SerialPortDsr,
        SerialPortXonXoff,
        SerialPortTransport;

part 'serial_port_config.dart';
part 'serial_port_reader.dart';
part 'serial_port_info.dart';

/// Represents a serial port and provides operations for opening, reading from,
/// writing to, and configuring it.
///
/// Create an instance with an operating-system-specific port name, such as
/// `COM3` on Windows or `/dev/ttyUSB0` on Linux. The port is not opened by the
/// constructor; call [open] before performing I/O. Call [dispose] when the
/// instance is no longer needed.
class SerialPort extends Equatable implements Finalizable {
  static final _finalizer = NativeFinalizer(sp.addresses.close.cast());

  final Pointer<sp.Port> _port;

  final _lifecycle = _PortLifecycle();

  SerialPort._(this._port);

  /// The native port, for any use that follows [dispose] to fail cleanly
  /// rather than touch freed memory.
  Pointer<sp.Port> get _handle {
    if (_lifecycle.disposed) {
      throw StateError('SerialPort used after dispose()');
    }
    return _port;
  }

  /// Creates a serial port handle for [portName].
  ///
  /// The port remains closed until [open] is called. Throws a
  /// [SerialPortException] if the named port cannot be found or allocated.
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

  /// Releases the native resources associated with this serial port, closing
  /// it first if it is still open.
  ///
  /// If a [SerialPortReader] is still reading from the port, it is stopped
  /// and the resources are released once it has finished its current read,
  /// so the reader never uses a freed port.
  ///
  /// Do not use this instance after calling [dispose]; doing so throws a
  /// [StateError]. Calling [dispose] again has no effect.
  void dispose() {
    if (_lifecycle.disposed) return;
    _lifecycle.disposed = true;

    if (_lifecycle.readers.isEmpty) {
      _release();
    } else {
      _stopReaders();
    }
  }

  /// Closes the port if it is open and frees it.
  void _release() {
    _finalizer.detach(this);
    // Fails harmlessly if the port is not open, and nobody is left to report
    // a failure to.
    sp.close(_port);
    sp.freePort(_port);
  }

  //#region Opening and closing

  /// Opens the serial port for reading and/or writing.
  ///
  /// [mode] can be one of the following:
  /// - [SerialPortMode.read]
  /// - [SerialPortMode.write]
  /// - [SerialPortMode.readWrite]
  ///
  /// If [mode] is not specified, defaults to [SerialPortMode.readWrite].
  ///
  /// Throws a [StateError] if the port is still closing; see [close].
  void open([SerialPortMode mode = SerialPortMode.readWrite]) {
    if (_lifecycle.closePending) {
      throw StateError(
        'SerialPort is still closing while its SerialPortReader finishes '
        'reading. Await SerialPortReader.close() before closing the port to '
        'reopen it at once.',
      );
    }
    assertReturn(sp.open(_handle, mode));
    _finalizer.attach(this, _port.cast(), detach: this);
  }

  /// Closes an open serial port.
  ///
  /// Closing a port stops I/O and releases its operating-system handle. The
  /// port can be opened again later with [open].
  ///
  /// If a [SerialPortReader] is still reading from the port, it is stopped
  /// and the port is closed once it has finished its current read, which
  /// takes at most about 100 ms. Until then [isOpen] reports `false` and
  /// [open] throws a [StateError]. To close the port at once, await
  /// [SerialPortReader.close] first.
  void close() {
    final port = _handle;

    if (_lifecycle.readers.isNotEmpty) {
      _lifecycle.closePending = true;
      _stopReaders();
      return;
    }

    _finalizer.detach(this);
    assertReturn(sp.close(port));
  }

  /// Whether the serial port currently has an open operating-system handle.
  ///
  /// Reports `false` once [close] has been called, even while the close is
  /// waiting for a [SerialPortReader] to finish.
  bool isOpen() => using((arena) {
    if (_lifecycle.closePending) return false;
    final ptr = arena<Int>();
    assertReturn(sp.getPortHandle(_handle, ptr.cast()));
    return ptr.value > 0;
  });

  void _stopReaders() {
    for (final reader in _lifecycle.readers) {
      reader._stop();
    }
  }

  /// Called once the isolate of [reader] has exited, so it can no longer be
  /// inside a native call on this port. Completes a pending [close] or
  /// [dispose] when the last reader is gone.
  void _readerExited(SerialPortReader reader) {
    _lifecycle.readers.remove(reader);
    if (_lifecycle.readers.isNotEmpty) return;

    final closePending = _lifecycle.closePending;
    _lifecycle.closePending = false;

    if (_lifecycle.disposed) {
      _release();
    } else if (closePending) {
      _finalizer.detach(this);
      // The caller of close() has already returned; nobody is left to report
      // a failure to.
      sp.close(_port);
    }
  }

  //#endregion

  //#region Reading and writing

  /// Reads up to [bytes] bytes from the serial port.
  ///
  /// [timeout] in milliseconds:
  /// - if 0 (default), the function will block until some bytes are available
  /// - if < 0, the function will be non-blocking
  /// - if > 0, the function will block until some bytes are available or timeout
  ///
  /// Returns the bytes read.
  ///
  /// The returned list can contain fewer than [bytes] bytes when the timeout
  /// expires or the native backend returns fewer bytes.
  Uint8List read(int bytes, {int timeout = 0}) => using((arena) {
    final ptr = arena<Uint8>(bytes);
    final ret = timeout < 0
        ? sp.nonblockingRead(_handle, ptr.cast(), bytes)
        : sp.blockingRead(_handle, ptr.cast(), bytes, timeout);
    return Uint8List.fromList(ptr.asTypedList(assertReturn(ret)));
  });

  /// Writes [bytes] to the serial port.
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
        ? sp.nonblockingWrite(_handle, ptr.cast(), len)
        : sp.blockingWrite(_handle, ptr.cast(), len, timeout);
    return assertReturn(ret);
  });

  //#endregion

  //#region Configuration

  /// Reads the current configuration from the serial port.
  ///
  /// Unsupported settings are represented by `null` in the returned
  /// [SerialPortConfig].
  SerialPortConfig getConfig() => using((arena) {
    final ptr = arena<Pointer<sp.PortConfig>>();
    assertReturn(sp.newConfig(ptr));
    assertReturn(sp.getConfig(_handle, ptr.value));

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

  /// Applies the non-null settings in [value] to the serial port.
  ///
  /// A `null` property leaves the corresponding native setting unchanged.
  ///
  /// The settings are applied together. This matters for RTS/CTS hardware
  /// flow control on Linux, Android and macOS, which can only be switched on
  /// or off for both lines at once: set [SerialPortConfig.rts] and
  /// [SerialPortConfig.cts] in the same call.
  void setConfig(SerialPortConfig value) => using((arena) {
    final ptr = arena<Pointer<sp.PortConfig>>();
    assertReturn(sp.newConfig(ptr));
    final config = ptr.value;

    try {
      // A setting left out of the native configuration is left alone.
      set<T>(int Function(Pointer<sp.PortConfig>, T value) func, T? value) {
        if (value == null) return;
        assertReturn(func(config, value));
      }

      set(sp.setConfigBaudrate, value.baudRate);
      set(sp.setConfigBits, value.bits);
      set(sp.setConfigParity, value.parity);
      set(sp.setConfigStopbits, value.stopBits);
      set(sp.setConfigRts, value.rts);
      set(sp.setConfigCts, value.cts);
      set(sp.setConfigDtr, value.dtr);
      set(sp.setConfigDsr, value.dsr);
      set(sp.setConfigXonXoff, value.xonXoff);

      assertReturn(sp.setConfig(_handle, config));
    } finally {
      sp.freeConfig(config);
    }
  });

  //#endregion

  //#region Port info

  /// Returns descriptive and transport-specific information for this port.
  ///
  /// USB and Bluetooth fields are populated only for ports using the
  /// corresponding transport and are otherwise `null`.
  SerialPortInfo getInfo() {
    getS(Pointer<Char> Function(Pointer<sp.Port>) func) {
      final ptr = func(_handle);
      if (ptr == nullptr) return '';
      return ptr.cast<Utf8>().toDartString();
    }

    getI(int Function(Pointer<sp.Port>, Pointer<Int>, Pointer<Int>) func) =>
        using((arena) {
          final ptr1 = arena<Int>();
          final ptr2 = arena<Int>();
          final ret = func(_handle, ptr1, ptr2);
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
      assertReturn(sp.getPortTransport(_handle).value),
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

  /// Returns the operating-system-specific names of available serial ports.
  ///
  /// The returned names can be passed to [SerialPort] to create a handle.
  /// Throws a [SerialPortException] if the native port enumeration fails.
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

/// Tracks what may still be using a native port, so it is closed and freed
/// only once nothing can touch it.
///
/// A [SerialPortReader] reads on its own isolate, which can be inside a
/// native read at any moment. Closing or freeing the port under it, as an
/// unawaited [SerialPortReader.close] followed by [SerialPort.close] or
/// [SerialPort.dispose] would, makes that read use closed handles and freed
/// memory; on Windows the pending read then corrupts the heap.
class _PortLifecycle {
  /// Readers whose isolate has not exited yet.
  final readers = <SerialPortReader>{};

  /// [SerialPort.close] was called and waits for [readers] to exit.
  bool closePending = false;

  /// [SerialPort.dispose] was called. The port is freed once [readers] have
  /// exited.
  bool disposed = false;
}
