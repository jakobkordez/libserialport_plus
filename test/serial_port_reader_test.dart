import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:libserialport_plus/libserialport_plus.dart';

// Set these to the names of your null-modem serial ports.
const String firstPort = 'CNCA0';
const String secondPort = 'CNCB0';

void main() {
  test('Basic test', () async {
    final data = Uint8List.fromList(List.generate(256, (i) => i % 128));

    final port1 = SerialPort(firstPort);
    final port2 = SerialPort(secondPort);

    port1.open();
    port2.open();

    final reader = SerialPortReader(port2);

    expect(reader.stream, emitsInOrder([data, emitsDone]));

    port1.write(data);

    await Future.delayed(const Duration(seconds: 1));

    await reader.close();

    port1.close();
    port2.close();

    port1.dispose();
    port2.dispose();
  });

  test('Delivers data without waiting for the buffer to fill', () async {
    final data = Uint8List.fromList(List.generate(16, (i) => i));

    final port1 = SerialPort(firstPort);
    final port2 = SerialPort(secondPort);

    port1.open();
    port2.open();

    final reader = SerialPortReader(port2);

    Completer<void>? arrived;
    reader.stream.listen((_) {
      if (arrived?.isCompleted == false) arrived!.complete();
    });

    final latencies = <Duration>[];
    for (var i = 0; i < 20; i++) {
      // Vary where in the reader's read cycle the data lands.
      await Future.delayed(Duration(milliseconds: 20 + i * 7));

      arrived = Completer<void>();
      final watch = Stopwatch()..start();
      port1.write(data);
      await arrived.future.timeout(const Duration(seconds: 2));
      latencies.add(watch.elapsed);
    }

    await reader.close();

    port1.close();
    port2.close();

    port1.dispose();
    port2.dispose();

    final worst = latencies.reduce((a, b) => a > b ? a : b);

    // Far below the reader's 100 ms read timeout.
    expect(worst, lessThan(const Duration(milliseconds: 60)));
  });

  test('Close and dispose the port while the reader is reading', () async {
    // An unawaited reader.close() followed by closing and disposing the port
    // used to close and free the port while the reader's isolate was inside
    // a native read. On Windows the pending read then corrupted the heap.
    final writer = SerialPort(firstPort);
    writer.open();

    for (var i = 0; i < 50; i++) {
      final port = SerialPort(secondPort);
      port.open();

      final reader = SerialPortReader(port);
      // Fails on a stream error: the reader must stop cleanly.
      final done = reader.stream.drain<void>();

      // Vary where in the reader's read cycle the port is closed.
      await Future.delayed(Duration(milliseconds: i % 10 * 5));
      writer.write(Uint8List.fromList([i]));

      reader.close();
      port.close();
      port.dispose();

      // The port is closed and freed by the time the stream is done.
      await done.timeout(const Duration(seconds: 2));
    }

    writer.close();
    writer.dispose();
  });

  test('Close waits for the reader to stop', () async {
    final port = SerialPort(secondPort);
    port.open();

    final reader = SerialPortReader(port);
    final done = reader.stream.drain<void>();

    port.close();

    expect(port.isOpen(), isFalse);
    expect(() => port.open(), throwsStateError);
    expect(() => SerialPortReader(port), throwsStateError);

    await done.timeout(const Duration(seconds: 2));

    // The deferred close has run, so the port can be opened again.
    port.open();
    expect(port.isOpen(), isTrue);

    port.close();
    port.dispose();
  });

  test('Wait after close', () async {
    final port = SerialPort(firstPort);

    port.open();
    final reader = SerialPortReader(port);

    final future = expectLater(reader.stream, emitsInOrder([emitsDone]));

    await Future.delayed(const Duration(seconds: 1));

    reader.close();

    await future.timeout(const Duration(seconds: 2));

    port.close();
    port.dispose();
  });

  test('Close test', () async {
    final port = SerialPort(firstPort);

    port.open();
    final reader = SerialPortReader(port);

    expect(reader.stream, emitsInOrder([emitsDone]));

    port.close();
    port.dispose();

    await Future.delayed(const Duration(seconds: 1));

    reader.close();
  });

  test('Open write only', () async {
    final port = SerialPort(firstPort);

    port.open(SerialPortMode.write);
    final reader = SerialPortReader(port);

    expect(reader.stream, emitsInOrder([emitsDone]));

    port.close();
    port.dispose();

    await Future.delayed(const Duration(seconds: 1));

    reader.close();
  });
}
