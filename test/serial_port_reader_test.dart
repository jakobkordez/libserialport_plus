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

    reader.close();

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
