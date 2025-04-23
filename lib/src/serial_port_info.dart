part of 'serial_port.dart';

class SerialPortInfo extends Equatable {
  final String name;
  final String description;
  final SerialPortTransport transport;

  // USB
  final int? usbBus;
  final int? usbAddress;
  final int? usbVid;
  final int? usbPid;
  final String? usbManufacturer;
  final String? usbProduct;
  final String? usbSerialNumber;

  // Bluetooth
  final String? bluetoothAddress;

  const SerialPortInfo({
    required this.name,
    required this.description,
    required this.transport,
    required this.usbBus,
    required this.usbAddress,
    required this.usbVid,
    required this.usbPid,
    required this.usbManufacturer,
    required this.usbProduct,
    required this.usbSerialNumber,
    required this.bluetoothAddress,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        transport,
        usbBus,
        usbAddress,
        usbVid,
        usbPid,
        usbManufacturer,
        usbProduct,
        usbSerialNumber,
        bluetoothAddress,
      ];

  @override
  String toString() {
    final props = [
      name,
      'description: $description',
      'transport: $transport',
      if (usbBus != null) 'usbBus: $usbBus',
      if (usbAddress != null) 'usbAddress: $usbAddress',
      if (usbVid != null) 'usbVid: $usbVid',
      if (usbPid != null) 'usbPid: $usbPid',
      if (usbManufacturer != null) 'usbManufacturer: $usbManufacturer',
      if (usbProduct != null) 'usbProduct: $usbProduct',
      if (usbSerialNumber != null) 'usbSerialNumber: $usbSerialNumber',
      if (bluetoothAddress != null) 'bluetoothAddress: $bluetoothAddress',
    ];
    return 'SerialPortInfo(${props.join(', ')})';
  }
}

enum SerialPortTransport {
  native(sp_transport.NATIVE),
  usb(sp_transport.USB),
  bluetooth(sp_transport.BLUETOOTH);

  final sp_transport _native;
  int get value => _native.value;
  const SerialPortTransport(this._native);

  static SerialPortTransport fromValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () =>
            throw ArgumentError("Unknown value for transport: $value"),
      );
}
