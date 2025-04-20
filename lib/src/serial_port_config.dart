import 'package:equatable/equatable.dart';
import 'package:flutter_serial/flutter_serial_bindings_generated.dart';

class SerialPortConfig extends Equatable {
  final int? baudRate;
  final int? bits;
  final SerialPortParity? parity;
  final int? stopBits;
  final SerialPortRts? rts;
  final SerialPortCts? cts;
  final SerialPortDtr? dtr;
  final SerialPortDsr? dsr;
  final SerialPortXonXoff? xonXoff;

  const SerialPortConfig({
    this.baudRate,
    this.bits,
    this.parity,
    this.stopBits,
    this.rts,
    this.cts,
    this.dtr,
    this.dsr,
    this.xonXoff,
  });

  @override
  List<Object?> get props =>
      [baudRate, bits, parity, stopBits, rts, cts, dtr, dsr, xonXoff];
}

enum SerialPortParity {
  /// Special value to indicate setting should be left alone.
  invalid(-1),

  /// No parity.
  none(0),

  /// Odd parity.
  odd(1),

  /// Even parity.
  even(2),

  /// Mark parity.
  mark(3),

  /// Space parity.
  space(4);

  final int value;
  const SerialPortParity(this.value);

  static SerialPortParity fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError("Unknown value for parity: $value"),
      );

  sp_parity get native => sp_parity.fromValue(value);
}

enum SerialPortRts {
  /// Special value to indicate setting should be left alone.
  invalid(-1),

  /// RTS off.
  off(0),

  /// RTS on.
  on(1),

  /// RTS used for flow control.
  flowControl(2);

  final int value;
  const SerialPortRts(this.value);

  static SerialPortRts fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError("Unknown value for rts: $value"),
      );

  sp_rts get native => sp_rts.fromValue(value);
}

enum SerialPortCts {
  /// Special value to indicate setting should be left alone.
  invalid(-1),

  /// CTS ignored.
  ignore(0),

  /// CTS used for flow control.
  flowControl(1);

  final int value;
  const SerialPortCts(this.value);

  static SerialPortCts fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError("Unknown value for cts: $value"),
      );

  sp_cts get native => sp_cts.fromValue(value);
}

enum SerialPortDtr {
  /// Special value to indicate setting should be left alone.
  invalid(-1),

  /// DTR off.
  off(0),

  /// DTR on.
  on(1),

  /// DTR used for flow control.
  flowControl(2);

  final int value;
  const SerialPortDtr(this.value);

  static SerialPortDtr fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError("Unknown value for dtr: $value"),
      );

  sp_dtr get native => sp_dtr.fromValue(value);
}

enum SerialPortDsr {
  /// Special value to indicate setting should be left alone.
  invalid(-1),

  /// DSR ignored.
  ignore(0),

  /// DSR used for flow control.
  flowControl(1);

  final int value;
  const SerialPortDsr(this.value);

  static SerialPortDsr fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError("Unknown value for dsr: $value"),
      );

  sp_dsr get native => sp_dsr.fromValue(value);
}

enum SerialPortXonXoff {
  /// Special value to indicate setting should be left alone.
  invalid(-1),

  /// XON/XOFF disabled.
  disabled(0),

  /// XON/XOFF enabled for input only.
  input(1),

  /// XON/XOFF enabled for output only.
  output(2),

  /// XON/XOFF enabled for input and output.
  inputOutput(3);

  final int value;
  const SerialPortXonXoff(this.value);

  static SerialPortXonXoff fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError("Unknown value for xonXoff: $value"),
      );

  sp_xonxoff get native => sp_xonxoff.fromValue(value);
}

enum SerialPortFlowControl {
  /// No flow control.
  none(0),

  /// Software flow control using XON/XOFF characters.
  xonXoff(1),

  /// Hardware flow control using RTS/CTS signals.
  rtsCts(2),

  /// Hardware flow control using DTR/DSR signals.
  dtrDsr(3);

  final int value;
  const SerialPortFlowControl(this.value);

  static SerialPortFlowControl fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () =>
            throw ArgumentError("Unknown value for flowControl: $value"),
      );

  sp_flowcontrol get native => sp_flowcontrol.fromValue(value);
}
