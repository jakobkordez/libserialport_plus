# libserialport_plus

A Flutter wrapper (FFI plugin) for the [libserialport](https://github.com/sigrok/libserialport) library.

This package provides a simple API for communicating over serial ports.

## Features

- Cross-platform support for Android, Linux, macOS and Windows.
- Reading and writing bytes to serial ports.
- Reading bytes from serial ports in a stream.
- Getting a list of available serial ports.
- Getting information about serial ports.
- Getting and setting serial port settings (baud rate, data bits, parity, stop bits, etc.).

## Platform support

| Platform | Supported |
| -------- | --------- |
| Windows  | ✅        |
| Linux    | ✅        |
| macOS    | ✅        |
| Android  | ✅        |
| iOS      | ❌        |
| Web      | ❌        |

On unsupported platforms the native library is simply not built, so an app that
targets, for example, both iOS and Windows will still compile for iOS. Serial
functionality must be guarded by a platform check (e.g. `Platform.isWindows`);
calling into the library on an unsupported platform fails at runtime.

## Usage

Add `libserialport_plus` as a dependency in your `pubspec.yaml` file.

```bash
flutter pub add libserialport_plus
```

Import the package in your Dart code:

```dart
import 'dart:typed_data';

import 'package:libserialport_plus/libserialport_plus.dart';

void communicate() {
  final ports = SerialPort.getAvailablePorts();
  if (ports.isEmpty) return;

  final port = SerialPort(ports.first);
  try {
    final info = port.getInfo();
    print('${info.name}: ${info.description} (${info.transport.name})');

    port.open();

    final isOpen = port.isOpen();
    if (isOpen) {
      final bytes = port.read(1024, timeout: 1000);
      print('Received ${bytes.length} bytes');

      final message = Uint8List.fromList([0x68, 0x69, 0x0a]);
      final written = port.write(message, timeout: 1000);
      print('Wrote $written bytes');
    }
  } on SerialPortException catch (error) {
    print('Serial port error ${error.code}: ${error.message}');
  } finally {
    if (port.isOpen()) {
      port.close();
    }
    port.dispose();
  }
}
```

`SerialPort` accepts the platform-specific name returned by
`SerialPort.getAvailablePorts()`, such as `COM3` on Windows or
`/dev/ttyUSB0` on Linux. Constructing a port does not open it. Always close
and dispose the port when finished.

### Reading and writing

`read` and `write` operate on bytes using `Uint8List`. Their `timeout` is in
milliseconds:

- `0` (default) blocks until data is available or the write completes.
- A negative value performs a non-blocking operation.
- A positive value blocks until data is available, the write completes, or the
  timeout expires.

`read` may return fewer bytes than requested, and `write` returns the number of
bytes accepted by the native library. Both methods require an open port.

### Configuration

Use `SerialPortConfig` to read or update serial settings. Every configuration
property is optional; a `null` property is left unchanged by `setConfig`.

```dart
final config = port.getConfig();
print('Current baud rate: ${config.baudRate}');

port.setConfig(const SerialPortConfig(
  baudRate: 115200,
  bits: 8,
  parity: SerialPortParity.none,
  stopBits: 1,
  xonXoff: SerialPortXonXoff.disabled,
));
```

### Background reader

`SerialPortReader` reads incoming data on a background isolate and exposes
non-empty byte chunks through a stream. The port must be open before creating
the reader. Native read errors are delivered as `SerialPortException` stream
errors.

```dart
Future<void> readInBackground() async {
  final port = SerialPort('COM3');
  port.open();

  final reader = SerialPortReader(port);

  final subscription = reader.stream.listen((bytes) {
    print('Received ${bytes.length} bytes');
  }, onError: (Object error) {
    if (error is SerialPortException) {
      print('Reader error: ${error.message}');
    }
  });

  // When finished, stop the reader before closing and disposing the port.
  await subscription.cancel();
  await reader.close();
  port.close();
  port.dispose();
}
```

See the [API documentation](https://pub.dev/documentation/libserialport_plus/latest/)
for the complete public API, including supported serial modes, parity, flow
control, and transport types.

## macOS

If creating an app for macOS, serial permissions are required. Enable this by adding the following two lines to `DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.device.serial</key>
<true/>
```

## Development

To get started you need to initialize the `libserialport` submodule with:

```bash
git submodule update --init --recursive
```

The native code is compiled at build time by the Dart/Flutter code-assets build
hook in `hook/build.dart`, which uses `package:native_toolchain_c` to build
`libserialport` for the target platform. Platforms without a serial backend
(such as iOS and web) are skipped by the hook, so no native asset is produced
for them and consuming apps still build.

## Binding to native code

To use the native code, bindings in Dart are needed.
To avoid writing these by hand, they are generated from the header file
(`src/libserialport/libserialport.h`) by `package:ffigen`.
Regenerate the bindings by running `dart run tool/ffigen.dart`.
