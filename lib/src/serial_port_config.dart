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

typedef SerialPortParity = sp.Parity;
typedef SerialPortRts = sp.Rts;
typedef SerialPortCts = sp.Cts;
typedef SerialPortDtr = sp.Dtr;
typedef SerialPortDsr = sp.Dsr;
typedef SerialPortXonXoff = sp.Xonxoff;
typedef SerialPortFlowControl = sp.Flowcontrol;
