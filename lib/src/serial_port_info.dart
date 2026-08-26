part of 'serial_port.dart';

/// Describes a serial port and its transport-specific information.
///
/// The common properties are available for every port. USB properties are
/// populated only when [transport] is [SerialPortTransport.usb], and
/// [bluetoothAddress] is populated only for
/// [SerialPortTransport.bluetooth].
class SerialPortInfo extends Equatable {
  /// The operating-system-specific name used to open the port.
  final String name;

  /// A human-readable description of the port.
  final String description;

  /// The transport used by the port.
  final SerialPortTransport transport;

  // USB
  /// The USB bus number, when available.
  final int? usbBus;

  /// The USB address on [usbBus], when available.
  final int? usbAddress;

  /// The USB vendor ID, when available.
  final int? usbVid;

  /// The USB product ID, when available.
  final int? usbPid;

  /// The USB manufacturer string, when available.
  final String? usbManufacturer;

  /// The USB product string, when available.
  final String? usbProduct;

  /// The USB serial number, when available.
  final String? usbSerialNumber;

  // Bluetooth
  /// The Bluetooth MAC address, when available.
  final String? bluetoothAddress;

  /// Creates a description of a serial port.
  ///
  /// Transport-specific values should be `null` when they are not applicable
  /// to [transport].
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
