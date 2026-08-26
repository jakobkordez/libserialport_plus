part of 'serial_port.dart';

/// Configuration values applied to a serial port.
///
/// Each property is optional. When passed to [SerialPort.setConfig], a `null`
/// property leaves the existing native setting unchanged. Use
/// [SerialPort.getConfig] to read the values currently applied to a port.
class SerialPortConfig extends Equatable {
  /// The communication speed in bits per second, such as `9600` or `115200`.
  final int? baudRate;

  /// The number of data bits in each character, commonly 5, 6, 7, or 8.
  final int? bits;

  /// The parity mode used for transmitted and received characters.
  final SerialPortParity? parity;

  /// The number of stop bits used for each character.
  final int? stopBits;

  /// The behaviour of the RTS (Request To Send) control line.
  final SerialPortRts? rts;

  /// The behaviour of the CTS (Clear To Send) control line.
  final SerialPortCts? cts;

  /// The behaviour of the DTR (Data Terminal Ready) control line.
  final SerialPortDtr? dtr;

  /// The behaviour of the DSR (Data Set Ready) control line.
  final SerialPortDsr? dsr;

  /// The XON/XOFF software flow-control mode.
  final SerialPortXonXoff? xonXoff;

  /// Creates a serial port configuration with the supplied settings.
  ///
  /// Any omitted setting is left unchanged when this configuration is passed
  /// to [SerialPort.setConfig].
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
  List<Object?> get props => [
    baudRate,
    bits,
    parity,
    stopBits,
    rts,
    cts,
    dtr,
    dsr,
    xonXoff,
  ];

  @override
  String toString() {
    final props = [
      'baudRate: $baudRate',
      'bits: $bits',
      'parity: ${parity?.name}',
      'stopBits: $stopBits',
      'rts: ${rts?.name}',
      'cts: ${cts?.name}',
      'dtr: ${dtr?.name}',
      'dsr: ${dsr?.name}',
      'xonXoff: ${xonXoff?.name}',
    ];
    return 'SerialPortConfig(${props.join(', ')})';
  }
}
