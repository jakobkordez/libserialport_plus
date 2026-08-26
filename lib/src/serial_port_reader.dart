part of 'serial_port.dart';

/// Reads incoming data from a serial port on a background isolate.
///
/// The port must already be open. Subscribe to [stream] to receive each
/// non-empty chunk of bytes, and call [close] when the reader is no longer
/// needed.
class SerialPortReader {
  final _receivePort = ReceivePort();
  final _sendPort = Completer<SendPort?>();

  final _controller = StreamController<Uint8List>();

  /// A stream of non-empty byte chunks received from the serial port.
  ///
  /// Native read errors are reported as [SerialPortException] errors on this
  /// stream.
  Stream<Uint8List> get stream => _controller.stream;

  /// Starts reading from [port] with a native read buffer of [bufferSize]
  /// bytes.
  ///
  /// [port] must be open before creating the reader. The reader owns its
  /// background isolate and should be stopped with [close].
  SerialPortReader(SerialPort port, {int bufferSize = 1024}) {
    _receivePort.listen((message) {
      if (message is SendPort) _sendPort.complete(message);
      if (message is Uint8List) _controller.add(message);
      if (message is SerialPortException) _controller.addError(message);
    });

    final closePort = ReceivePort();
    closePort.listen((_) {
      closePort.close();
      _dispose();
    });

    Isolate.spawn(
      _startRemoteIsolate,
      _IsolateParams(_receivePort.sendPort, port._port.address, bufferSize),
      onExit: closePort.sendPort,
    );
  }

  /// Stops the background reader and completes when its stream is closed.
  Future<void> close() async {
    _sendPort.future.then((sendPort) => sendPort?.send(_StopSignal()));
    await _controller.done;
  }

  void _dispose() {
    _controller.close();
    _receivePort.close();
  }

  static Future<void> _startRemoteIsolate(_IsolateParams params) async {
    // Setup
    final bufferSize = params.bufferSize;
    final port = Pointer<sp.Port>.fromAddress(params.portAddress);
    final buffer = calloc<Uint8>(bufferSize);

    // Stop signal setup
    final receivePort = ReceivePort();
    bool running = true;
    final listener = receivePort.listen((message) {
      if (message is _StopSignal) running = false;
    });
    params.sendPort.send(receivePort.sendPort);

    // Main loop
    while (running) {
      try {
        final len = assertReturn(
          sp.blockingRead(port, buffer.cast(), bufferSize, 100),
        );
        if (len > 0) {
          final bytes = buffer.asTypedList(len);
          params.sendPort.send(bytes);
        }
      } catch (e) {
        final error = getLastError();
        if (error != null) params.sendPort.send(error);
        break;
      }
      await Future.delayed(const Duration(milliseconds: 5));
    }

    // Cleanup
    listener.cancel();
    receivePort.close();
    calloc.free(buffer);
  }
}

class _IsolateParams {
  final SendPort sendPort;
  final int portAddress;
  final int bufferSize;

  const _IsolateParams(this.sendPort, this.portAddress, this.bufferSize);
}

class _StopSignal {}
