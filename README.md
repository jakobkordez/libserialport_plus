# flutter_serial

Flutter libserialport FFI plugin

## Getting Started

To get started you need to initialize the `libserialport` submodule with:

```bash
git submodule update --init --recursive
```

The native build systems that are invoked by FFI (and method channel) plugins are:

- For Android: Gradle, which invokes the Android NDK for native builds.
  - See the documentation in android/build.gradle.
- For iOS and MacOS: Xcode, via CocoaPods.
  - See the documentation in ios/flutter_serial.podspec.
  - See the documentation in macos/flutter_serial.podspec.
- For Linux and Windows: CMake.
  - See the documentation in linux/CMakeLists.txt.
  - See the documentation in windows/CMakeLists.txt.

## Binding to native code

To use the native code, bindings in Dart are needed.
To avoid writing these by hand, they are generated from the header file
(`src/libserialport/flutter_serial.h`) by `package:ffigen`.
Regenerate the bindings by running `dart run ffigen --config ffigen.yaml`.
