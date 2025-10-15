part of 'serial_port.dart';

class SerialPortReader {
  final _receivePort = ReceivePort();
  final _sendPort = Completer<SendPort?>();

  final _controller = StreamController<Uint8List>();
  Stream<Uint8List> get stream => _controller.stream;

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
    final port = Pointer<sp_port>.fromAddress(params.portAddress);
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
            lib.blocking_read(port, buffer.cast(), bufferSize, 100));
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
