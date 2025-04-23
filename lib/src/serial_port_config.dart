part of 'serial_port.dart';

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
  /// No parity.
  none(sp_parity.NONE),

  /// Odd parity.
  odd(sp_parity.ODD),

  /// Even parity.
  even(sp_parity.EVEN),

  /// Mark parity.
  mark(sp_parity.MARK),

  /// Space parity.
  space(sp_parity.SPACE);

  final sp_parity _native;
  int get value => _native.value;
  const SerialPortParity(this._native);

  static SerialPortParity? fromValue(int value) =>
      values.where((e) => e.value == value).firstOrNull;
}

enum SerialPortRts {
  /// RTS off.
  off(sp_rts.OFF),

  /// RTS on.
  on(sp_rts.ON),

  /// RTS used for flow control.
  flowControl(sp_rts.FLOW_CONTROL);

  final sp_rts _native;
  int get value => _native.value;
  const SerialPortRts(this._native);

  static SerialPortRts? fromValue(int value) =>
      values.where((e) => e.value == value).firstOrNull;
}

enum SerialPortCts {
  /// CTS ignored.
  ignore(sp_cts.IGNORE),

  /// CTS used for flow control.
  flowControl(sp_cts.FLOW_CONTROL);

  final sp_cts _native;
  int get value => _native.value;
  const SerialPortCts(this._native);

  static SerialPortCts? fromValue(int value) =>
      values.where((e) => e.value == value).firstOrNull;
}

enum SerialPortDtr {
  /// DTR off.
  off(sp_dtr.OFF),

  /// DTR on.
  on(sp_dtr.ON),

  /// DTR used for flow control.
  flowControl(sp_dtr.FLOW_CONTROL);

  final sp_dtr _native;
  int get value => _native.value;
  const SerialPortDtr(this._native);

  static SerialPortDtr? fromValue(int value) =>
      values.where((e) => e.value == value).firstOrNull;
}

enum SerialPortDsr {
  /// DSR ignored.
  ignore(sp_dsr.IGNORE),

  /// DSR used for flow control.
  flowControl(sp_dsr.FLOW_CONTROL);

  final sp_dsr _native;
  int get value => _native.value;
  const SerialPortDsr(this._native);

  static SerialPortDsr? fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError("Unknown value for dsr: $value"),
      );
}

enum SerialPortXonXoff {
  /// XON/XOFF disabled.
  disabled(sp_xonxoff.DISABLED),

  /// XON/XOFF enabled for input only.
  input(sp_xonxoff.IN),

  /// XON/XOFF enabled for output only.
  output(sp_xonxoff.OUT),

  /// XON/XOFF enabled for input and output.
  inputOutput(sp_xonxoff.INOUT);

  final sp_xonxoff _native;
  int get value => _native.value;
  const SerialPortXonXoff(this._native);

  static SerialPortXonXoff? fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError("Unknown value for xonXoff: $value"),
      );
}

enum SerialPortFlowControl {
  /// No flow control.
  none(sp_flowcontrol.NONE),

  /// Software flow control using XON/XOFF characters.
  xonXoff(sp_flowcontrol.XONXOFF),

  /// Hardware flow control using RTS/CTS signals.
  rtsCts(sp_flowcontrol.RTSCTS),

  /// Hardware flow control using DTR/DSR signals.
  dtrDsr(sp_flowcontrol.DTRDSR);

  final sp_flowcontrol _native;
  int get value => _native.value;
  const SerialPortFlowControl(this._native);

  static SerialPortFlowControl? fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () =>
            throw ArgumentError("Unknown value for flowControl: $value"),
      );
}
