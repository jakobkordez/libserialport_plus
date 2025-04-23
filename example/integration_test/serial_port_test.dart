import 'package:flutter/services.dart';
import 'package:flutter_serial/flutter_serial.dart';
import 'package:flutter_test/flutter_test.dart';

// Set these to the names of your null-modem serial ports.
const String firstPort = 'CNCA0';
const String secondPort = 'CNCB0';

void main() {
  test('Get port list', () {
    final ports = SerialPort.getAvailablePorts();

    expect(ports, isNotEmpty);
    expect(ports, everyElement(isNotEmpty));
  });

  test('Create port', () {
    final port = SerialPort(firstPort);

    port.dispose();
  });

  test('Get port info', () {
    final port = SerialPort(firstPort);
    final info = port.getInfo();

    expect(info.name, firstPort);
    expect(info.description, isNotEmpty);
    expect(info.transport, SerialPortTransport.native);
    expect(info.usbBus, isNull);
    expect(info.usbAddress, isNull);
    expect(info.usbVid, isNull);
    expect(info.usbPid, isNull);
    expect(info.usbManufacturer, isNull);
    expect(info.usbProduct, isNull);
    expect(info.usbSerialNumber, isNull);
    expect(info.bluetoothAddress, isNull);

    port.dispose();
  });

  test('Open and close port', () {
    final port = SerialPort(firstPort);

    expect(port.isOpen(), isFalse);

    port.open();

    expect(port.isOpen(), isTrue);

    port.close();

    expect(port.isOpen(), isFalse);

    port.dispose();
  });

  test('Read and write', () async {
    final port1 = SerialPort(firstPort);
    final port2 = SerialPort(secondPort);

    port1.open();
    port2.open();

    final msg = Uint8List.fromList(List.generate(256, (i) => i % 128));
    final written = port1.write(msg);
    final received = port2.read(msg.length);

    port1.close();
    port2.close();

    port1.dispose();
    port2.dispose();

    expect(written, msg.length);
    expect(received, msg);
  });

  test('Read and write 8 bits', () async {
    final port1 = SerialPort(firstPort);
    final port2 = SerialPort(secondPort);

    port1.open();
    port1.setConfig(const SerialPortConfig(bits: 8));
    port2.open();
    port2.setConfig(const SerialPortConfig(bits: 8));

    final msg = Uint8List.fromList(List.generate(512, (i) => i % 256));
    final written = port1.write(msg);
    final received = port2.read(msg.length);

    port1.close();
    port2.close();

    port1.dispose();
    port2.dispose();

    expect(written, msg.length);
    expect(received, msg);
  });

  test('Get config', () {
    final port = SerialPort(firstPort);
    port.open();
    final config = port.getConfig();

    port.close();
    port.dispose();

    expect(config.baudRate, isNonNegative);
    expect(config.bits, isNonNegative);
    expect(config.parity, isNotNull);
    expect(config.stopBits, isNonNegative);
    expect(config.rts, isNotNull);
    expect(config.cts, isNotNull);
    expect(config.dtr, isNotNull);
    expect(config.dsr, isNotNull);
    expect(config.xonXoff, isNotNull);
  });

  test('Set config', () {
    const config = SerialPortConfig(
      baudRate: 115200,
      bits: 8,
      parity: SerialPortParity.mark,
      stopBits: 2,
      rts: SerialPortRts.on,
      cts: SerialPortCts.flowControl,
      dtr: SerialPortDtr.flowControl,
      dsr: SerialPortDsr.flowControl,
      xonXoff: SerialPortXonXoff.inputOutput,
    );
    final port = SerialPort(firstPort);

    port.open();

    port.setConfig(config);
    final newConfig = port.getConfig();

    port.close();
    port.dispose();

    expect(newConfig, config);
  });
}
