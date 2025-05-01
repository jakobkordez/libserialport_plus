# libserialport_plus

Flutter libserialport FFI plugin

## Usage

Add `libserialport_plus` as a dependency in your `pubspec.yaml` file.

```bash
flutter pub add libserialport_plus
```

Import the package in your Dart code:

```dart
import 'package:libserialport_plus/libserialport_plus.dart';
```

```dart
// Get a list of available serial ports
List<String> ports = SerialPort.getAvailablePorts();

// Create a serial port instance (MUST BE DISPOSED AFTER USE)
SerialPort port = SerialPort("COM3");

// Get information about the serial port
SerialPortInfo info = port.getInfo();

// Open the serial port
port.open(SerialPortMode.readWrite);

// Check if the serial port is open
bool isOpen = port.isOpen();

// Read bytes from the serial port
Uint8List bytes = port.read(1024);

// Write some bytes to the serial port
port.write(bytes);

// Close the serial port
port.close();

// Dispose the serial port
port.dispose();
```

### Reader

```dart
// Create and open a serial port
SerialPort port = SerialPort("COM3");
port.open();

SerialPortReader reader = SerialPortReader(port);

reader.stream.listen((Uint8List bytes) {
  // Do something with the bytes
});

// After you are done, close the reader
reader.close();
```

## Development

To get started you need to initialize the `libserialport` submodule with:

```bash
git submodule update --init --recursive
```

The native build systems that are invoked by FFI (and method channel) plugins are:

- For Android: Gradle, which invokes the Android NDK for native builds.
  - See the documentation in android/build.gradle.
- For iOS and MacOS: Xcode, via CocoaPods.
  - See the documentation in ios/libserialport_plus.podspec.
  - See the documentation in macos/libserialport_plus.podspec.
- For Linux and Windows: CMake.
  - See the documentation in linux/CMakeLists.txt.
  - See the documentation in windows/CMakeLists.txt.

## Binding to native code

To use the native code, bindings in Dart are needed.
To avoid writing these by hand, they are generated from the header file
(`src/libserialport/libserialport.h`) by `package:ffigen`.
Regenerate the bindings by running `dart run ffigen --config ffigen.yaml`.
